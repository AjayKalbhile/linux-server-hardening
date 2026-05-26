#!/bin/bash
# =============================================================================
# generate_report.sh — HTML & JSON Security Report Generator
# Produces a professional security posture report
# =============================================================================
set -euo pipefail

FORMAT="${1:---html}"
REPORT_DIR="/var/log/hardening"
DATE=$(date +%Y%m%d_%H%M%S)
HTML_REPORT="$REPORT_DIR/report_$DATE.html"
JSON_REPORT="$REPORT_DIR/report_$DATE.json"

[[ $EUID -ne 0 ]] && { echo "Run as root: sudo $0"; exit 1; }
mkdir -p "$REPORT_DIR"

# Collect data
HOSTNAME=$(hostname)
OS=$(lsb_release -ds 2>/dev/null || cat /etc/os-release | grep PRETTY_NAME | cut -d'"' -f2)
UPTIME=$(uptime -p 2>/dev/null || echo "unknown")
DATE_NICE=$(date '+%B %d, %Y %H:%M UTC')

# SSH checks
SSH_PORT=$(grep "^Port " /etc/ssh/sshd_config 2>/dev/null | awk '{print $2}' || echo "22")
SSH_ROOT=$(grep "^PermitRootLogin" /etc/ssh/sshd_config 2>/dev/null | awk '{print $2}' || echo "unknown")
SSH_PASS=$(grep "^PasswordAuthentication" /etc/ssh/sshd_config 2>/dev/null | awk '{print $2}' || echo "unknown")

# Service status helpers
svc_status() { systemctl is-active "$1" 2>/dev/null || echo "inactive"; }
svc_badge()  { [ "$(svc_status "$1")" = "active" ] && echo "ACTIVE" || echo "INACTIVE"; }

UFW_STATUS=$(ufw status 2>/dev/null | head -1 | awk '{print $2}' || echo "unknown")
F2B_STATUS=$(svc_badge fail2ban)
AA_STATUS=$(svc_badge apparmor)
AUDIT_STATUS=$(svc_badge auditd)
AIDE_DB=$([ -f /var/lib/aide/aide.db ] && echo "Initialized" || echo "Not initialized")
RKH=$(command -v rkhunter &>/dev/null && echo "Installed" || echo "Not installed")
CHKRK=$(command -v chkrootkit &>/dev/null && echo "Installed" || echo "Not installed")

# Kernel params
ASLR=$(sysctl -n kernel.randomize_va_space 2>/dev/null || echo "unknown")
KPTR=$(sysctl -n kernel.kptr_restrict 2>/dev/null || echo "unknown")
SYNCOOKIES=$(sysctl -n net.ipv4.tcp_syncookies 2>/dev/null || echo "unknown")

# Run test suite to get score
SCORE_RAW=$(bash "$(dirname "$0")/../tests/test-hardening.sh" 2>/dev/null | grep "Results:" | grep -oP '\d+/\d+' | head -1 || echo "?/?")
GRADE_RAW=$(bash "$(dirname "$0")/../tests/test-hardening.sh" 2>/dev/null | grep "Grade:" | grep -oP '[A-C][+]?' | head -1 || echo "?")

# Fail2Ban recent bans
F2B_BANS=$(fail2ban-client status sshd 2>/dev/null | grep "Total banned" | awk '{print $NF}' || echo "N/A")
F2B_CURRENT=$(fail2ban-client status sshd 2>/dev/null | grep "Currently banned" | awk '{print $NF}' || echo "N/A")

# JSON Report
cat > "$JSON_REPORT" << JSONEOF
{
  "report_metadata": {
    "hostname": "$HOSTNAME",
    "os": "$OS",
    "generated": "$DATE_NICE",
    "uptime": "$UPTIME"
  },
  "test_results": {
    "score": "$SCORE_RAW",
    "grade": "$GRADE_RAW"
  },
  "ssh": {
    "port": "$SSH_PORT",
    "permit_root_login": "$SSH_ROOT",
    "password_auth": "$SSH_PASS"
  },
  "services": {
    "ufw": "$UFW_STATUS",
    "fail2ban": "$F2B_STATUS",
    "apparmor": "$AA_STATUS",
    "auditd": "$AUDIT_STATUS"
  },
  "intrusion_detection": {
    "aide_database": "$AIDE_DB",
    "rkhunter": "$RKH",
    "chkrootkit": "$CHKRK"
  },
  "kernel": {
    "aslr": "$ASLR",
    "kptr_restrict": "$KPTR",
    "tcp_syncookies": "$SYNCOOKIES"
  },
  "fail2ban_stats": {
    "total_banned": "$F2B_BANS",
    "currently_banned": "$F2B_CURRENT"
  }
}
JSONEOF

