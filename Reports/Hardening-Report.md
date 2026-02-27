## Security Check

[+] ✅ Auto-updates & audit configured
[+] Securing services...
disabled
inactive
[+] ✅ avahi-daemon already secure
not-found
inactive
[+] ✅ cups already secure
disabled
inactive
[+] ✅ bluetooth already secure
not-found
inactive
[+] ✅ telnet already secure
not-found
inactive
[+] ✅ postfix already secure
alias
[+] 🔒 Disabled mysql
disabled
inactive
[+] ✅ apache2 already secure



## 🎉 HARDENING COMPLETE! REBOOT RECOMMENDED

[*] Admin: pentester / nogle1NcO9ZiFLmrsCe7XOoJ
[*] SSH: ssh -p 2222 -i id_ed25519 pentester@YOUR_IP
[*] Test: ./test-hardening.sh
[*] Lynis Report: cat /var/log/lynis-report.log



[-] Admin user 'pentester' already exists
[+] Hardening SSH...
Synchronizing state of ssh.service with SysV service script with /usr/lib/systemd/systemd-sysv-install.
Executing: /usr/lib/systemd/systemd-sysv-install enable ssh
[+] ✅ SSH hardened (port 2222, keys only)
[+] Configuring firewall...
[+] ✅ UFW configured (3 ports only)
Synchronizing state of fail2ban.service with SysV service script with /usr/lib/systemd/systemd-sysv-install.
Executing: /usr/lib/systemd/systemd-sysv-install enable fail2ban
[+] ✅ Fail2Ban protecting SSH
[+] Configuring AppArmor...
Profile for /etc/apparmor.d/usr.sbin.sshd not found, skipping
Synchronizing state of apparmor.service with SysV service script with /usr/lib/systemd/systemd-sysv-install.
Executing: /usr/lib/systemd/systemd-sysv-install enable apparmor
[+] ✅ AppArmor enforcing SSH profile
[+] Applying kernel hardening...
[+] ✅ Kernel hardened
[+] Configuring auto-updates & audit...
Reading package lists... Done
