#!/bin/bash
# =============================================================================
# audit.sh — Weekly Re-Audit + Email Alert System
# Re-runs full test suite, rootkit scan, AIDE check, emails results
# =============================================================================
set -euo pipefail

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'
BLUE='\033[0;34m'; NC='\033[0m'
log()   { echo -e "${GREEN}[+] $1${NC}"; }
warn()  { echo -e "${YELLOW}[-] $1${NC}"; }
error() { echo -e "${RED}[!] $1${NC}"; }
info()  { echo -e "${BLUE}[*] $1${NC}"; }

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ALERT_EMAIL="${ALERT_EMAIL:-}"
SETUP_CRON=false

# Parse args
while [[ $# -gt 0 ]]; do
    case $1 in
        --setup-cron) SETUP_CRON=true ;;
        --email)      ALERT_EMAIL="$2"; shift ;;
        --run)        ;; # just run the audit
        *) echo "Usage: $0 [--setup-cron] [--email addr@domain.com] [--run]"; exit 0 ;;
    esac
    shift
done

# Setup cron mode
if [ "$SETUP_CRON" = true ]; then
    CRON_LINE="0 6 * * 1 root ALERT_EMAIL=${ALERT_EMAIL} $SCRIPT_DIR/audit.sh --run >> /var/log/hardening/weekly-audit.log 2>&1"
    if ! grep -q "audit.sh" /etc/crontab 2>/dev/null; then
        echo "$CRON_LINE" >> /etc/crontab
        log "Weekly audit cron configured (every Monday 06:00)"
    else
        warn "Cron already configured — skipping"
    fi
    log "Email alerts: ${ALERT_EMAIL:-not configured}"
    info "Run manually: sudo $0 --run"
    exit 0
fi

[[ $EUID -ne 0 ]] && { echo "Run as root: sudo $0 --run"; exit 1; }

REPORT_DIR="/var/log/hardening"
DATE=$(date +%Y%m%d_%H%M%S)
REPORT="$REPORT_DIR/weekly-audit-$DATE.txt"
mkdir -p "$REPORT_DIR"

HOSTNAME=$(hostname)
ISSUES=0

{
echo "======================================================"
echo "  WEEKLY SECURITY AUDIT — $HOSTNAME"
echo "  Date: $(date)"
echo "======================================================"
echo ""

# ── Test Suite ─────────────────────────────────────────────
echo "[ HARDENING TESTS ]"
if [ -f "$SCRIPT_DIR/tests/test-hardening.sh" ]; then
    bash "$SCRIPT_DIR/tests/test-hardening.sh" 2>/dev/null | tail -10
    SCORE=$(bash "$SCRIPT_DIR/tests/test-hardening.sh" 2>/dev/null | grep "Results:" | grep -oP '\d+/\d+' || echo "?/?")
    echo "Score: $SCORE"
else
    echo "test-hardening.sh not found"
fi
echo ""

# ── AIDE File Integrity ────────────────────────────────────
echo "[ AIDE FILE INTEGRITY ]"
if command -v aide &>/dev/null && [ -f /var/lib/aide/aide.db ]; then
    AIDE_OUT=$(aide --check 2>&1 | tail -5)
    CHANGES=$(aide --check 2>&1 | grep -cE "^(Added|Removed|Changed)" 2>/dev/null || echo 0)
    echo "$AIDE_OUT"
    echo "Changes detected: $CHANGES"
    [ "$CHANGES" -gt 0 ] && { ISSUES=$((ISSUES + CHANGES)); echo "⚠️  File integrity violations!"; }
else
    echo "AIDE not configured — run module 08"
fi
echo ""

# ── Rootkit Scan ───────────────────────────────────────────
echo "[ ROOTKIT SCAN ]"
if command -v rkhunter &>/dev/null; then
    rkhunter --update --nocolors -q 2>/dev/null || true
    RKH_WARN=$(rkhunter --check --skip-keypress --nocolors -q 2>/dev/null | grep -c "Warning:" || echo 0)
    echo "rkhunter warnings: $RKH_WARN"
    [ "$RKH_WARN" -gt 0 ] && ISSUES=$((ISSUES + RKH_WARN))
else
    echo "rkhunter not installed — run module 09"
fi

if command -v chkrootkit &>/dev/null; then
    CKR=$(chkrootkit 2>/dev/null | grep -c "INFECTED" || echo 0)
    echo "chkrootkit infected: $CKR"
    [ "$CKR" -gt 0 ] && ISSUES=$((ISSUES + CKR))
fi
echo ""

# ── Fail2Ban Stats ─────────────────────────────────────────
echo "[ FAIL2BAN STATS ]"
if systemctl is-active --quiet fail2ban 2>/dev/null; then
    fail2ban-client status sshd 2>/dev/null | grep -E "Total|Currently" || echo "No data"
else
    echo "Fail2Ban not running"
    ISSUES=$((ISSUES + 1))
fi
echo ""

# ── Open Ports ─────────────────────────────────────────────
echo "[ OPEN PORTS ]"
ss -tlnp 2>/dev/null | grep LISTEN || netstat -tlnp 2>/dev/null | grep LISTEN || echo "Could not check"
echo ""

# ── Last Logins ────────────────────────────────────────────
echo "[ LAST 5 LOGINS ]"
last -5 2>/dev/null || echo "No login data"
echo ""

# ── Failed Login Attempts ──────────────────────────────────
echo "[ FAILED LOGIN ATTEMPTS (last 24h) ]"
grep "Failed password" /var/log/auth.log 2>/dev/null | \
    grep "$(date +%b\ %d)" | wc -l | \
    xargs -I{} echo "{} failed attempts today"
echo ""

echo "======================================================"
echo "  TOTAL ISSUES: $ISSUES"
echo "  Status: $([ $ISSUES -eq 0 ] && echo 'CLEAN ✅' || echo 'ACTION REQUIRED ⚠️')"
echo "======================================================"

} | tee "$REPORT"

# Email if issues found or email configured
if [ -n "$ALERT_EMAIL" ] && [ "$ISSUES" -gt 0 ]; then
    mail -s "[SECURITY ALERT] $ISSUES issues on $HOSTNAME" "$ALERT_EMAIL" < "$REPORT" 2>/dev/null \
        && log "Alert email sent to $ALERT_EMAIL" \
        || warn "Email send failed — check mail config"
elif [ -n "$ALERT_EMAIL" ]; then
    mail -s "[SECURITY OK] Weekly audit clean on $HOSTNAME" "$ALERT_EMAIL" < "$REPORT" 2>/dev/null || true
fi

log "Audit report: $REPORT"
[ "$ISSUES" -gt 0 ] && exit 1 || exit 0
