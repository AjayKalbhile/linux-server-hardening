#!/bin/bash
# =============================================================================
# Module 02: User Hardening — Secure Admin Account & Account Policies
# Creates admin user, locks root, sets password policies (CIS 5.4, 5.6, 6.1)
# =============================================================================
set -euo pipefail
GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'
log()  { echo -e "${GREEN}[+] $1${NC}"; }
warn() { echo -e "${YELLOW}[-] $1${NC}"; }
info() { echo -e "${BLUE}[*] $1${NC}"; }

[[ $EUID -ne 0 ]] && { echo "Run as root: sudo $0"; exit 1; }

ADMIN_USER="${ADMIN_USER:-pentester}"
BACKUP_DIR="${BACKUP_DIR:-/var/backups/hardening}"
mkdir -p "$BACKUP_DIR"

# ── Create secure admin user ──────────────────────────────
ADMIN_PASS=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-24)

if ! id "$ADMIN_USER" &>/dev/null; then
    useradd -m -s /bin/bash "$ADMIN_USER"
    echo "$ADMIN_USER:$ADMIN_PASS" | chpasswd
    usermod -aG sudo "$ADMIN_USER"
    mkdir -p "/home/$ADMIN_USER/.ssh"
    chmod 700 "/home/$ADMIN_USER/.ssh"

    # Generate ed25519 SSH key pair
    ssh-keygen -t ed25519 -f "/home/$ADMIN_USER/.ssh/id_ed25519" -N "" \
        -C "$ADMIN_USER@hardened-server" &>/dev/null
    cat "/home/$ADMIN_USER/.ssh/id_ed25519.pub" \
        >> "/home/$ADMIN_USER/.ssh/authorized_keys"
    chmod 600 "/home/$ADMIN_USER/.ssh/authorized_keys"
    chown -R "$ADMIN_USER:$ADMIN_USER" "/home/$ADMIN_USER/.ssh"

    log "Admin user '$ADMIN_USER' created"
    info "Temporary password: $ADMIN_PASS"
    info "SSH key: /home/$ADMIN_USER/.ssh/id_ed25519"
    info "CHANGE PASSWORD after SSH key setup!"
else
    warn "User '$ADMIN_USER' already exists — skipping creation"
fi

# ── Lock root account (CIS 5.4.3) ────────────────────────
passwd -l root &>/dev/null
log "Root account locked"

# ── Password policies (CIS 5.4.1) ────────────────────────
cp /etc/login.defs "$BACKUP_DIR/login.defs.bak" 2>/dev/null || true
sed -i 's/^PASS_MAX_DAYS.*/PASS_MAX_DAYS   90/'  /etc/login.defs
sed -i 's/^PASS_MIN_DAYS.*/PASS_MIN_DAYS   1/'   /etc/login.defs
sed -i 's/^PASS_WARN_AGE.*/PASS_WARN_AGE   14/'  /etc/login.defs
log "Password policy: max 90 days, warn at 14 days"

# ── File permissions (CIS 6.1.x) ─────────────────────────
chmod 644 /etc/passwd /etc/group
chmod 640 /etc/shadow /etc/gshadow
chown root:shadow /etc/shadow /etc/gshadow
log "Critical file permissions set (CIS 6.1)"

# ── Restrict su to wheel group (CIS 5.6.1) ───────────────
groupadd -f wheel
usermod -aG wheel "$ADMIN_USER"
if ! grep -q "^auth.*pam_wheel" /etc/pam.d/su; then
    sed -i '/^#.*pam_wheel/s/^#//' /etc/pam.d/su 2>/dev/null || true
fi
log "su access restricted to wheel group"

# ── Remove unneeded packages ──────────────────────────────
for pkg in rsh-client talk telnet; do
    if dpkg -l "$pkg" 2>/dev/null | grep -q "^ii"; then
        apt-get remove -yqq "$pkg"
        log "Removed insecure package: $pkg"
    fi
done

# ── Check for empty passwords (CIS 6.2.1) ────────────────
EMPTY=$(awk -F: '($2 == "") {print $1}' /etc/shadow 2>/dev/null | wc -l)
if [ "$EMPTY" -gt 0 ]; then
    warn "Empty passwords found — locking affected accounts"
    awk -F: '($2 == "") {print $1}' /etc/shadow | xargs -I{} passwd -l {}
fi

log "✅ Module 02 — User Hardening complete"
info "Admin:    $ADMIN_USER"
info "SSH key:  /home/$ADMIN_USER/.ssh/id_ed25519  (copy to your local machine)"
