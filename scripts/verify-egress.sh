#!/bin/bash
# Run on the server after network-setup.sh. Spins up a throwaway container on
# bashland-egress and asserts the allow/deny matrix. Exits non-zero on regression.
set -uo pipefail

IMG=bashland-course:latest
RUN="docker run --rm --network=bashland-egress --cap-drop=ALL --security-opt no-new-privileges $IMG"
PASS=0
FAIL=0

check() {
  local name="$1" expect="$2"
  shift 2
  if $RUN "$@" >/dev/null 2>&1; then result=allow; else result=deny; fi
  if [ "$result" = "$expect" ]; then
    printf "  ok    %-25s (%s)\n" "$name" "$expect"
    PASS=$((PASS + 1))
  else
    printf "  FAIL  %-25s want=%s got=%s\n" "$name" "$expect" "$result"
    FAIL=$((FAIL + 1))
  fi
}

echo "==> egress checks"
check "dns lookup"        allow bash -c 'getent hosts github.com'
check "https github"      allow bash -c 'curl -fsS -m5 https://github.com -o /dev/null'
check "https cloudflare"  allow bash -c 'curl -fsS -m5 https://1.1.1.1 -o /dev/null'
check "ssh to github"     deny  bash -c 'curl -m3 -sf https://github.com:22'
check "rfc1918 10/8"      deny  bash -c 'curl -m2 http://10.0.0.1/'
check "rfc1918 192.168"   deny  bash -c 'curl -m2 http://192.168.0.1/'
check "cloud metadata"    deny  bash -c 'curl -m2 http://169.254.169.254/'

echo "==> result: $PASS pass / $FAIL fail"
[ "$FAIL" -eq 0 ]
