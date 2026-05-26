#!/bin/bash
# =============================================================================
# Module 01: System Update & Prerequisites
# Updates system, installs all required tools, enables auditd + rsyslog
# =============================================================================
set -euo pipefail
GREEN='\033[0;32m'; BLUE='\033[0;34m'; NC='\033[0m'
log()  { echo -e "${GREEN}[+] $1${NC}"; }
info() { echo -e "${BLUE}[*] $1${NC}"; }

[[ $EUID -ne 0 ]] && { echo "Run as root: sudo $0"; exit 1; }

log "Updating system packages..."
apt-get update -qq
apt-get upgrade -yqq

log "Installing required tools..."
apt-get install -yqq \
    curl wget git vim htop \
    ufw fail2ban \
    openssh-server \
    apparmor apparmor-utils \
    unattended-upgrades apt-listchanges \
    auditd audispd-plugins rsyslog logrotate \
    aide aide-common \
    rkhunter chkrootkit \
    libpam-google-authenticator \
    lynis bc \
    net-tools dnsutils \
    unzip jq

log "Enabling and starting core services..."
systemctl enable --now auditd rsyslog 2>/dev/null || true

# Basic auditd rules
mkdir -p /etc/audit/rules.d
cat > /etc/audit/rules.d/hardening.rules << 'RULES'
# Linux Server Hardening v3.0 — Audit Rules
-w /etc/passwd         -p wa -k identity
-w /etc/group          -p wa -k identity
-w /etc/shadow         -p wa -k identity
-w /etc/sudoers        -p wa -k actions
-w /etc/ssh/sshd_config -p wa -k sshd
-w /var/log/auth.log   -p wa -k auth
-w /bin/su             -p x  -k priv_esc
-w /usr/bin/sudo       -p x  -k priv_esc
-a always,exit -F arch=b64 -S execve -k exec
RULES
systemctl restart auditd 2>/dev/null || true

# Disable cramfs, freevxfs, jffs2 (CIS 1.1.x)
cat > /etc/modprobe.d/cis-filesystems.conf << 'MODS'
install cramfs   /bin/true
install freevxfs /bin/true
install jffs2    /bin/true
install hfs      /bin/true
install hfsplus  /bin/true
install udf      /bin/true
MODS

log "✅ Module 01 — System Update & Prerequisites complete"
info "Packages installed, auditd running, unused filesystems disabled"
