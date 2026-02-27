#!/bin/bash
echo "🧪 HARDENING VERIFICATION SUITE v2.0"

tests=0; passed=0

run_test() {
    ((tests++))
    if "$@"; then ((passed++)); echo "✅ $1"; else echo "❌ $1"; fi
}

run_test "SSH hardened (port 2222)"        'grep -q "^Port 2222" /etc/ssh/sshd_config'
run_test "SSH keys only"                   'grep -q "^PasswordAuthentication no" /etc/ssh/sshd_config'
run_test "UFW active"                      'ufw status | grep -q "Status: active"'
run_test "Fail2Ban running"                'systemctl is-active --quiet fail2ban'
run_test "AppArmor enforcing SSH"          'aa-status | grep -q "enforce"'
run_test "Kernel ptr restrict"             'sysctl kernel.kptr_restrict | grep -q "2"'
run_test "Root login disabled"             'grep -q "^PermitRootLogin no" /etc/ssh/sshd_config'
run_test "Auto-updates configured"         'dpkg -l | grep -q unattended-upgrades'

echo "📊 RESULTS: $passed/$tests tests PASSED ($(bc -l <<< "scale=1; $passed/$tests*100")%)"
[ "$passed" = "$tests" ] && echo "🎉 SERVER FULLY HARDENED!" || echo "⚠️  Some tests failed"
