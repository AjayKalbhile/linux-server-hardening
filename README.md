# 🛡️ Linux Server Hardening Toolkit v3.0

<div align="center">

<br>

![Bash](https://img.shields.io/badge/Bash-5.0%2B-4EAA25?style=for-the-badge&logo=gnubash&logoColor=white)
![Ubuntu](https://img.shields.io/badge/Ubuntu-22.04%20LTS-E95420?style=for-the-badge&logo=ubuntu&logoColor=white)
![Lynis](https://img.shields.io/badge/Lynis%20Score-98%25-brightgreen?style=for-the-badge)
![License](https://img.shields.io/badge/License-MIT-blue?style=for-the-badge)
![CIS](https://img.shields.io/badge/CIS%20Benchmark-Compliant-orange?style=for-the-badge)
![Status](https://img.shields.io/badge/Status-Production%20Ready-brightgreen?style=for-the-badge)

<br>

**Production-grade Ubuntu 22.04 LTS server hardening — automated, modular, and CIS-benchmark aligned.**

*From a fresh server to hardened, monitored, and compliant in under 5 minutes.*

<br>

[What's New](#-whats-new-in-v30) · [Features](#-features) · [Quick Start](#-quick-start) · [Modules](#-hardening-modules) · [Scoring](#-security-scoring) · [Reports](#-reports)

<br>

</div>

---

## 🆕 What's New in v3.0

| v2.0 (Previous) | v3.0 (Current) |
|:----------------|:---------------|
| Single monolithic script | Modular — run any module independently |
| SSH + UFW + Fail2Ban + AppArmor + Kernel | + AIDE IDS, rootkit scanner, 2FA, CIS benchmark |
| Basic 8-test suite | 25-test suite with A+/A/B/C grading |
| No rollback | Full rollback/restore for every module |
| No reporting | HTML + JSON reports with score breakdown |
| Manual config only | Interactive setup wizard |
| No scheduling | Cron-based weekly re-audit + email alerts |

---

## ✨ Features

| Module | What It Does | Standard |
|:-------|:------------|:---------|
| 🔐 **SSH Hardening** | Port 2222, keys only, rate limiting, banner | CIS 5.2 |
| 🛡️ **UFW Firewall** | Default deny, allowlist only, logging | CIS 3.5 |
| 🚫 **Fail2Ban** | Brute-force protection, auto IP ban | CIS 5.3 |
| 📦 **AppArmor** | Mandatory access control, SSH confinement | CIS 1.7 |
| 🧬 **Kernel Hardening** | Sysctl tuning, ASLR, pointer restriction | CIS 3.1 |
| 🔄 **Auto Updates** | Unattended security patch install | CIS 1.9 |
| 🔍 **AIDE IDS** *(NEW)* | File integrity monitoring — detects tampering | CIS 1.4 |
| 🦠 **Rootkit Scanner** *(NEW)* | rkhunter + chkrootkit daily scans | CIS 1.3 |
| 🔑 **2FA / MFA** *(NEW)* | Google Authenticator TOTP for SSH login | NIST 800-53 |
| 📋 **CIS Benchmark** *(NEW)* | 50-point compliance check | CIS Level 1 |
| 📊 **HTML Reports** *(NEW)* | Auto-generated security report with scoring | Custom |
| ⏪ **Rollback** *(NEW)* | Safely undo any hardening change | Custom |
| 🔔 **Email Alerts** *(NEW)* | Weekly audit + alert on score drop | Custom |

---

## 🏗️ Project Structure

```
linux-server-hardening/
├── harden-server.sh              # Main script — runs all modules
├── rollback.sh                   # NEW: Safely undo hardening
├── audit.sh                      # NEW: Weekly re-audit + alerts
├── status.sh                     # Live security dashboard
│
├── scripts/
│   ├── 01_system_update.sh       # System updates & prereqs
│   ├── 02_user_hardening.sh      # Secure admin user setup
│   ├── 03_ssh_hardening.sh       # SSH configuration
│   ├── 04_firewall.sh            # UFW + Fail2Ban
│   ├── 05_apparmor.sh            # AppArmor MAC
│   ├── 06_kernel_hardening.sh    # Sysctl hardening
│   ├── 07_auto_updates.sh        # Unattended upgrades
│   ├── 08_aide_ids.sh            # NEW: AIDE file integrity
│   ├── 09_rootkit_scanner.sh     # NEW: rkhunter + chkrootkit
│   ├── 10_two_factor_auth.sh     # NEW: Google Authenticator 2FA
│   └── 11_cis_benchmark.sh       # NEW: CIS compliance check
│
├── configs/
│   ├── sshd_config.hardened      # SSH config template
│   ├── fail2ban-jail.local       # Fail2Ban config
│   ├── sysctl-hardening.conf     # Kernel parameters
│   ├── aide.conf                 # AIDE monitoring config
│   └── audit.rules               # Auditd rules
│
├── reports/
│   ├── generate_report.sh        # NEW: HTML report generator
│   ├── Hardening-Report.md       # Sample filled report
│   └── cis-benchmark-results.md  # CIS check output
│
├── docs/
│   ├── audit-report.md
│   ├── client-ssh-config.md
│   ├── cis-benchmark-mapping.md  # NEW: Full CIS control mapping
│   └── rollback-guide.md         # NEW: Rollback documentation
│
├── tests/
│   └── test-hardening.sh         # 25-test verification suite
│
└── .github/workflows/
    └── test.yml                  # CI pipeline
```

---

## 🚀 Quick Start

### Prerequisites
- Ubuntu 22.04 LTS (fresh install recommended)
- Root or sudo access

### Option A — Full Hardening (All Modules)

```bash
git clone https://github.com/AjayKalbhlile/linux-server-hardening.git
cd linux-server-hardening
chmod +x *.sh scripts/*.sh tests/*.sh reports/*.sh
sudo ./harden-server.sh
```

### Option B — Interactive Wizard

```bash
sudo ./harden-server.sh --interactive
```

Wizard prompts: admin username, which modules, SSH port, email for alerts.

### Option C — Run a Single Module

```bash
sudo ./scripts/08_aide_ids.sh          # File integrity only
sudo ./scripts/09_rootkit_scanner.sh   # Rootkit scan only
sudo ./scripts/10_two_factor_auth.sh   # 2FA only
sudo ./scripts/11_cis_benchmark.sh     # CIS check only
```

### Option D — Rollback

```bash
sudo ./rollback.sh --all               # Undo everything
sudo ./rollback.sh --module ssh        # Undo only SSH changes
sudo ./rollback.sh --module firewall   # Undo only firewall
```

---

## 🔧 Hardening Modules (NEW in v3.0)

### Module 8 — AIDE File Integrity Monitoring

AIDE creates a cryptographic database of your filesystem and alerts you when files are tampered with — detecting rootkits, unauthorized changes, and supply chain attacks.

```bash
sudo ./scripts/08_aide_ids.sh

# Manual integrity check
sudo aide --check
```

Monitors: `/etc/`, `/bin/`, `/sbin/`, `/usr/bin/`, `/boot/`, SSH authorized_keys

---

### Module 9 — Rootkit Scanner

Runs `rkhunter` and `chkrootkit` on a daily cron schedule, cross-checking against known rootkit signatures.

```bash
sudo ./scripts/09_rootkit_scanner.sh

# Manual scan
sudo rkhunter --check --sk
sudo chkrootkit
```

---

### Module 10 — Two-Factor Authentication (2FA)

Adds TOTP-based 2FA to SSH. Even with a valid SSH key, users also enter a 6-digit TOTP code from Google Authenticator or Authy.

```bash
sudo ./scripts/10_two_factor_auth.sh

# Per-user setup
google-authenticator   # Scan QR code with your authenticator app
```

---

### Module 11 — CIS Benchmark Compliance

Runs 50 automated checks against the CIS Ubuntu 22.04 Level 1 Benchmark and scores your server.

```bash
sudo ./scripts/11_cis_benchmark.sh
```

Sample output:
```
CIS Ubuntu 22.04 Benchmark — Level 1
══════════════════════════════════════════
[PASS] 1.1.1  Disable mounting of cramfs
[PASS] 1.4.1  AIDE is installed
[PASS] 3.5.1  UFW is installed and active
[PASS] 5.2.4  SSH root login disabled
[FAIL] 1.6.1  Core dumps are restricted
...
Score: 47/50 (94%) — PASS
```

---

## 📊 Security Scoring

| Framework | Max | Typical Result |
|:---------|:----|:--------------|
| Lynis Hardening Index | 100 | **98** |
| CIS Ubuntu Benchmark | 50 controls | **47–50** |
| Internal Test Suite | 25 tests | **25/25** |
| Overall Grade | A+ | **A+** |

Grade scale: **A+ (95–100%)** · **A (85–94%)** · **B (70–84%)** · **C (<70%)**

---

## 📋 Reports

```bash
# Generate HTML report
sudo ./reports/generate_report.sh
# → /var/log/hardening/report_YYYYMMDD.html

# Generate JSON report (for SIEM)
sudo ./reports/generate_report.sh --format json
```

Report includes: score breakdown, CIS results, AIDE status, Fail2Ban bans, remediation steps.

---

## 🔔 Automated Weekly Audit

```bash
sudo ./audit.sh --setup-cron --email your@email.com
```

Weekly cron: re-runs test suite, rkhunter scan, AIDE check, emails results if score drops.

---

## 🧪 Verification Suite — 25 Tests

```bash
sudo ./tests/test-hardening.sh
```

```
🧪 HARDENING VERIFICATION SUITE v3.0
══════════════════════════════════════════
[SSH]
  ✅ SSH on port 2222            ✅ Root login disabled
  ✅ Password auth disabled      ✅ PubkeyAuthentication enabled
  ✅ LoginGraceTime 30s          ✅ MaxAuthTries 3
  ✅ X11Forwarding disabled      ✅ SSH banner configured

[FIREWALL]
  ✅ UFW active                  ✅ Default deny incoming
  ✅ Only approved ports open    ✅ Logging enabled

[SERVICES]
  ✅ Fail2Ban running            ✅ AppArmor enforcing
  ✅ auditd running              ✅ rkhunter installed
  ✅ AIDE initialized

[KERNEL]
  ✅ ASLR enabled                ✅ Kernel pointer restriction
  ✅ SYN cookie protection       ✅ ICMP redirects disabled
  ✅ Source routing disabled

[USERS & ACCOUNTS]
  ✅ Root password locked        ✅ No empty passwords
  ✅ Auto-updates configured

══════════════════════════════════════════
📊 RESULTS: 25/25 PASSED (100%)
🎉 GRADE: A+ — Server fully hardened!
```

---

## ⚠️ Disclaimer

> Test in a non-production environment first. Always backup before running. Authors accept no liability for misconfiguration or downtime.

---

## 📄 License

MIT License — see [LICENSE](LICENSE) for full details.

---

<div align="center">

Built for the blue team ❤️ · ⭐ Star this repo if it helped!

</div>
