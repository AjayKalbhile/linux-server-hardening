#!/bin/bash
# =============================================================================
# status.sh — Live Server Security Dashboard
# Real-time view of all hardening controls and security posture
# =============================================================================

GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BLUE='\033[0;34m'; BOLD='\033[1m'; NC='\033[0m'

ok()   { echo -e "  ${GREEN}✅  $1${NC}"; }
fail() { echo -e "  ${RED}❌  $1${NC}"; }
warn() { echo -e "  ${YELLOW}⚠️   $1${NC}"; }
info() { echo -e "  ${BLUE}ℹ️   $1${NC}"; }

svc_ok()  { systemctl is-active --quiet "$1" 2>/dev/null && ok "$2" || fail "$2"; }
svc_val() { systemctl is-active --quiet "$1" 2>/dev/null && echo -e "${GREEN}active${NC}" || echo -e "${RED}inactive${NC}"; }

clear
echo -e "${CYAN}${BOLD}"
echo "  ╔═══════════════════════════════════════════════════════╗"
echo "  ║      🛡️  SERVER SECURITY DASHBOARD v3.0              ║"
echo "  ╚═══════════════════════════════════════════════════════╝"
echo -e "${NC}"
echo -e "  Host:   ${BOLD}$(hostname)${NC}"
echo -e "  OS:     $(lsb_release -ds 2>/dev/null || cat /etc/os-release | grep PRETTY_NAME | cut -d'"' -f2)"
echo -e "  Time:   $(date '+%Y-%m-%d %H:%M:%S UTC')"
echo -e "  Uptime: $(uptime -p 2>/dev/null || echo 'unknown')"
echo -e "  IP:     $(hostname -I | awk '{print $1}')"
echo ""

# ── SSH ───────────────────────────────────────────────────
echo -e "${CYAN}[ SSH ]${NC}"
SSH_PORT=$(grep "^Port " /etc/ssh/sshd_config 2>/dev/null | awk '{print $2}' || echo "22")
SSH_ROOT=$(grep "^PermitRootLogin " /etc/ssh/sshd_config 2>/dev/null | awk '{print $2}' || echo "?")
SSH_PASS=$(grep "^PasswordAuthentication " /etc/ssh/sshd_config 2>/dev/null | awk '{print $2}' || echo "?")

echo -e "  Port:     ${BOLD}$SSH_PORT${NC}  $([ "$SSH_PORT" = "2222" ] && echo -e "${GREEN}(non-default ✓)${NC}" || echo -e "${YELLOW}(consider changing)${NC}")"
echo -e "  Root:     $SSH_ROOT  $([ "$SSH_ROOT" = "no" ] && echo -e "${GREEN}(disabled ✓)${NC}" || echo -e "${RED}(ENABLED — fix!)${NC}")"
echo -e "  Password: $SSH_PASS  $([ "$SSH_PASS" = "no" ] && echo -e "${GREEN}(keys only ✓)${NC}" || echo -e "${RED}(ENABLED — fix!)${NC}")"
svc_ok ssh "SSH service running"
echo ""

# ── Firewall ──────────────────────────────────────────────
echo -e "${CYAN}[ FIREWALL ]${NC}"
UFW_STATUS=$(ufw status 2>/dev/null | head -1 | awk '{print $2}' || echo "unknown")
echo -e "  UFW: ${BOLD}$UFW_STATUS${NC}"
if [ "$UFW_STATUS" = "active" ]; then
    ufw status 2>/dev/null | grep -E "ALLOW|DENY" | while read -r line; do
        echo -e "    ${GREEN}▶${NC} $line"
    done
else
    fail "UFW is not active — server is unprotected!"
fi
echo ""

# ── Services ──────────────────────────────────────────────
echo -e "${CYAN}[ SERVICES ]${NC}"
svc_ok fail2ban "Fail2Ban (brute-force protection)"
svc_ok apparmor "AppArmor (mandatory access control)"
svc_ok auditd   "auditd (system call auditing)"
svc_ok unattended-upgrades "Auto-updates"
echo ""

