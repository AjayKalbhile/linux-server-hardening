#!/bin/bash
# =============================================================================
# Module 08: AIDE — Advanced Intrusion Detection Environment
# Detects unauthorized file changes, rootkit file drops, config tampering
# =============================================================================
set -euo pipefail

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'
log()  { echo -e "${GREEN}[+] $1${NC}"; }
warn() { echo -e "${YELLOW}[-] $1${NC}"; }
info() { echo -e "${BLUE}[*] $1${NC}"; }

[[ $EUID -ne 0 ]] && { echo "Run as root: sudo $0"; exit 1; }

log "Installing AIDE..."
apt-get install -yqq aide aide-common

# Write AIDE config
cat > /etc/aide/aide.conf << 'AIDECONF'
# AIDE Configuration — Linux Server Hardening v3.0
database=file:/var/lib/aide/aide.db
database_out=file:/var/lib/aide/aide.db.new
gzip_dbout=yes

# Rule definitions
FIPSR  = p+i+n+u+g+s+m+c+acl+sha256
NORMAL = p+i+n+u+g+s+m+c+sha256

# Critical binaries — full monitoring
/bin         FIPSR
/sbin        FIPSR
/usr/bin     FIPSR
/usr/sbin    FIPSR
/lib         FIPSR
/boot        FIPSR

# Configuration files
/etc         NORMAL
!/etc/mtab
!/etc/.*~

# SSH specifically
/etc/ssh/sshd_config  FIPSR
/root/.ssh             FIPSR

# Exclusions — dynamic paths that change legitimately
!/proc
!/sys
!/dev
!/run
!/tmp
!/var/log
!/var/cache
!/var/lib/dpkg
AIDECONF

log "Initializing AIDE database (2-3 minutes)..."
aideinit --yes 2>&1 | grep -E "(Initialized|New database)" || true
cp /var/lib/aide/aide.db.new /var/lib/aide/aide.db 2>/dev/null || true
log "AIDE database: /var/lib/aide/aide.db"

# Daily cron integrity check
mkdir -p /var/log/aide
cat > /etc/cron.daily/aide-check << 'CRON'
#!/bin/bash
REPORT="/var/log/aide/aide-$(date +%Y%m%d).log"
aide --check > "$REPORT" 2>&1
CHANGED=$(grep -cE "^(Added|Removed|Changed)" "$REPORT" 2>/dev/null || echo 0)
if [ "$CHANGED" -gt 0 ]; then
    logger -t aide "WARNING: $CHANGED file integrity violations detected"
    echo "AIDE found $CHANGED changes. See $REPORT" | \
        mail -s "[SECURITY] AIDE Alert on $(hostname)" root 2>/dev/null || true
fi
CRON
chmod +x /etc/cron.daily/aide-check

log "✅ Module 08 — AIDE File Integrity Monitoring complete"
info "Check now:           sudo aide --check"
info "Update after changes: sudo aide --update && sudo cp /var/lib/aide/aide.db.new /var/lib/aide/aide.db"
info "Daily log:           /var/log/aide/aide-YYYYMMDD.log"
