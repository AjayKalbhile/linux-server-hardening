#!/bin/bash
# =============================================================================
# Module 10: Two-Factor Authentication (2FA/MFA) for SSH
# Google Authenticator TOTP — requires key + 6-digit code
# =============================================================================
set -euo pipefail

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; RED='\033[0;31m'; NC='\033[0m'
log()  { echo -e "${GREEN}[+] $1${NC}"; }
warn() { echo -e "${YELLOW}[-] $1${NC}"; }
info() { echo -e "${BLUE}[*] $1${NC}"; }
error(){ echo -e "${RED}[!] $1${NC}"; exit 1; }

[[ $EUID -ne 0 ]] && error "Run as root: sudo $0"

ADMIN_USER="${ADMIN_USER:-pentester}"

log "Installing Google Authenticator PAM..."
apt-get install -yqq libpam-google-authenticator

# Backup PAM config
cp /etc/pam.d/sshd /etc/pam.d/sshd.bak.2fa

# Add Google Authenticator to PAM SSH stack
# Insert AFTER @include common-auth so key+TOTP both required
if ! grep -q "pam_google_authenticator" /etc/pam.d/sshd; then
    sed -i '/@include common-auth/a auth required pam_google_authenticator.so nullok' \
        /etc/pam.d/sshd
fi
log "PAM configured for TOTP"

# Update sshd_config for 2FA
SSHD_CONFIG="/etc/ssh/sshd_config"
cp "$SSHD_CONFIG" "$SSHD_CONFIG.bak.2fa"

# Enable keyboard-interactive and PAM
sed -i 's/^ChallengeResponseAuthentication.*/ChallengeResponseAuthentication yes/' "$SSHD_CONFIG"
sed -i 's/^KbdInteractiveAuthentication.*/KbdInteractiveAuthentication yes/' "$SSHD_CONFIG"

# Require both publickey AND keyboard-interactive
if grep -q "^AuthenticationMethods" "$SSHD_CONFIG"; then
    sed -i 's/^AuthenticationMethods.*/AuthenticationMethods publickey,keyboard-interactive/' "$SSHD_CONFIG"
else
    echo "AuthenticationMethods publickey,keyboard-interactive" >> "$SSHD_CONFIG"
fi

systemctl reload ssh 2>/dev/null || systemctl reload sshd 2>/dev/null || true
log "SSH reloaded with 2FA support"

# Per-user 2FA setup instructions
cat > /home/"$ADMIN_USER"/SETUP_2FA.txt << INSTRUCTIONS
==============================================
  SSH 2FA SETUP — Google Authenticator
==============================================

Run this command as your user (NOT as root):

  google-authenticator

Follow the prompts:
  - Time-based tokens?           YES (y)
  - Update .google_authenticator? YES (y)
  - Disallow multiple uses?       YES (y)
  - Increase window?              NO  (n)
  - Rate limiting?                YES (y)

Then scan the QR code with:
  - Google Authenticator (iOS/Android)
  - Authy
  - Microsoft Authenticator
  - Any TOTP app

After setup, SSH requires BOTH:
  1. Your SSH private key
  2. The 6-digit code from your app

Test connection (keep current session open!):
  ssh -p 2222 -i ~/.ssh/id_ed25519 $ADMIN_USER@YOUR_SERVER_IP

==============================================
INSTRUCTIONS
chown "$ADMIN_USER":"$ADMIN_USER" /home/"$ADMIN_USER"/SETUP_2FA.txt

log "✅ Module 10 — 2FA/MFA complete"
warn "IMPORTANT: Each user must run 'google-authenticator' to set up their TOTP"
info "Instructions saved: /home/$ADMIN_USER/SETUP_2FA.txt"
info "Test with a separate session before closing current connection!"
