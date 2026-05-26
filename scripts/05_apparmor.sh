#!/bin/bash
# =============================================================================
# Module 05: AppArmor — Mandatory Access Control
# CIS 1.7 — Enforce profiles for SSH and system daemons
# =============================================================================
set -euo pipefail
GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'
log()  { echo -e "${GREEN}[+] $1${NC}"; }
warn() { echo -e "${YELLOW}[-] $1${NC}"; }
info() { echo -e "${BLUE}[*] $1${NC}"; }

[[ $EUID -ne 0 ]] && { echo "Run as root: sudo $0"; exit 1; }

log "Installing AppArmor..."
apt-get install -yqq apparmor apparmor-utils apparmor-profiles apparmor-profiles-extra

log "Enabling AppArmor service..."
systemctl enable apparmor --now
systemctl start apparmor

# Enforce all loaded profiles
log "Setting all profiles to enforce mode..."
aa-enforce /etc/apparmor.d/* 2>/dev/null | grep -v "Warning\|Skipping" || true

# Enforce SSH specifically
if [ -f /etc/apparmor.d/usr.sbin.sshd ]; then
    aa-enforce /etc/apparmor.d/usr.sbin.sshd 2>/dev/null \
        && log "SSH AppArmor profile enforcing" \
        || warn "SSH profile not found — using default confinement"
fi

# Show status
ENFORCED=$(aa-status 2>/dev/null | grep "profiles are in enforce" | awk '{print $1}' || echo "?")
COMPLAIN=$(aa-status 2>/dev/null | grep "profiles are in complain" | awk '{print $1}' || echo "?")

log "AppArmor profiles — enforce: $ENFORCED | complain: $COMPLAIN"
log "✅ Module 05 — AppArmor complete"
info "Status:  sudo aa-status"
info "Logs:    sudo journalctl -f -k | grep apparmor"
