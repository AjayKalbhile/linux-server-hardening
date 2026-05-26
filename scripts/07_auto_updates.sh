#!/bin/bash
# =============================================================================
# Module 07: Automatic Security Updates — Unattended Upgrades
# CIS 1.9 — Ensure updates and patches installed automatically
# =============================================================================
set -euo pipefail
GREEN='\033[0;32m'; BLUE='\033[0;34m'; NC='\033[0m'
log()  { echo -e "${GREEN}[+] $1${NC}"; }
info() { echo -e "${BLUE}[*] $1${NC}"; }

[[ $EUID -ne 0 ]] && { echo "Run as root: sudo $0"; exit 1; }

log "Installing unattended-upgrades..."
apt-get install -yqq unattended-upgrades apt-listchanges

# Configure what to auto-upgrade
cat > /etc/apt/apt.conf.d/50unattended-upgrades << 'CONF'
// Linux Server Hardening v3.0 — Auto Updates Config
Unattended-Upgrade::Allowed-Origins {
    "${distro_id}:${distro_codename}";
    "${distro_id}:${distro_codename}-security";
    "${distro_id}ESMApps:${distro_codename}-apps-security";
    "${distro_id}ESM:${distro_codename}-infra-security";
    "${distro_id}:${distro_codename}-updates";
};

// Auto-remove unused kernels and dependencies
Unattended-Upgrade::Remove-Unused-Kernel-Packages "true";
Unattended-Upgrade::Remove-New-Unused-Dependencies "true";
Unattended-Upgrade::Remove-Unused-Dependencies "true";

// Auto-reboot at 02:00 if kernel update requires it
Unattended-Upgrade::Automatic-Reboot "true";
Unattended-Upgrade::Automatic-Reboot-Time "02:00";

// Email on errors
// Unattended-Upgrade::Mail "admin@yourdomain.com";
// Unattended-Upgrade::MailReport "on-change";

// Verbose logging
Unattended-Upgrade::Verbose "false";
Unattended-Upgrade::Debug "false";
CONF

# Enable auto-update schedule
cat > /etc/apt/apt.conf.d/20auto-upgrades << 'SCHED'
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Download-Upgradeable-Packages "1";
APT::Periodic::AutocleanInterval "7";
APT::Periodic::Unattended-Upgrade "1";
SCHED

# Enable and start the service
systemctl enable unattended-upgrades --now
systemctl restart unattended-upgrades

log "✅ Module 07 — Auto Updates complete"
info "Status:    sudo systemctl status unattended-upgrades"
info "Dry run:   sudo unattended-upgrades --dry-run --debug"
info "Logs:      /var/log/unattended-upgrades/"
