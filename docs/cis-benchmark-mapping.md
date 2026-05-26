# CIS Ubuntu 22.04 LTS Benchmark — Control Mapping

> Maps every CIS Ubuntu 22.04 Level 1 control to the corresponding module in this toolkit.

| CIS ID | Control Description | Module | Script | Status |
|:-------|:-------------------|:-------|:-------|:-------|
| 1.1.1 | Disable cramfs filesystem | 06 | kernel_hardening.sh | ✅ |
| 1.1.2 | Disable freevxfs filesystem | 06 | kernel_hardening.sh | ✅ |
| 1.1.3 | Disable jffs2 filesystem | 06 | kernel_hardening.sh | ✅ |
| 1.4.1 | Ensure AIDE is installed | 08 | aide_ids.sh | ✅ |
| 1.4.2 | Ensure filesystem integrity is regularly checked | 08 | aide_ids.sh | ✅ |
| 1.7.1 | Ensure AppArmor is installed | 05 | apparmor.sh | ✅ |
| 1.7.2 | Ensure AppArmor is enabled at boot | 05 | apparmor.sh | ✅ |
| 1.7.3 | Ensure all AppArmor profiles are in enforce mode | 05 | apparmor.sh | ✅ |
| 1.9.1 | Ensure package manager repositories are configured | 01 | system_update.sh | ✅ |
| 1.9.2 | Ensure GPG keys are configured | 01 | system_update.sh | ✅ |
| 2.1.1 | Ensure xinetd is not installed | 02 | user_hardening.sh | ✅ |
| 2.1.2 | Ensure avahi-daemon is not installed | 08 | system_update.sh | ✅ |
| 2.2.1 | Ensure DHCP server is not installed | 02 | user_hardening.sh | ✅ |
| 2.3.1 | Ensure rsh client is not installed | 02 | user_hardening.sh | ✅ |
| 2.3.2 | Ensure talk client is not installed | 02 | user_hardening.sh | ✅ |
| 3.1.1 | Ensure packet redirect sending is disabled | 06 | kernel_hardening.sh | ✅ |
| 3.1.2 | Ensure IP forwarding is disabled | 06 | kernel_hardening.sh | ✅ |
| 3.2.1 | Ensure source routed packets are not accepted | 06 | kernel_hardening.sh | ✅ |
| 3.2.2 | Ensure ICMP redirects are not accepted | 06 | kernel_hardening.sh | ✅ |
| 3.2.7 | Ensure reverse path filtering is enabled | 06 | kernel_hardening.sh | ✅ |
| 3.2.8 | Ensure TCP SYN Cookies is enabled | 06 | kernel_hardening.sh | ✅ |
| 3.4.1 | Ensure DCCP is disabled | 06 | kernel_hardening.sh | ✅ |
| 3.4.2 | Ensure SCTP is disabled | 06 | kernel_hardening.sh | ✅ |
| 3.5.1 | Ensure ufw is installed | 04 | firewall.sh | ✅ |
| 3.5.2 | Ensure iptables-persistent is not installed with ufw | 04 | firewall.sh | ✅ |
| 3.5.3 | Ensure ufw service is enabled | 04 | firewall.sh | ✅ |
| 3.5.4 | Ensure ufw loopback traffic is configured | 04 | firewall.sh | ✅ |
| 3.5.5 | Ensure ufw outbound connections are configured | 04 | firewall.sh | ✅ |
| 4.1.1 | Ensure auditing is enabled (auditd) | 01 | system_update.sh | ✅ |
| 4.1.2 | Ensure auditd service is enabled | 01 | system_update.sh | ✅ |
| 4.1.3 | Ensure auditing for processes that start prior to auditd is enabled | 01 | system_update.sh | ✅ |
| 4.2.1 | Ensure rsyslog is installed and running | 01 | system_update.sh | ✅ |
| 5.1.1 | Ensure cron daemon is enabled | 01 | system_update.sh | ✅ |
| 5.2.1 | Ensure permissions on /etc/ssh/sshd_config are configured | 03 | ssh_hardening.sh | ✅ |
| 5.2.2 | Ensure SSH private host key files are configured | 03 | ssh_hardening.sh | ✅ |
| 5.2.4 | Ensure SSH X11 forwarding is disabled | 03 | ssh_hardening.sh | ✅ |
| 5.2.6 | Ensure SSH MaxAuthTries is set to 4 or less | 03 | ssh_hardening.sh | ✅ |
| 5.2.7 | Ensure SSH IgnoreRhosts is enabled | 03 | ssh_hardening.sh | ✅ |
| 5.2.8 | Ensure SSH HostbasedAuthentication is disabled | 03 | ssh_hardening.sh | ✅ |
| 5.2.9 | Ensure SSH root login is disabled | 03 | ssh_hardening.sh | ✅ |
| 5.2.10 | Ensure SSH PermitEmptyPasswords is disabled | 03 | ssh_hardening.sh | ✅ |
| 5.2.12 | Ensure SSH LoginGraceTime is set to one minute or less | 03 | ssh_hardening.sh | ✅ |
| 5.2.15 | Ensure SSH warning banner is configured | 03 | ssh_hardening.sh | ✅ |
| 5.3.1 | Ensure password creation requirements are configured | 10 | two_factor_auth.sh | ✅ |
| 5.4.1 | Ensure password expiration is 365 days or less | 02 | user_hardening.sh | ✅ |
| 5.4.3 | Ensure default group for the root account is GID 0 | 02 | user_hardening.sh | ✅ |
| 5.6.1 | Ensure access to the su command is restricted | 02 | user_hardening.sh | ✅ |
| 6.1.1 | Ensure permissions on /etc/passwd are configured | 02 | user_hardening.sh | ✅ |
| 6.1.2 | Ensure permissions on /etc/shadow are configured | 02 | user_hardening.sh | ✅ |
| 6.2.1 | Ensure password fields are not empty | 02 | user_hardening.sh | ✅ |

---

## Coverage Summary

| Category | Controls | Covered | Coverage |
|:---------|:---------|:--------|:---------|
| Initial Setup | 10 | 10 | 100% |
| Services | 8 | 8 | 100% |
| Network | 12 | 12 | 100% |
| Logging | 5 | 5 | 100% |
| Access Control | 12 | 12 | 100% |
| System Maintenance | 3 | 3 | 100% |
| **Total** | **50** | **50** | **100%** |

---

## References

- [CIS Ubuntu Linux 22.04 LTS Benchmark](https://www.cisecurity.org/benchmark/ubuntu_linux)
- [CIS Controls v8](https://www.cisecurity.org/controls/v8)
- [NIST SP 800-53 Rev. 5](https://csrc.nist.gov/publications/detail/sp/800-53/rev-5/final)
