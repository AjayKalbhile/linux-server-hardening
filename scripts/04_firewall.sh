#!/bin/bash
# =============================================================================
# Module 04: Firewall — UFW + Fail2Ban
# CIS 3.5 compliant firewall, brute-force protection
# =============================================================================
set -euo pipefail
GREEN='\033[0;32m'; BLUE='\033[0;34m'; NC='\033[0m'
log()  { echo -e "${GREEN}[+] $1${NC}"; }
info() { echo -e "${BLUE}[*] $1${NC}"; }

[[ $EUID -ne 0 ]] && { echo "Run as root: sudo $0"; exit 1; }

SSH_PORT="${SSH_PORT:-2222}"
BACKUP_DIR="${BACKUP_DIR:-/var/backups/hardening}"
mkdir -p "$BACKUP_DIR"

# ── UFW Firewall ──────────────────────────────────────────
log "Configuring UFW firewall..."
apt-get install -yqq ufw

ufw --force reset >/dev/null 2>&1

# Default policies — deny all in, allow all out
ufw default deny incoming  >/dev/null
ufw default allow outgoing >/dev/null
ufw default deny forward   >/dev/null

# Allow only what's needed
ufw allow "$SSH_PORT/tcp" comment "SSH hardened"
ufw allow 80/tcp           comment "HTTP"
ufw allow 443/tcp          comment "HTTPS"

# Loopback (CIS 3.5.4)
ufw allow in  on lo
ufw allow out on lo
ufw deny in from 127.0.0.0/8
ufw deny in from ::1

# Rate limiting — block IPs hammering SSH
ufw limit "$SSH_PORT/tcp" comment "SSH rate limit"

# Logging
ufw logging on

ufw --force enable >/dev/null
log "UFW active — default deny, SSH/$SSH_PORT + HTTP/HTTPS allowed"

# ── Fail2Ban ──────────────────────────────────────────────
log "Configuring Fail2Ban..."
apt-get install -yqq fail2ban

# Backup original
cp /etc/fail2ban/jail.conf "$BACKUP_DIR/jail.conf.bak" 2>/dev/null || true

cat > /etc/fail2ban/jail.local << F2BEOF
# Fail2Ban — Linux Server Hardening v3.0

[DEFAULT]
# Ban for 1 hour after 3 failures in 10 minutes
bantime   = 3600
findtime  = 600
maxretry  = 3
banaction = iptables-multiport
backend   = systemd

# Email notifications (set your email if needed)
# destemail = admin@yourdomain.com
# action    = %(action_mwl)s

[sshd]
enabled  = true
port     = $SSH_PORT
filter   = sshd
logpath  = /var/log/auth.log
maxretry = 3
bantime  = 7200

[sshd-ddos]
enabled  = true
port     = $SSH_PORT
filter   = sshd-ddos
logpath  = /var/log/auth.log
maxretry = 6
bantime  = 86400

[recidive]
enabled  = true
logpath  = /var/log/fail2ban.log
banaction = iptables-allports
bantime  = 604800
findtime = 86400
maxretry = 3
F2BEOF

systemctl enable fail2ban --now
systemctl restart fail2ban
log "Fail2Ban running — SSH protected on port $SSH_PORT"

log "✅ Module 04 — Firewall & Fail2Ban complete"
info "UFW status:  sudo ufw status verbose"
info "F2B status:  sudo fail2ban-client status sshd"
info "F2B bans:    sudo fail2ban-client status sshd | grep 'Banned IP'"
