#!/bin/bash
# Run on the server after network-setup.sh. Spins up a throwaway container on
# bashland-egress and asserts the allow/deny matrix. Exits non-zero on regression.
#
# We override the image entrypoint with /bin/sh so the test command actually
# runs (the default entrypoint exec's interactive bash and ignores args).
set -uo pipefail

IMG=bashland-course:latest
RUN=(docker run --rm
  --network=bashland-egress
  --cap-drop=ALL
  --security-opt no-new-privileges
  --entrypoint /bin/sh
  "$IMG" -c)

PASS=0
FAIL=0

check() {
  local name="$1" expect="$2" cmd="$3"
  if "${RUN[@]}" "$cmd" >/dev/null 2>&1; then result=allow; else result=deny; fi
  if [ "$result" = "$expect" ]; then
    printf "  ok    %-25s (%s)\n" "$name" "$expect"
    PASS=$((PASS + 1))
  else
    printf "  FAIL  %-25s want=%s got=%s\n" "$name" "$expect" "$result"
    FAIL=$((FAIL + 1))
  fi
}

echo "==> egress checks"
check "dns lookup"        allow 'getent hosts github.com'
check "https github"      allow 'curl -fsS -m5 https://github.com -o /dev/null'
check "https cloudflare"  allow 'curl -fsS -m5 https://1.1.1.1 -o /dev/null'
check "ssh to github"     deny  'timeout 3 bash -c "</dev/tcp/github.com/22"'
check "rfc1918 10/8"      deny  'timeout 3 bash -c "</dev/tcp/10.0.0.1/22"'
check "rfc1918 192.168"   deny  'timeout 3 bash -c "</dev/tcp/192.168.0.1/22"'
check "cloud metadata"    deny  'curl -m2 -fsS http://169.254.169.254/ -o /dev/null'

echo "==> result: $PASS pass / $FAIL fail"
[ "$FAIL" -eq 0 ]
