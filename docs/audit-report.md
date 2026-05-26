# Audit Report — Sample Output

> Example output from running `sudo ./audit.sh --run` on a fully hardened server.

```
======================================================
  WEEKLY SECURITY AUDIT — hardened-server
  Date: Mon May 10 06:00:01 UTC 2026
======================================================

[ HARDENING TESTS ]
  Results: 25/25 tests passed (100%)
  Grade: A+
  Score: 25/25

[ AIDE FILE INTEGRITY ]
  AIDE found no changes.
  Changes detected: 0

[ ROOTKIT SCAN ]
  rkhunter warnings: 0
  chkrootkit infected: 0

[ FAIL2BAN STATS ]
  Total banned:    47
  Currently banned: 2

[ OPEN PORTS ]
  tcp LISTEN 0.0.0.0:2222    sshd
  tcp LISTEN 0.0.0.0:80      nginx
  tcp LISTEN 0.0.0.0:443     nginx

[ LAST 5 LOGINS ]
  pentester pts/0  Mon May 10 05:44  (192.168.1.50)
  pentester pts/0  Sun May  9 18:22  (192.168.1.50)

[ FAILED LOGIN ATTEMPTS (last 24h) ]
  3 failed attempts today

======================================================
  TOTAL ISSUES: 0
  Status: CLEAN ✅
======================================================
```
