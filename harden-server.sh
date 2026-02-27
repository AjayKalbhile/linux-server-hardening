#!/bin/bash
# =============================================================================
# 🔒 LINUX SERVER HARDENING v2.0 - HackerAI Production Edition
# Ubuntu 22.04 LTS | UFW + Fail2Ban + AppArmor + SSH + Kernel
# =============================================================================
set -euo pipefail

# Colors
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'
NC='\033[0m'

log()    { echo -e "${GREEN}[+] $1${NC}"; }
warn()   { echo -e "${YELLOW}[-] $1${NC}"; }
error()  { echo -e "${RED}[!] $1${NC}"; exit 1; }
info()   { echo -e "${BLUE}[*] $1${NC}"; }

# Banner
cat << "EOF"
   ██████╗██╗  ██╗██████╗  █████╗ ████████╗███████╗
  ██╔════╝██║  ██║██╔══██╗██╔══██╗╚══██╔══╝██╔════╝
  ██║     ███████║██████╔╝███████║   ██║   █████╗  
  ██║     ██╔══██║██╔══██╗██╔══██║   ██║   ██╔══╝  
  ╚██████╗██║  ██║██████╔╝██║  ██║   ██║   ███████╗
   ╚═════╝╚═╝  ╚═╝╚═════╝ ╚═╝  ╚═╝   ╚═╝   ╚══════╝
                       v2.0 - Production Ready
EOF

# =============================================================================
# 1. SYSTEM UPDATE & PREREQS
# =============================================================================
log "Updating system..."
apt-get update -qq && apt-get upgrade -yqq
apt-get install -yqq curl wget git vim htop ufw fail2ban openssh-server \
    apparmor apparmor-utils unattended-upgrades auditd rsyslog logrotate lynis

# =============================================================================
# 2. CREATE SECURE ADMIN USER
# =============================================================================
ADMIN_USER="pentester"
ADMIN_PASS=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-24)

if ! id "$ADMIN_USER" &>/dev/null; then
    useradd -m -s /bin/bash "$ADMIN_USER"
    echo "$ADMIN_USER:$ADMIN_PASS" | chpasswd
    usermod -aG sudo "$ADMIN_USER"
    mkdir -p "/home/$ADMIN_USER/.ssh"
    chmod 700 "/home/$ADMIN_USER/.ssh"
    log "✅ Admin user '$ADMIN_USER' created"
    log "   Password: $ADMIN_PASS (CHANGE AFTER SSH KEY SETUP!)"
else
    warn "Admin user '$ADMIN_USER' already exists"
fi

# =============================================================================
# 3. SSH HARDENING (PORT 2222, KEYS ONLY)
# =============================================================================
log "Hardening SSH..."
SSHD_CONFIG="/etc/ssh/sshd_config"

backup_sshd() {
    [ -f "$SSHD_CONFIG.bak" ] || cp "$SSHD_CONFIG" "$SSHD_CONFIG.bak"
}

cat << 'EOF' > "$SSHD_CONFIG"
# 🔒 SSH HARDENING CONFIGURATION v2.0
Port 2222
Protocol 2
PermitRootLogin no
PasswordAuthentication no
PubkeyAuthentication yes
AuthorizedKeysFile .ssh/authorized_keys
PermitEmptyPasswords no
ChallengeResponseAuthentication no
UsePAM yes
X11Forwarding no
PrintMotd no
ClientAliveInterval 600
ClientAliveCountMax 0
LoginGraceTime 30
MaxAuthTries 3
MaxSessions 2
Banner /etc/issue.net
AllowUsers pentester
AcceptEnv LANG LC_*
Subsystem sftp internal-sftp
EOF

backup_sshd
chmod 600 "$SSHD_CONFIG"
restorecon "$SSHD_CONFIG" 2>/dev/null || true

# Generate SSH keys for pentester
if [ ! -f "/home/$ADMIN_USER/.ssh/id_ed25519" ]; then
    ssh-keygen -t ed25519 -f "/home/$ADMIN_USER/.ssh/id_ed25519" -N "" -C "pentester@hardened"
    cat "/home/$ADMIN_USER/.ssh/id_ed25519.pub" >> "/home/$ADMIN_USER/.ssh/authorized_keys"
    chmod 600 "/home/$ADMIN_USER/.ssh/authorized_keys"
    chown -R "$ADMIN_USER:$ADMIN_USER" "/home/$ADMIN_USER/.ssh"
    log "✅ SSH keys generated: /home/$ADMIN_USER/.ssh/id_ed25519"
fi

# Banner
echo "🚫 UNAUTHORIZED ACCESS PROHIBITED - ALL TRAFFIC LOGGED" > /etc/issue.net

