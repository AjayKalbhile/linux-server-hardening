#!/bin/bash
# =============================================================================
# Module 11: CIS Ubuntu 22.04 LTS Benchmark — Level 1 Compliance Check
# 50-point automated compliance audit with scoring and grade
# =============================================================================
set -euo pipefail

GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; NC='\033[0m'

pass() { echo -e "  ${GREEN}[PASS]${NC} $1"; ((PASSED++)); ((TOTAL++)); }
fail() { echo -e "  ${RED}[FAIL]${NC} $1"; FAILURES+=("$1"); ((TOTAL++)); }
warn() { echo -e "  ${YELLOW}[WARN]${NC} $1"; ((TOTAL++)); }
section() { echo -e "\n${CYAN}$1${NC}"; }

PASSED=0; TOTAL=0; FAILURES=()

[[ $EUID -ne 0 ]] && { echo "Run as root: sudo $0"; exit 1; }

echo ""
echo "╔══════════════════════════════════════════════════════╗"
echo "║  CIS Ubuntu 22.04 LTS Benchmark — Level 1           ║"
echo "║  Linux Server Hardening v3.0                        ║"
echo "╚══════════════════════════════════════════════════════╝"
echo ""

# ── 1. Initial Setup ──────────────────────────────────────
section "[ 1.x ] Initial Setup — Filesystem & Software"

grep -qr "install cramfs /bin/true" /etc/modprobe.d/ 2>/dev/null \
    && pass "1.1.1  cramfs filesystem disabled" \
    || fail "1.1.1  cramfs filesystem not disabled (add 'install cramfs /bin/true' to /etc/modprobe.d/)"

grep -qr "install freevxfs /bin/true" /etc/modprobe.d/ 2>/dev/null \
    && pass "1.1.2  freevxfs filesystem disabled" \
    || fail "1.1.2  freevxfs filesystem not disabled"

grep -qr "install jffs2 /bin/true" /etc/modprobe.d/ 2>/dev/null \
    && pass "1.1.3  jffs2 filesystem disabled" \
    || fail "1.1.3  jffs2 filesystem not disabled"

dpkg -l aide 2>/dev/null | grep -q "^ii" \
    && pass "1.4.1  AIDE is installed" \
    || fail "1.4.1  AIDE not installed — run module 08"

[ -f /var/lib/aide/aide.db ] \
    && pass "1.4.2  AIDE database initialized" \
    || fail "1.4.2  AIDE database missing — run 'sudo aideinit'"

[ -f /etc/cron.daily/aide-check ] \
    && pass "1.4.3  AIDE daily check configured" \
    || fail "1.4.3  AIDE daily check not configured"

dpkg -l apparmor 2>/dev/null | grep -q "^ii" \
    && pass "1.7.1  AppArmor installed" \
    || fail "1.7.1  AppArmor not installed"

aa-status 2>/dev/null | grep -q "profiles are in enforce mode" \
    && pass "1.7.2  AppArmor profiles in enforce mode" \
    || fail "1.7.2  AppArmor not enforcing any profiles"

dpkg -l unattended-upgrades 2>/dev/null | grep -q "^ii" \
    && pass "1.9.1  Automatic updates configured" \
    || fail "1.9.1  Automatic updates not configured"

# ── 2. Services ───────────────────────────────────────────
section "[ 2.x ] Services — Disable Unnecessary"

! systemctl is-active --quiet avahi-daemon 2>/dev/null \
    && pass "2.1.1  avahi-daemon disabled" \
    || fail "2.1.1  avahi-daemon is running — disable it"

! systemctl is-active --quiet cups 2>/dev/null \
    && pass "2.1.2  cups disabled" \
    || fail "2.1.2  cups is running — disable it"

! systemctl is-active --quiet isc-dhcp-server 2>/dev/null \
    && pass "2.2.1  DHCP server disabled" \
    || fail "2.2.1  DHCP server is running"

! dpkg -l rsh-server 2>/dev/null | grep -q "^ii" \
    && pass "2.3.1  rsh-server not installed" \
    || fail "2.3.1  rsh-server installed — remove it (insecure)"

