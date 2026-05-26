#!/bin/bash
# =============================================================================
# rollback.sh — Safely undo hardening changes
# Restores from backups created by harden-server.sh
# =============================================================================
set -euo pipefail

GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; NC='\033[0m'
log()   { echo -e "${GREEN}[+] $1${NC}"; }
error() { echo -e "${RED}[!] $1${NC}"; exit 1; }
warn()  { echo -e "${YELLOW}[-] $1${NC}"; }
info()  { echo -e "${BLUE}[*] $1${NC}"; }

[[ $EUID -ne 0 ]] && error "Run as root: sudo $0"

MODULE="all"
while [[ $# -gt 0 ]]; do
    case $1 in
        --all)           MODULE="all" ;;
        --module)        MODULE="$2"; shift ;;
        --list)
            echo "Available rollback targets:"
            echo "  --all       Undo all hardening"
            echo "  --module ssh       Restore SSH config"
            echo "  --module firewall  Disable UFW rules"
            echo "  --module fail2ban  Restore Fail2Ban defaults"
            echo "  --module kernel    Restore kernel sysctl"
            echo "  --module 2fa       Remove 2FA from SSH"
            exit 0 ;;
        *) error "Unknown option: $1. Use --list to see options." ;;
    esac
    shift
done

BACKUP_BASE="/var/backups/hardening"
LATEST_BACKUP=$(ls -td "$BACKUP_BASE"/20* 2>/dev/null | head -1 || echo "")

echo ""
echo "╔══════════════════════════════════════════╗"
echo "║    Linux Server Hardening — ROLLBACK     ║"
echo "╚══════════════════════════════════════════╝"
echo ""
echo "  Module:  $MODULE"
echo "  Backup:  ${LATEST_BACKUP:-none found}"
echo ""
warn "This will undo hardening changes. Server will be LESS secure."
read -rp "  Continue? [y/N]: " confirm
[[ "$confirm" =~ ^[Yy]$ ]] || { echo "Aborted."; exit 0; }

rollback_ssh() {
    info "Rolling back SSH..."
    if [ -f /etc/ssh/sshd_config.bak ]; then
        cp /etc/ssh/sshd_config.bak /etc/ssh/sshd_config
        systemctl restart ssh 2>/dev/null || systemctl restart sshd 2>/dev/null || true
        log "SSH config restored from backup"
    else
        warn "No SSH backup found at /etc/ssh/sshd_config.bak"
    fi
}

rollback_firewall() {
    info "Rolling back UFW firewall..."
    ufw --force disable 2>/dev/null || true
    ufw --force reset 2>/dev/null || true
    log "UFW disabled and reset"
}

rollback_fail2ban() {
    info "Rolling back Fail2Ban..."
    systemctl stop fail2ban 2>/dev/null || true
    systemctl disable fail2ban 2>/dev/null || true
    rm -f /etc/fail2ban/jail.local
    log "Fail2Ban stopped and default config restored"
}

rollback_kernel() {
    info "Rolling back kernel hardening..."
    rm -f /etc/sysctl.d/99-hardening.conf
    sysctl --system >/dev/null 2>&1
    log "Custom sysctl params removed, defaults restored"
}

rollback_apparmor() {
    info "Rolling back AppArmor..."
    systemctl stop apparmor 2>/dev/null || true
    systemctl disable apparmor 2>/dev/null || true
    log "AppArmor disabled"
}

rollback_2fa() {
    info "Rolling back 2FA..."
    if [ -f /etc/pam.d/sshd.bak.2fa ]; then
        cp /etc/pam.d/sshd.bak.2fa /etc/pam.d/sshd
    fi
    if [ -f /etc/ssh/sshd_config.bak.2fa ]; then
        cp /etc/ssh/sshd_config.bak.2fa /etc/ssh/sshd_config
    fi
    systemctl reload ssh 2>/dev/null || systemctl reload sshd 2>/dev/null || true
    log "2FA removed from SSH"
}

rollback_aide() {
    info "Rolling back AIDE..."
    rm -f /etc/cron.daily/aide-check
    systemctl stop aide 2>/dev/null || true
    log "AIDE daily check removed"
}

case "$MODULE" in
    all)
        rollback_ssh
        rollback_firewall
        rollback_fail2ban
        rollback_kernel
        rollback_apparmor
        rollback_2fa
        rollback_aide
        ;;
    ssh)       rollback_ssh ;;
    firewall)  rollback_firewall ;;
    fail2ban)  rollback_fail2ban ;;
    kernel)    rollback_kernel ;;
    apparmor)  rollback_apparmor ;;
    2fa)       rollback_2fa ;;
    aide)      rollback_aide ;;
    *)         error "Unknown module: $MODULE. Use --list to see options." ;;
esac

echo ""
log "Rollback complete for: $MODULE"
warn "Server security has been reduced. Reboot recommended."
echo ""
