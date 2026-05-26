#!/bin/bash
# =============================================================================
# Module 06: Kernel Hardening — Sysctl Parameters
# CIS 3.1–3.4 | ASLR | Pointer restrict | Network hardening
# =============================================================================
set -euo pipefail
GREEN='\033[0;32m'; BLUE='\033[0;34m'; NC='\033[0m'
log()  { echo -e "${GREEN}[+] $1${NC}"; }
info() { echo -e "${BLUE}[*] $1${NC}"; }

[[ $EUID -ne 0 ]] && { echo "Run as root: sudo $0"; exit 1; }

BACKUP_DIR="${BACKUP_DIR:-/var/backups/hardening}"
mkdir -p "$BACKUP_DIR"

cp /etc/sysctl.conf "$BACKUP_DIR/sysctl.conf.bak" 2>/dev/null || true

log "Applying kernel hardening parameters..."
cat > /etc/sysctl.d/99-hardening.conf << 'SYSCTL'
# =====================================================
# Kernel Hardening — Linux Server Hardening v3.0
# CIS Ubuntu 22.04 LTS — Sections 3.1, 3.2, 3.3, 3.4
# =====================================================

# ── Kernel security ──────────────────────────────────
# Hide kernel pointers from unprivileged users (CIS 6.1.2)
kernel.kptr_restrict = 2

# Restrict dmesg to root (CIS 6.1.3)
kernel.dmesg_restrict = 1

# Full ASLR — randomize memory addresses (CIS 6.1.1)
kernel.randomize_va_space = 2

# Disable SysRq (prevents keyboard-triggered crashes)
kernel.sysrq = 0

# Restrict ptrace scope (CIS 1.6)
kernel.yama.ptrace_scope = 1

# Disable core dumps (CIS 1.6.1)
fs.suid_dumpable = 0

# ── Network — Packet & Routing ────────────────────────
# Enable SYN cookies (CIS 3.2.8 — prevent SYN flood DDoS)
net.ipv4.tcp_syncookies = 1

# Disable IP forwarding (not a router) (CIS 3.1.1)
net.ipv4.ip_forward = 0
net.ipv6.conf.all.forwarding = 0

# Reverse path filter — prevent IP spoofing (CIS 3.2.7)
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1

# Disable source routing (CIS 3.2.1)
net.ipv4.conf.all.accept_source_route = 0
net.ipv4.conf.default.accept_source_route = 0
net.ipv6.conf.all.accept_source_route = 0

# Disable ICMP redirect acceptance (CIS 3.2.2)
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
net.ipv6.conf.all.accept_redirects = 0

# Disable sending redirects (CIS 3.1.1)
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.default.send_redirects = 0

# Log suspicious packets (martian, redirects, source routes)
net.ipv4.conf.all.log_martians = 1
net.ipv4.conf.default.log_martians = 1

# Disable broadcast ping (Smurf attack prevention)
net.ipv4.icmp_echo_ignore_broadcasts = 1

# Ignore bogus error responses
net.ipv4.icmp_ignore_bogus_error_responses = 1

# ── IPv6 ──────────────────────────────────────────────
# Disable IPv6 if not needed
net.ipv6.conf.all.disable_ipv6 = 1
net.ipv6.conf.default.disable_ipv6 = 1
net.ipv6.conf.lo.disable_ipv6 = 1

# ── Uncommon protocols (CIS 3.4) ─────────────────────
# Handled via modprobe.d in module 01
SYSCTL

# Apply immediately
sysctl --system >/dev/null 2>&1
log "Kernel parameters applied"

# Disable unused network protocols via modprobe
cat > /etc/modprobe.d/cis-network-protocols.conf << 'MODS'
install dccp    /bin/true
install sctp    /bin/true
install rds     /bin/true
install tipc    /bin/true
install n-hdlc  /bin/true
install ax25    /bin/true
install netrom  /bin/true
install x25     /bin/true
install rose    /bin/true
MODS
log "Uncommon network protocols disabled"

log "✅ Module 06 — Kernel Hardening complete"
info "Verify ASLR:  sysctl kernel.randomize_va_space   (should be 2)"
info "Verify SYN:   sysctl net.ipv4.tcp_syncookies      (should be 1)"