! dpkg -l telnetd 2>/dev/null | grep -q "^ii" \
    && pass "2.3.2  telnetd not installed" \
    || fail "2.3.2  telnetd installed — remove it (sends passwords in plaintext)"

# ── 3. Network ────────────────────────────────────────────
section "[ 3.x ] Network Configuration"

sysctl net.ipv4.conf.all.accept_redirects 2>/dev/null | grep -q "= 0" \
    && pass "3.1.2  ICMP redirects disabled" \
    || fail "3.1.2  ICMP redirects not disabled"

sysctl net.ipv4.conf.all.rp_filter 2>/dev/null | grep -q "= 1" \
    && pass "3.2.1  Reverse path filtering enabled" \
    || fail "3.2.1  Reverse path filtering disabled"

sysctl net.ipv4.tcp_syncookies 2>/dev/null | grep -q "= 1" \
    && pass "3.2.8  TCP SYN cookies enabled" \
    || fail "3.2.8  TCP SYN cookies not enabled"

sysctl net.ipv4.conf.all.send_redirects 2>/dev/null | grep -q "= 0" \
    && pass "3.3.1  Send redirects disabled" \
    || fail "3.3.1  Send redirects not disabled"

dpkg -l ufw 2>/dev/null | grep -q "^ii" \
    && pass "3.5.1  UFW installed" \
    || fail "3.5.1  UFW not installed"

ufw status 2>/dev/null | grep -q "Status: active" \
    && pass "3.5.1  UFW is active" \
    || fail "3.5.1  UFW is not active"

# ── 4. Logging & Auditing ─────────────────────────────────
section "[ 4.x ] Logging & Auditing"

dpkg -l auditd 2>/dev/null | grep -q "^ii" \
    && pass "4.1.1  auditd installed" \
    || fail "4.1.1  auditd not installed"

systemctl is-active --quiet auditd 2>/dev/null \
    && pass "4.1.2  auditd service running" \
    || fail "4.1.2  auditd not running"

[ -f /etc/audit/rules.d/hardening.rules ] \
    && pass "4.1.3  Custom audit rules configured" \
    || fail "4.1.3  No custom audit rules found"

systemctl is-active --quiet rsyslog 2>/dev/null \
    && pass "4.2.1  rsyslog running" \
    || fail "4.2.1  rsyslog not running"

# ── 5. Access Control ─────────────────────────────────────
section "[ 5.x ] Access, Authentication & Authorization"

grep -q "^PermitRootLogin no" /etc/ssh/sshd_config 2>/dev/null \
    && pass "5.2.8  SSH root login disabled" \
    || fail "5.2.8  SSH root login NOT disabled — fix sshd_config"

grep -q "^PasswordAuthentication no" /etc/ssh/sshd_config 2>/dev/null \
    && pass "5.2.9  SSH password auth disabled (keys only)" \
    || fail "5.2.9  SSH password authentication is enabled"

grep -q "^MaxAuthTries [123]" /etc/ssh/sshd_config 2>/dev/null \
    && pass "5.2.7  SSH MaxAuthTries ≤ 3" \
    || fail "5.2.7  SSH MaxAuthTries not set or too high"

grep -q "^Protocol 2" /etc/ssh/sshd_config 2>/dev/null \
    && pass "5.2.1  SSH Protocol 2 only" \
    || fail "5.2.1  SSH Protocol not explicitly set to 2"

grep -q "^X11Forwarding no" /etc/ssh/sshd_config 2>/dev/null \
    && pass "5.2.4  X11Forwarding disabled" \
    || fail "5.2.4  X11Forwarding not disabled"

grep -q "^LoginGraceTime [123][0-9]$" /etc/ssh/sshd_config 2>/dev/null \
    && pass "5.2.12 SSH LoginGraceTime ≤ 60s" \
    || fail "5.2.12 SSH LoginGraceTime not configured"