systemctl enable ssh --now
log "✅ SSH hardened (port 2222, keys only)"

# =============================================================================
# 4. UFW FIREWALL + FAIL2BAN
# =============================================================================
log "Configuring firewall..."

# UFW
ufw --force reset >/dev/null 2>&1
ufw default deny incoming >/dev/null 2>&1
ufw default allow outgoing >/dev/null 2>&1
ufw allow 2222/tcp comment "SSH hardened" >/dev/null 2>&1
ufw allow 80/tcp comment "HTTP" >/dev/null 2>&1
ufw allow 443/tcp comment "HTTPS" >/dev/null 2>&1
ufw --force enable >/dev/null 2>&1
log "✅ UFW configured (3 ports only)"

# Fail2Ban
cat << 'EOF' > /etc/fail2ban/jail.local
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 3

[sshd]
enabled = true
port = 2222
filter = sshd
logpath = /var/log/auth.log
EOF

systemctl enable fail2ban --now
log "✅ Fail2Ban protecting SSH"

# =============================================================================
# 5. APPARMOR (Ubuntu SELinux)
# =============================================================================
log "Configuring AppArmor..."
aa-enforce /etc/apparmor.d/usr.sbin.sshd 2>/dev/null || true
systemctl enable apparmor --now
log "✅ AppArmor enforcing SSH profile"

# =============================================================================
# 6. KERNEL HARDENING
# =============================================================================
log "Applying kernel hardening..."
cat << 'EOF' > /etc/sysctl.d/99-hardening.conf
# Kernel security
kernel.kptr_restrict = 2
kernel.dmesg_restrict = 1
kernel.randomize_va_space = 2
kernel.sysrq = 0
kernel.yama.ptrace_scope = 1

# Network security
net.ipv4.tcp_syncookies = 1
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
net.ipv4.conf.all.send_redirects = 0
EOF

sysctl --system >/dev/null 2>&1
log "✅ Kernel hardened"

# =============================================================================
# 7. AUTO UPDATES & AUDIT
# =============================================================================
log "Configuring auto-updates & audit..."

# Unattended upgrades
apt-get install -y unattended-upgrades
cat << 'EOF' >> /etc/apt/apt.conf.d/50unattended-upgrades
Unattended-Upgrade::Allowed-Origins {
    "${DISTRO_ID}:${DISTRO_CODENAME}-security";
    "${DISTRO_ID}:${DISTRO_CODENAME}-updates";
};
EOF
dpkg-reconfigure -f noninteractive unattended-upgrades

# Auditd
cat << 'EOF' > /etc/audit/rules.d/hardening.rules
-w /etc/passwd -p wa -k identity
-w /etc/ssh/sshd_config -p wa -k sshd
-w /etc/sudoers -p wa -k actions
EOF
systemctl restart auditd >/dev/null 2>&1

log "✅ Auto-updates & audit configured"

# =============================================================================
# 8. DISABLE UNNECESSARY SERVICES (ERROR-PROOF)
# =============================================================================
log "Securing services..."
services=(avahi-daemon cups bluetooth telnet postfix mysql apache2)

for svc in "${services[@]}"; do
    if systemctl is-enabled "${svc}.service" 2>/dev/null || systemctl is-active "${svc}.service" 2>/dev/null; then
        systemctl stop "${svc}.service" 2>/dev/null || true
        systemctl disable "${svc}.service" 2>/dev/null || true
        log "🔒 Disabled $svc"
    else
        log "✅ $svc already secure"
    fi
done

# =============================================================================
# 9. MOTD & FINAL STATUS
# =============================================================================
cat << 'EOF' > /etc/update-motd.d/00-hardening
#!/bin/sh
printf "\n🔒 HARDENED SERVER STATUS\n"
printf "   Lynis Score: $(lynis audit system | grep -o 'Tests performed: [0-9]*' | cut -d' ' -f3)/[0-9]*\n"
printf "   UFW: $(ufw status | head -1)\n"
printf "   SSH: Port 2222 (Keys Only)\n"
printf "   Public IP: $(curl -4 ifconfig.me 2>/dev/null || echo 'N/A')\n\n"
EOF
chmod +x /etc/update-motd.d/00-hardening

# Run Lynis quick scan
lynis audit system | tee /var/log/lynis-report.log >/dev/null 2>&1

log "🎉 HARDENING COMPLETE! REBOOT RECOMMENDED"
info "Admin: pentester / $ADMIN_PASS"
info "SSH: ssh -p 2222 -i id_ed25519 pentester@YOUR_IP"
info "Test: ./test-hardening.sh"
info "Lynis Report: cat /var/log/lynis-report.log"

exit 0