# HTML Report
GRADE_COLOR="#22c55e"
[ "$GRADE_RAW" = "B" ] && GRADE_COLOR="#f59e0b"
[ "$GRADE_RAW" = "C" ] && GRADE_COLOR="#ef4444"

cat > "$HTML_REPORT" << HTMLEOF
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Security Report — $HOSTNAME</title>
<style>
  * { box-sizing: border-box; margin: 0; padding: 0; }
  body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif; background: #0f172a; color: #e2e8f0; padding: 2rem; }
  .container { max-width: 900px; margin: 0 auto; }
  .header { background: #1e293b; border: 1px solid #334155; border-radius: 12px; padding: 2rem; margin-bottom: 1.5rem; display: flex; justify-content: space-between; align-items: center; }
  .header h1 { font-size: 1.5rem; font-weight: 600; color: #f1f5f9; }
  .header p  { color: #94a3b8; font-size: 0.875rem; margin-top: 0.25rem; }
  .grade-circle { width: 80px; height: 80px; border-radius: 50%; background: ${GRADE_COLOR}20; border: 3px solid ${GRADE_COLOR}; display: flex; flex-direction: column; align-items: center; justify-content: center; }
  .grade-letter { font-size: 2rem; font-weight: 700; color: ${GRADE_COLOR}; line-height: 1; }
  .grade-label  { font-size: 0.6rem; color: #94a3b8; text-transform: uppercase; letter-spacing: 0.05em; }
  .grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 1rem; margin-bottom: 1.5rem; }
  .card { background: #1e293b; border: 1px solid #334155; border-radius: 10px; padding: 1.25rem; }
  .card h3 { font-size: 0.75rem; font-weight: 500; color: #64748b; text-transform: uppercase; letter-spacing: 0.08em; margin-bottom: 0.5rem; }
  .card .value { font-size: 1.25rem; font-weight: 600; color: #f1f5f9; }
  .card .sub { font-size: 0.8rem; color: #94a3b8; margin-top: 0.25rem; }
  .section { background: #1e293b; border: 1px solid #334155; border-radius: 10px; padding: 1.5rem; margin-bottom: 1rem; }
  .section h2 { font-size: 0.875rem; font-weight: 600; color: #94a3b8; text-transform: uppercase; letter-spacing: 0.08em; margin-bottom: 1rem; border-bottom: 1px solid #334155; padding-bottom: 0.75rem; }
  .check-row { display: flex; align-items: center; justify-content: space-between; padding: 0.5rem 0; border-bottom: 1px solid #1e293b; }
  .check-row:last-child { border-bottom: none; }
  .check-label { font-size: 0.875rem; color: #cbd5e1; }
  .badge { padding: 0.2rem 0.6rem; border-radius: 999px; font-size: 0.7rem; font-weight: 600; }
  .badge.good { background: #14532d; color: #86efac; }
  .badge.bad  { background: #7f1d1d; color: #fca5a5; }
  .badge.warn { background: #78350f; color: #fcd34d; }
  .badge.info { background: #1e3a5f; color: #93c5fd; }
  .footer { text-align: center; color: #475569; font-size: 0.75rem; margin-top: 2rem; }
</style>
</head>
<body>
<div class="container">

<div class="header">
  <div>
    <h1>🛡️ Server Security Report</h1>
    <p>$HOSTNAME &nbsp;·&nbsp; $OS</p>
    <p>Generated: $DATE_NICE &nbsp;·&nbsp; Uptime: $UPTIME</p>
  </div>
  <div class="grade-circle">
    <div class="grade-letter">$GRADE_RAW</div>
    <div class="grade-label">Grade</div>
  </div>
</div>

<div class="grid">
  <div class="card">
    <h3>Test Score</h3>
    <div class="value">$SCORE_RAW</div>
    <div class="sub">Hardening controls passed</div>
  </div>
  <div class="card">
    <h3>SSH Port</h3>
    <div class="value">$SSH_PORT</div>
    <div class="sub">Non-standard port active</div>
  </div>
  <div class="card">
    <h3>Fail2Ban Bans</h3>
    <div class="value">$F2B_BANS</div>
    <div class="sub">Total IPs blocked ($F2B_CURRENT current)</div>
  </div>
  <div class="card">
    <h3>AIDE Status</h3>
    <div class="value" style="font-size:1rem;">$AIDE_DB</div>
    <div class="sub">File integrity monitor</div>
  </div>
</div>

<div class="section">
  <h2>SSH Configuration</h2>
  <div class="check-row">
    <span class="check-label">SSH Port</span>
    <span class="badge $([ "$SSH_PORT" = "2222" ] && echo good || echo warn)">$SSH_PORT</span>
  </div>
  <div class="check-row">
    <span class="check-label">Root Login</span>
    <span class="badge $([ "$SSH_ROOT" = "no" ] && echo good || echo bad)">$SSH_ROOT</span>
  </div>
  <div class="check-row">
    <span class="check-label">Password Authentication</span>
    <span class="badge $([ "$SSH_PASS" = "no" ] && echo good || echo bad)">$SSH_PASS</span>
  </div>
</div>

<div class="section">
  <h2>Services</h2>
  <div class="check-row"><span class="check-label">UFW Firewall</span>
    <span class="badge $([ "$UFW_STATUS" = "active" ] && echo good || echo bad)">$UFW_STATUS</span></div>
  <div class="check-row"><span class="check-label">Fail2Ban</span>
    <span class="badge $([ "$F2B_STATUS" = "ACTIVE" ] && echo good || echo bad)">$F2B_STATUS</span></div>
  <div class="check-row"><span class="check-label">AppArmor</span>
    <span class="badge $([ "$AA_STATUS" = "ACTIVE" ] && echo good || echo bad)">$AA_STATUS</span></div>
  <div class="check-row"><span class="check-label">auditd</span>
    <span class="badge $([ "$AUDIT_STATUS" = "ACTIVE" ] && echo good || echo bad)">$AUDIT_STATUS</span></div>
</div>

<div class="section">
  <h2>Intrusion Detection</h2>
  <div class="check-row"><span class="check-label">AIDE Database</span>
    <span class="badge $([ "$AIDE_DB" = "Initialized" ] && echo good || echo bad)">$AIDE_DB</span></div>
  <div class="check-row"><span class="check-label">rkhunter</span>
    <span class="badge $([ "$RKH" = "Installed" ] && echo good || echo bad)">$RKH</span></div>
  <div class="check-row"><span class="check-label">chkrootkit</span>
    <span class="badge $([ "$CHKRK" = "Installed" ] && echo good || echo bad)">$CHKRK</span></div>
</div>

<div class="section">
  <h2>Kernel Hardening</h2>
  <div class="check-row"><span class="check-label">ASLR (randomize_va_space)</span>
    <span class="badge $([ "$ASLR" = "2" ] && echo good || echo bad)">$ASLR / 2</span></div>
  <div class="check-row"><span class="check-label">Kernel pointer restrict</span>
    <span class="badge $([ "$KPTR" = "2" ] && echo good || echo bad)">$KPTR / 2</span></div>
  <div class="check-row"><span class="check-label">TCP SYN cookies</span>
    <span class="badge $([ "$SYNCOOKIES" = "1" ] && echo good || echo bad)">$SYNCOOKIES / 1</span></div>
</div>

<div class="footer">
  Generated by Linux Server Hardening Toolkit v3.0 &nbsp;·&nbsp;
  <a href="https://github.com/AjayKalbhlile/linux-server-hardening" style="color:#60a5fa;">GitHub</a>
</div>

</div>
</body>
</html>
HTMLEOF

echo ""
echo "[+] Reports generated:"
echo "    HTML: $HTML_REPORT"
echo "    JSON: $JSON_REPORT"
echo ""
echo "[*] View HTML: xdg-open $HTML_REPORT"