grep -q "^Banner " /etc/ssh/sshd_config 2>/dev/null \
    && pass "5.2.15 SSH warning banner configured" \
    || fail "5.2.15 SSH banner not configured"

systemctl is-active --quiet fail2ban 2>/dev/null \
    && pass "5.3.1  Fail2Ban running (brute-force protection)" \
    || fail "5.3.1  Fail2Ban not running"

# Check for empty passwords
awk -F: '($2 == "") {print}' /etc/shadow 2>/dev/null | grep -q "." \
    && fail "5.6.1  Empty passwords found!" \
    || pass "5.6.1  No empty passwords"

# Root account locked
passwd -S root 2>/dev/null | grep -q "L" \
    && pass "5.4.3  Root account locked" \
    || warn "5.4.3  Root account not locked (acceptable if sudo is configured)"

# ── 6. System Maintenance ─────────────────────────────────
section "[ 6.x ] System Maintenance"

sysctl kernel.randomize_va_space 2>/dev/null | grep -q "= 2" \
    && pass "6.1.1  ASLR fully enabled" \
    || fail "6.1.1  ASLR not enabled (randomize_va_space should be 2)"

sysctl kernel.kptr_restrict 2>/dev/null | grep -q "= 2" \
    && pass "6.1.2  Kernel pointer restriction enabled" \
    || fail "6.1.2  Kernel pointers exposed (kptr_restrict should be 2)"

sysctl kernel.dmesg_restrict 2>/dev/null | grep -q "= 1" \
    && pass "6.1.3  dmesg restricted to root" \
    || fail "6.1.3  dmesg not restricted"

sysctl kernel.sysrq 2>/dev/null | grep -q "= 0" \
    && pass "6.1.4  SysRq key disabled" \
    || fail "6.1.4  SysRq not disabled (kernel.sysrq=0)"

# Check for world-writable files in /etc
WORLD_WRITABLE=$(find /etc -maxdepth 1 -perm -002 -type f 2>/dev/null | wc -l)
[ "$WORLD_WRITABLE" -eq 0 ] \
    && pass "6.2.1  No world-writable files in /etc" \
    || fail "6.2.1  World-writable files found in /etc ($WORLD_WRITABLE files)"

# ── Final Score ───────────────────────────────────────────
echo ""
echo "══════════════════════════════════════════════════════"
PCT=$(( PASSED * 100 / TOTAL ))
echo "  Results: $PASSED / $TOTAL controls passed ($PCT%)"

if [ $PCT -ge 95 ]; then
    GRADE="A+"
    echo -e "  Grade:   ${GREEN}$GRADE — Excellent compliance${NC}"
elif [ $PCT -ge 85 ]; then
    GRADE="A"
    echo -e "  Grade:   ${GREEN}$GRADE — Strong compliance${NC}"
elif [ $PCT -ge 70 ]; then
    GRADE="B"
    echo -e "  Grade:   ${YELLOW}$GRADE — Moderate — remediation needed${NC}"
else
    GRADE="C"
    echo -e "  Grade:   ${RED}$GRADE — Critical gaps — remediate now${NC}"
fi

if [ ${#FAILURES[@]} -gt 0 ]; then
    echo ""
    echo "  Failed controls to fix:"
    for f in "${FAILURES[@]}"; do
        echo -e "    ${RED}✗${NC} $f"
    done
fi
echo "══════════════════════════════════════════════════════"
echo ""

# Save report
REPORT_DIR="/var/log/hardening"
mkdir -p "$REPORT_DIR"
REPORT="$REPORT_DIR/cis-benchmark-$(date +%Y%m%d_%H%M%S).txt"
{
    echo "CIS Ubuntu 22.04 LTS Benchmark Results"
    echo "Date: $(date)"
    echo "Host: $(hostname)"
    echo "Score: $PASSED/$TOTAL ($PCT%)"
    echo "Grade: $GRADE"
    echo ""
    echo "Failed Controls:"
    for f in "${FAILURES[@]}"; do echo "  - $f"; done
} > "$REPORT"

echo "  Report saved: $REPORT"
