#!/bin/bash
# =============================================================================
# Module 09: Rootkit Scanner — rkhunter + chkrootkit
# Daily automated rootkit detection and alerting
# =============================================================================
set -euo pipefail

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'
log()  { echo -e "${GREEN}[+] $1${NC}"; }
warn() { echo -e "${YELLOW}[-] $1${NC}"; }
info() { echo -e "${BLUE}[*] $1${NC}"; }

[[ $EUID -ne 0 ]] && { echo "Run as root: sudo $0"; exit 1; }

log "Installing rootkit scanners..."
apt-get install -yqq rkhunter chkrootkit

# Configure rkhunter
log "Configuring rkhunter..."
cat >> /etc/rkhunter.conf << 'RKHCONF'
# rkhunter config additions — Linux Server Hardening v3.0
MAIL_ON_WARNING=root
PKGMGR=DPKG
ALLOW_SSH_PROT_V1=0
SCRIPTWHITELIST=/usr/bin/egrep
SCRIPTWHITELIST=/usr/bin/fgrep
SCRIPTWHITELIST=/usr/bin/ldd
SCRIPTWHITELIST=/usr/bin/vendor_perl/GET
ALLOWHIDDENDIR=/dev/.udev
ALLOWHIDDENDIR=/dev/.static
ALLOWHIDDENFILE=/dev/.blkid.tab
RKHCONF

# Update rkhunter database
rkhunter --update --nocolors 2>&1 | tail -5 || true
rkhunter --propupd --nocolors 2>&1 | tail -3 || true
log "rkhunter database updated"

# Daily scan cron
mkdir -p /var/log/rkhunter
cat > /etc/cron.daily/rootkit-scan << 'CRON'
#!/bin/bash
DATE=$(date +%Y%m%d)
RKH_LOG="/var/log/rkhunter/rkhunter-$DATE.log"
CKR_LOG="/var/log/chkrootkit-$DATE.log"

# rkhunter scan
rkhunter --check --skip-keypress --nocolors --quiet > "$RKH_LOG" 2>&1
RKH_WARNINGS=$(grep -c "Warning:" "$RKH_LOG" 2>/dev/null || echo 0)

# chkrootkit scan
chkrootkit 2>&1 > "$CKR_LOG"
CKR_INFECTED=$(grep -c "INFECTED" "$CKR_LOG" 2>/dev/null || echo 0)

if [ "$RKH_WARNINGS" -gt 0 ] || [ "$CKR_INFECTED" -gt 0 ]; then
    logger -t rootkit-scan "ALERT: rkhunter=$RKH_WARNINGS warnings, chkrootkit=$CKR_INFECTED infected"
    {
        echo "ROOTKIT SCAN ALERT on $(hostname) at $(date)"
        echo "rkhunter warnings:     $RKH_WARNINGS"
        echo "chkrootkit infections: $CKR_INFECTED"
        echo ""
        echo "--- rkhunter warnings ---"
        grep "Warning:" "$RKH_LOG"
        echo ""
        echo "--- chkrootkit infections ---"
        grep "INFECTED" "$CKR_LOG"
    } | mail -s "[SECURITY] Rootkit Alert on $(hostname)" root 2>/dev/null || true
else
    logger -t rootkit-scan "OK: No rootkits detected"
fi
CRON
chmod +x /etc/cron.daily/rootkit-scan

# Run initial scan (non-fatal — new installs always have some warnings)
log "Running initial rkhunter scan (may show warnings on fresh install)..."
rkhunter --check --skip-keypress --nocolors --quiet 2>&1 | tail -5 || true

log "✅ Module 09 — Rootkit Scanner complete"
info "Manual rkhunter: sudo rkhunter --check --sk"
info "Manual chkrootkit: sudo chkrootkit"
info "Logs: /var/log/rkhunter/ and /var/log/chkrootkit-YYYYMMDD.log"
