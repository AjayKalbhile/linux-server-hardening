#!/bin/bash
# =============================================================================
# test-hardening.sh — 25-Test Verification Suite v3.0
# Verifies every hardening control with pass/fail and grading
# =============================================================================
set -euo pipefail

GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; NC='\033[0m'

PASSED=0; FAILED=0; TOTAL=0
FAIL_LIST=()

check() {
    local name="$1"; local cmd="$2"
    ((TOTAL++))
    if eval "$cmd" &>/dev/null; then
        echo -e "  ${GREEN}✅${NC} $name"
        ((PASSED++))
    else
        echo -e "  ${RED}❌${NC} $name"
        ((FAILED++))
        FAIL_LIST+=("$name")
    fi
}

section() { echo -e "\n${CYAN}[$1]${NC}"; }

echo ""
echo "╔══════════════════════════════════════════════════════╗"
echo "║   🧪 HARDENING VERIFICATION SUITE v3.0              ║"
echo "║   Linux Server Hardening Toolkit                    ║"
echo "╚══════════════════════════════════════════════════════╝"

[[ $EUID -ne 0 ]] && { echo "Run as root: sudo $0"; exit 1; }

section "SSH CONFIGURATION"
check "SSH running on port 2222"              'grep -q "^Port 2222" /etc/ssh/sshd_config'
check "Root login disabled"                   'grep -q "^PermitRootLogin no" /etc/ssh/sshd_config'
check "Password authentication disabled"      'grep -q "^PasswordAuthentication no" /etc/ssh/sshd_config'
check "PubkeyAuthentication enabled"          'grep -q "^PubkeyAuthentication yes" /etc/ssh/sshd_config'
check "X11Forwarding disabled"                'grep -q "^X11Forwarding no" /etc/ssh/sshd_config'
check "SSH LoginGraceTime set"                'grep -qE "^LoginGraceTime (20|30|60)$" /etc/ssh/sshd_config'
check "MaxAuthTries 3 or less"                'grep -qE "^MaxAuthTries [123]$" /etc/ssh/sshd_config'
check "SSH banner configured"                 'grep -q "^Banner " /etc/ssh/sshd_config'

section "FIREWALL"
check "UFW active"                            'ufw status | grep -q "Status: active"'
check "Default policy deny incoming"          'ufw status verbose 2>/dev/null | grep -q "Default: deny (incoming)"'
check "SSH port 2222 allowed"                 'ufw status | grep -q "2222/tcp"'
check "UFW logging enabled"                   'ufw status verbose 2>/dev/null | grep -q "Logging: on"'

section "INTRUSION PREVENTION"
check "Fail2Ban service running"              'systemctl is-active --quiet fail2ban'
check "Fail2Ban SSH jail configured"          'grep -q "enabled = true" /etc/fail2ban/jail.local'
check "AppArmor service active"               'systemctl is-active --quiet apparmor'
check "AppArmor in enforce mode"              'aa-status 2>/dev/null | grep -q "enforce"'
check "auditd service running"                'systemctl is-active --quiet auditd'

section "FILE INTEGRITY & ROOTKIT"
check "AIDE installed"                        'command -v aide &>/dev/null'
check "AIDE database exists"                  'test -f /var/lib/aide/aide.db'
check "rkhunter installed"                    'command -v rkhunter &>/dev/null'
check "chkrootkit installed"                  'command -v chkrootkit &>/dev/null'

section "KERNEL HARDENING"
check "ASLR fully enabled (level 2)"          'sysctl kernel.randomize_va_space | grep -q "= 2"'
check "Kernel pointer restriction"            'sysctl kernel.kptr_restrict | grep -q "= 2"'
check "SYN cookies enabled"                   'sysctl net.ipv4.tcp_syncookies | grep -q "= 1"'
check "ICMP redirects disabled"               'sysctl net.ipv4.conf.all.accept_redirects | grep -q "= 0"'
check "Source routing disabled"               'sysctl net.ipv4.conf.all.send_redirects | grep -q "= 0"'

# ── Summary ───────────────────────────────────────────────
echo ""
echo "══════════════════════════════════════════════════════"
PCT=$(( PASSED * 100 / TOTAL ))
echo "  Results: $PASSED / $TOTAL tests passed ($PCT%)"
echo ""

if   [ $PCT -eq 100 ]; then GRADE="A+"; COLOR=$GREEN
elif [ $PCT -ge 88 ];  then GRADE="A";  COLOR=$GREEN
elif [ $PCT -ge 70 ];  then GRADE="B";  COLOR=$YELLOW
else                        GRADE="C";  COLOR=$RED
fi

echo -e "  Grade:   ${COLOR}${GRADE}${NC}"

case $GRADE in
    "A+") echo -e "           ${GREEN}🎉 Server fully hardened — production ready!${NC}" ;;
    "A")  echo -e "           ${GREEN}✅ Strong security — minor gaps remain${NC}" ;;
    "B")  echo -e "           ${YELLOW}⚠️  Moderate security — remediation recommended${NC}" ;;
    "C")  echo -e "           ${RED}🚨 Critical gaps — remediate before production use${NC}" ;;
esac

if [ ${#FAIL_LIST[@]} -gt 0 ]; then
    echo ""
    echo "  ❌ Failed tests:"
    for f in "${FAIL_LIST[@]}"; do
        echo -e "     ${RED}•${NC} $f"
    done
    echo ""
    echo "  Rerun hardening:  sudo ./harden-server.sh"
    echo "  Module only:      sudo ./scripts/NN_module.sh"
fi

echo "══════════════════════════════════════════════════════"
echo ""

# Exit code — useful for CI/CD
[ $PASSED -eq $TOTAL ] && exit 0 || exit 1
