### **2. `harden-server.sh`** 🔥 **MAIN SCRIPT**
```bash
#!/bin/bash
# 🛡️ UBUNTU 22.04 SERVER HARDENING v2.1 - PRODUCTION READY

set -euo pipefail
echo "🛡️ Starting Linux Server Hardening v2.1..."

# CUSTOM USERNAME (change this!)
ADMIN_USER="${ADMIN_USER:-pentester}"
ADMIN_PASS="TempPass123!"  # CHANGE IMMEDIATELY after SSH!

# Update & essentials
apt update && apt upgrade -y
apt install -y ufw fail2ban apparmor-utils unattended-upgrades lynis bc curl

# Create admin user
useradd -m -s /bin/bash "$ADMIN_USER" || true
echo "$ADMIN_USER:$ADMIN_PASS" | chpasswd
usermod -aG sudo "$ADMIN_USER"
echo "$ADMIN_USER ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/"$ADMIN_USER"

# SSH Hardening
sed -i 's/#Port 22/Port 2222/' /etc/ssh/sshd_config
sed -i 's/#?PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
sed -i 's/#?PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config
sed -i 's/#?PubkeyAuthentication.*/PubkeyAuthentication yes/' /etc/ssh/sshd_config
systemctl restart ssh

# UFW Firewall
ufw --force reset
ufw default deny incoming
ufw default allow outgoing
ufw allow 2222/tcp
ufw --force enable

# Fail2Ban
cat > /etc/fail2ban/jail.local << EOF
[sshd]
enabled = true
port = 2222
maxretry = 3
bantime = 3600
EOF
systemctl restart fail2ban

# AppArmor (SSH profile)
aa-enforce /usr/sbin/sshd

# Kernel Hardening
cat >> /etc/sysctl.conf << EOF
kernel.kptr_restrict = 2
kernel.dmesg_restrict = 1
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.default.rp_filter = 1
EOF
sysctl -p

# Auto-updates
dpkg-reconfigure -plow unattended-upgrades

echo "✅ HARDENING COMPLETE!"
echo "👤 Admin: $ADMIN_USER / SSH:2222"
echo "⚠️  CHANGE PASSWORD: passwd $ADMIN_USER"
echo "🔑 Setup SSH keys next!"
