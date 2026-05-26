# Rollback Guide — Linux Server Hardening Toolkit v3.0

> Use this guide to safely undo any hardening change if something breaks.

## ⚠️ Before You Rollback

**Always keep a second terminal session open** when hardening SSH or the firewall.
If you lock yourself out, you'll need console/KVM access to recover.

---

## Quick Rollback Commands

```bash
# Undo everything
sudo ./rollback.sh --all

# Undo only SSH changes
sudo ./rollback.sh --module ssh

# Undo only firewall
sudo ./rollback.sh --module firewall

# Undo only Fail2Ban
sudo ./rollback.sh --module fail2ban

# Undo only kernel changes
sudo ./rollback.sh --module kernel

# Undo 2FA (if locked out)
sudo ./rollback.sh --module 2fa

# List all rollback options
./rollback.sh --list
```

---

## Manual Rollback — SSH

If the `rollback.sh` script is inaccessible, restore SSH manually:

```bash
# Restore from backup
sudo cp /etc/ssh/sshd_config.bak /etc/ssh/sshd_config
sudo systemctl restart ssh

# Or reset to Ubuntu defaults
sudo apt-get install --reinstall openssh-server
```

---

## Manual Rollback — UFW

```bash
# Disable firewall completely
sudo ufw disable

# Reset to factory defaults
sudo ufw reset

# Allow all traffic temporarily
sudo ufw default allow incoming
sudo ufw enable
```

---

## Manual Rollback — Fail2Ban

```bash
# Stop Fail2Ban
sudo systemctl stop fail2ban

# Unban your IP if you locked yourself out
sudo fail2ban-client set sshd unbanip YOUR.IP.ADDRESS

# Remove custom jail config
sudo rm /etc/fail2ban/jail.local
sudo systemctl restart fail2ban
```

---

## Manual Rollback — Kernel (sysctl)

```bash
# Remove hardening config
sudo rm /etc/sysctl.d/99-hardening.conf

# Reload defaults
sudo sysctl --system

# Or restore from backup
sudo cp /var/backups/hardening/sysctl.conf.bak /etc/sysctl.conf
sudo sysctl -p
```

---

## Manual Rollback — 2FA

If you're locked out due to 2FA misconfiguration:

```bash
# Remove Google Authenticator from PAM
sudo cp /etc/pam.d/sshd.bak.2fa /etc/pam.d/sshd

# Restore SSH config
sudo cp /etc/ssh/sshd_config.bak.2fa /etc/ssh/sshd_config
sudo systemctl reload ssh
```

---

## Recovery via Console (Last Resort)

If locked out completely:

1. Access server via hypervisor console (VNC/KVM/IPMI)
2. Login as root physically
3. Run: `sudo ufw disable && sudo systemctl stop fail2ban`
4. Fix SSH config manually
5. Re-enable services

---

## Backup Locations

All backups are stored in: `/var/backups/hardening/YYYYMMDD_HHMMSS/`

| File | Backup Path |
|:-----|:-----------|
| `/etc/ssh/sshd_config` | `/etc/ssh/sshd_config.bak` |
| `/etc/fail2ban/jail.conf` | `/var/backups/hardening/jail.conf.bak` |
| `/etc/sysctl.conf` | `/var/backups/hardening/sysctl.conf.bak` |
| `/etc/login.defs` | `/var/backups/hardening/login.defs.bak` |
| `/etc/pam.d/sshd` | `/etc/pam.d/sshd.bak.2fa` |
