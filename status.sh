#!/bin/bash
echo "🔒 SERVER SECURITY DASHBOARD @ $(date)"
echo "══════════════════════════════"
printf "🌐 IP: %-15s  🛡️ UFW: %s\n" "$(hostname -I|awk '{print$1}')" "$(sudo ufw status|head -1)"
printf "🔑 SSH: %-15s  🚫 Fail2Ban: %s\n" "$(grep '^Port' /etc/ssh/sshd_config|cut -d' ' -f2)" "$(sudo systemctl is-active fail2ban)"
printf "🛡️ AppArmor: %-12s  📊 Lynis: %s\n" "$(sudo aa-status 2>/dev/null|head -1|cut -d' ' -f1)" "$(sudo lynis audit system 2>/dev/null|grep 'hardening index'|cut -d':' -f2|xargs)"
echo "═══════════════════════════════════════════════"
sudo ./test-hardening.sh
