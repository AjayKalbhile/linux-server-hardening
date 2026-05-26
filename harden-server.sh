#!/bin/bash
# =============================================================================
# 🛡️ LINUX SERVER HARDENING v3.0
# Ubuntu 22.04 LTS | Modular | CIS Benchmark | AIDE | 2FA | Rootkit Scanner
# =============================================================================
set -euo pipefail

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; CYAN='\033[0;36m'; NC='\033[0m'

log()    { echo -e "${GREEN}[+] $1${NC}"; }
warn()   { echo -e "${YELLOW}[-] $1${NC}"; }
error()  { echo -e "${RED}[!] $1${NC}"; exit 1; }
info()   { echo -e "${BLUE}[*] $1${NC}"; }
section(){ echo -e "\n${CYAN}══════════════════════════════════════${NC}"; echo -e "${CYAN}  $1${NC}"; echo -e "${CYAN}══════════════════════════════════════${NC}"; }

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BACKUP_DIR="/var/backups/hardening/$(date +%Y%m%d_%H%M%S)"
LOG_FILE="/var/log/hardening/hardening_$(date +%Y%m%d_%H%M%S).log"
INTERACTIVE=false
MODULES_TO_RUN="all"

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --interactive|-i) INTERACTIVE=true ;;
        --module) MODULES_TO_RUN="$2"; shift ;;
        --help|-h)
            echo "Usage: $0 [--interactive] [--module MODULE_NUMBER]"
            echo "  --interactive    Run wizard to select modules"
            echo "  --module 1-11    Run a specific module only"
            echo "  --help           Show this help"
            exit 0 ;;
    esac
    shift
done

# Check root
[[ $EUID -ne 0 ]] && error "Run as root: sudo $0"

# Setup logging
mkdir -p "$(dirname "$LOG_FILE")" "$BACKUP_DIR"
exec > >(tee -a "$LOG_FILE") 2>&1

cat << "BANNER"
  ██╗  ██╗ █████╗ ██████╗ ██████╗ ███████╗███╗  ██╗
  ██║  ██║██╔══██╗██╔══██╗██╔══██╗██╔════╝████╗ ██║
  ███████║███████║██████╔╝██║  ██║█████╗  ██╔██╗██║
  ██╔══██║██╔══██║██╔══██╗██║  ██║██╔══╝  ██║╚████║
  ██║  ██║██║  ██║██║  ██║██████╔╝███████╗██║  ███║
  ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚═════╝ ╚══════╝╚═╝  ╚══╝
         Linux Server Hardening v3.0 | CIS Aligned
BANNER

info "Log: $LOG_FILE"
info "Backups: $BACKUP_DIR"

# Interactive mode
if [ "$INTERACTIVE" = true ]; then
    section "Interactive Setup Wizard"
    read -rp "Admin username [pentester]: " ADMIN_USER
    ADMIN_USER="${ADMIN_USER:-pentester}"
    read -rp "SSH port [2222]: " SSH_PORT
    SSH_PORT="${SSH_PORT:-2222}"
    read -rp "Alert email (leave blank to skip): " ALERT_EMAIL
    echo ""
    echo "Modules to enable (enter numbers separated by space, or 'all'):"
    echo "  1=System Update   2=User Hardening  3=SSH          4=Firewall"
    echo "  5=AppArmor        6=Kernel          7=Auto Updates 8=AIDE IDS"
    echo "  9=Rootkit Scanner 10=2FA            11=CIS Benchmark"
    read -rp "Modules [all]: " MODULES_TO_RUN
    MODULES_TO_RUN="${MODULES_TO_RUN:-all}"
else
    ADMIN_USER="${ADMIN_USER:-pentester}"
    SSH_PORT="${SSH_PORT:-2222}"
    ALERT_EMAIL="${ALERT_EMAIL:-}"
fi

export ADMIN_USER SSH_PORT ALERT_EMAIL BACKUP_DIR

# Run modules
run_module() {
    local num="$1"
    local script="$SCRIPT_DIR/scripts/$(printf '%02d' $num)_*.sh"
    for f in $script; do
        if [ -f "$f" ]; then
            section "Module $num — $(basename "$f" .sh | cut -d_ -f2-)"
            bash "$f"
            log "Module $num complete"
        fi
    done
}

if [ "$MODULES_TO_RUN" = "all" ]; then
    for i in $(seq 1 11); do run_module $i; done
else
    for mod in $MODULES_TO_RUN; do run_module $mod; done
fi

# Final summary
section "Hardening Complete"
log "All selected modules applied"
info "Backups saved to: $BACKUP_DIR"
info "Log saved to:     $LOG_FILE"
info ""
info "Next steps:"
info "  1. Test:   sudo ./tests/test-hardening.sh"
info "  2. Status: sudo ./status.sh"
info "  3. Report: sudo ./reports/generate_report.sh"
info "  4. REBOOT: sudo reboot"
info ""
info "To rollback: sudo ./rollback.sh --all"