# ── Fail2Ban Stats ─────────────────────────────────────────
echo -e "${CYAN}[ FAIL2BAN STATS ]${NC}"
if systemctl is-active --quiet fail2ban 2>/dev/null; then
    TOTAL_BANS=$(fail2ban-client status sshd 2>/dev/null | grep "Total banned" | awk '{print $NF}' || echo "0")
    CURR_BANS=$(fail2ban-client status sshd  2>/dev/null | grep "Currently banned" | awk '{print $NF}' || echo "0")
    echo -e "  Total bans:   ${BOLD}$TOTAL_BANS${NC}"
    echo -e "  Active bans:  ${BOLD}$CURR_BANS${NC}"
else
    warn "Fail2Ban not running"
fi
echo ""

# ── Intrusion Detection ────────────────────────────────────
echo -e "${CYAN}[ INTRUSION DETECTION ]${NC}"
[ -f /var/lib/aide/aide.db ] && ok "AIDE database initialized" || fail "AIDE database missing (run module 08)"
command -v rkhunter &>/dev/null    && ok "rkhunter installed"    || fail "rkhunter missing (run module 09)"
command -v chkrootkit &>/dev/null  && ok "chkrootkit installed"  || fail "chkrootkit missing (run module 09)"
echo ""

# ── Kernel Params ─────────────────────────────────────────
echo -e "${CYAN}[ KERNEL HARDENING ]${NC}"
ASLR=$(sysctl -n kernel.randomize_va_space 2>/dev/null || echo "?")
KPTR=$(sysctl -n kernel.kptr_restrict 2>/dev/null || echo "?")
SYNCK=$(sysctl -n net.ipv4.tcp_syncookies 2>/dev/null || echo "?")
REDIR=$(sysctl -n net.ipv4.conf.all.accept_redirects 2>/dev/null || echo "?")

[ "$ASLR"  = "2" ] && ok "ASLR enabled (level 2)"         || fail "ASLR not fully enabled (is $ASLR, want 2)"
[ "$KPTR"  = "2" ] && ok "Kernel pointers restricted"     || fail "Kernel pointers exposed (is $KPTR, want 2)"
[ "$SYNCK" = "1" ] && ok "SYN cookies enabled"            || fail "SYN cookies disabled"
[ "$REDIR" = "0" ] && ok "ICMP redirects disabled"        || fail "ICMP redirects enabled"
echo ""

# ── Recent Auth Activity ───────────────────────────────────
echo -e "${CYAN}[ RECENT AUTH ACTIVITY ]${NC}"
FAILED_TODAY=$(grep "Failed password" /var/log/auth.log 2>/dev/null | grep "$(date '+%b %_d')" | wc -l)
LAST_LOGIN=$(last -1 2>/dev/null | head -1 | awk '{print $1, $3, $4, $5, $6}')
echo -e "  Failed logins today: ${BOLD}$FAILED_TODAY${NC}"
echo -e "  Last login: $LAST_LOGIN"
echo ""

# ── Quick Score ────────────────────────────────────────────
echo -e "${CYAN}[ QUICK SCORE ]${NC}"
if [ -f "$(dirname "$0")/tests/test-hardening.sh" ]; then
    SCORE=$(bash "$(dirname "$0")/tests/test-hardening.sh" 2>/dev/null | grep "Results:" | grep -oP '\d+/\d+' || echo "?/?")
    GRADE=$(bash "$(dirname "$0")/tests/test-hardening.sh" 2>/dev/null | grep "Grade:" | grep -oP '[A-C][+]?' || echo "?")
    echo -e "  Test score: ${BOLD}$SCORE${NC}"
    echo -e "  Grade:      ${BOLD}$GRADE${NC}"
else
    info "Run: sudo ./tests/test-hardening.sh"
fi

echo ""
echo -e "${CYAN}═══════════════════════════════════════════════════════${NC}"
echo -e "  Full report:  sudo ./reports/generate_report.sh"
echo -e "  Full tests:   sudo ./tests/test-hardening.sh"
echo -e "  CIS check:    sudo ./scripts/11_cis_benchmark.sh"
echo -e "${CYAN}═══════════════════════════════════════════════════════${NC}"
echo ""
