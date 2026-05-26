#!/bin/bash
# =============================================================================
# Module 03: SSH Hardening — Port 2222, Keys Only, Rate Limiting, Banner
# CIS 5.2.x compliant SSH configuration
# =============================================================================
set -euo pipefail
GREEN='\033[0;32m'; BLUE='\033[0;34m'; NC='\033[0m'
log()  { echo -e "${GREEN}[+] $1${NC}"; }
info() { echo -e "${BLUE}[*] $1${NC}"; }

[[ $EUID -ne 0 ]] && { echo "Run as root: sudo $0"; exit 1; }

ADMIN_USER="${ADMIN_USER:-pentester}"
SSH_PORT="${SSH_PORT:-2222}"
BACKUP_DIR="${BACKUP_DIR:-/var/backups/hardening}"
mkdir -p "$BACKUP_DIR"

SSHD_CONFIG="/etc/ssh/sshd_config"

# Backup original
cp "$SSHD_CONFIG" "$BACKUP_DIR/sshd_config.bak" 2>/dev/null || true
cp "$SSHD_CONFIG" "$SSHD_CONFIG.bak"

log "Writing hardened SSH config (port $SSH_PORT)..."
cat > "$SSHD_CONFIG" << SSHEOF
# =============================================================
# SSH Hardened Configuration — Linux Server Hardening v3.0
# CIS Ubuntu 22.04 Level 1 — Section 5.2
# Generated: $(date)
# =============================================================

# Network
Port $SSH_PORT
AddressFamily inet
ListenAddress 0.0.0.0

# Protocol & Ciphers (modern only)
Protocol 2
HostKey /etc/ssh/ssh_host_ed25519_key
HostKey /etc/ssh/ssh_host_rsa_key
KexAlgorithms curve25519-sha256,curve25519-sha256@libssh.org
Ciphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com,aes128-gcm@openssh.com
MACs hmac-sha2-256-etm@openssh.com,hmac-sha2-512-etm@openssh.com

# Authentication — keys only, no root, no passwords
PermitRootLogin no
PasswordAuthentication no
PubkeyAuthentication yes
AuthorizedKeysFile .ssh/authorized_keys
PermitEmptyPasswords no
ChallengeResponseAuthentication no
KerberosAuthentication no
GSSAPIAuthentication no
UsePAM yes

# Access control
AllowUsers $ADMIN_USER
MaxSessions 3
MaxAuthTries 3
LoginGraceTime 30

# Session hardening
ClientAliveInterval 300
ClientAliveCountMax 2
TCPKeepAlive yes
Compression no

# Disable unnecessary features
X11Forwarding no
AllowTcpForwarding no
AllowAgentForwarding no
PermitTunnel no
GatewayPorts no
PrintMotd no
PrintLastLog yes

# Logging (verbose for security monitoring)
SyslogFacility AUTH
LogLevel VERBOSE

# Warning banner
Banner /etc/issue.net

# SFTP (internal — no shell needed)
Subsystem sftp internal-sftp
SSHEOF

chmod 600 "$SSHD_CONFIG"
chown root:root "$SSHD_CONFIG"

# Warning banner
cat > /etc/issue.net << 'BANNER'
╔══════════════════════════════════════════════════════════╗
║  ⚠️  AUTHORIZED ACCESS ONLY                              ║
║  All connections are monitored and logged.               ║
║  Unauthorized access is prohibited and will be           ║
║  reported to law enforcement.                            ║
╚══════════════════════════════════════════════════════════╝
BANNER

# Regenerate host keys (ed25519 only — remove weak RSA 1024)
log "Regenerating SSH host keys..."
rm -f /etc/ssh/ssh_host_dsa_key* /etc/ssh/ssh_host_ecdsa_key*
ssh-keygen -t ed25519 -f /etc/ssh/ssh_host_ed25519_key -N "" &>/dev/null || true
ssh-keygen -t rsa -b 4096 -f /etc/ssh/ssh_host_rsa_key -N "" &>/dev/null || true

# Test config before restarting
sshd -t && log "SSH config syntax OK"
systemctl enable ssh --now
systemctl restart ssh
log "SSH restarted on port $SSH_PORT"

log "✅ Module 03 — SSH Hardening complete"
info "Connect: ssh -p $SSH_PORT -i ~/.ssh/id_ed25519 $ADMIN_USER@YOUR_IP"
info "Backup:  $BACKUP_DIR/sshd_config.bak"
