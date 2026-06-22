#!/bin/bash
# Local integration tests. Run on Mac or any machine with Docker.
# Covers: image content, cgroup limits applied, fork bomb caught, file-size cap, memory cap.
# Server-only checks (iptables egress) are in verify-egress.sh.
set -uo pipefail

REPO=$(cd "$(dirname "$0")/.." && pwd)
IMG=bashland-course:latest

# Mirrors spawn-session.sh flags. Update both if you change either.
RUN_PROD=(
  docker run --rm -i
  --tmpfs /home/student:rw,size=64m,uid=1000,gid=1000,mode=0755
  --tmpfs /tmp:rw,size=16m,mode=1777
  --tmpfs /run:rw,size=4m
  --tmpfs /var/tmp:rw,size=8m,mode=1777
  --memory=256m --memory-swap=256m --memory-swappiness=0
  --cpus=0.5 --pids-limit=64
  --ulimit nproc=64:64 --ulimit nofile=256:256 --ulimit fsize=20971520
  --security-opt no-new-privileges --cap-drop=ALL
  -v "$REPO/course":/opt/course:ro
  "$IMG"
)

PASS=0
FAIL=0
check() {
  local name=$1 expected=$2 actual=$3
  if [[ "$actual" == "$expected" ]]; then
    printf "  ok    %-32s %s\n" "$name" "$expected"
    PASS=$((PASS + 1))
  else
    printf "  FAIL  %-32s want=%q got=%q\n" "$name" "$expected" "$actual"
    FAIL=$((FAIL + 1))
  fi
}

# ---- 1. Smoke: identity, files, prompt ----
echo "==> smoke"
out=$(printf 'whoami\npwd\nls README.md\n' | "${RUN_PROD[@]}" 2>&1)
check "user is student"   "student"        "$(echo "$out" | grep -m1 -E '^student$')"
check "cwd is home"       "/home/student"  "$(echo "$out" | grep -m1 -E '^/home/student$')"
check "course README seen" "README.md"     "$(echo "$out" | grep -m1 -E '^README\.md$')"

# ---- 2. cgroup limits applied ----
echo "==> limits applied"
out=$(printf 'cat /sys/fs/cgroup/memory.max; cat /sys/fs/cgroup/pids.max\n' | "${RUN_PROD[@]}" 2>&1)
check "memory.max" "268435456" "$(echo "$out" | grep -m1 -E '^[0-9]+$')"
check "pids.max"   "64"        "$(echo "$out" | tail -n1 | tr -d '\r')"

# ---- 3. Fork bomb caught by --pids-limit ----
echo "==> fork bomb"
# Under pids-limit=64, attempting to spawn 200 sleeps exhausts the slots and
# kills the shell. Expect non-zero exit from the container.
docker run --rm \
  --tmpfs /home/student:rw,size=64m,uid=1000,gid=1000,mode=0755 \
  --tmpfs /tmp:rw,size=16m,mode=1777 \
  --pids-limit=64 --ulimit nproc=64:64 \
  --entrypoint /bin/bash \
  "$IMG" -c 'for i in $(seq 1 200); do sleep 30 & done' >/dev/null 2>&1
ec=$?
if [[ "$ec" -ne 0 ]]; then
  printf "  ok    %-32s %s\n" "fork bomb kills container" "exit=$ec"
  PASS=$((PASS + 1))
else
  printf "  FAIL  %-32s %s\n" "fork bomb kills container" "exit=$ec (expected non-zero)"
  FAIL=$((FAIL + 1))
fi

# ---- 4. File-size limit (ulimit fsize=20MB) ----
echo "==> file size cap"
# ulimit fsize sends SIGXFSZ when limit reached. dd reports an error.
script='
  ulimit -f
  dd if=/dev/zero of=/home/student/big bs=1M count=50 2>&1 | tail -n1
  ls -l /home/student/big 2>/dev/null | awk "{print \$5}"
'
out=$(printf '%s\n' "$script" | "${RUN_PROD[@]}" 2>&1)
size=$(echo "$out" | tail -n1 | tr -d '\r')
if [[ -n "$size" && "$size" -le 20971520 ]]; then
  printf "  ok    %-32s %s\n" "fsize cap honored" "got ${size} bytes (<=20MB)"
  PASS=$((PASS + 1))
else
  printf "  FAIL  %-32s got=%s\n" "fsize cap honored" "$size"
  FAIL=$((FAIL + 1))
fi

# ---- 5. Memory cap kills runaway allocator ----
echo "==> memory cap"
# awk grows a string forever — should be OOM-killed before reaching 1GB.
out=$(printf 'awk "BEGIN { x=\\"a\\"; while (1) x=x x }" 2>&1; echo EXIT=$?\n' | \
  timeout 15 "${RUN_PROD[@]}" 2>&1 | tail -n3)
exit_line=$(echo "$out" | grep -oE 'EXIT=[0-9]+' | head -1)
ec=${exit_line#EXIT=}
if [[ -n "$ec" && "$ec" -ne 0 ]]; then
  printf "  ok    %-32s %s\n" "OOM kills runaway alloc" "awk exit=$ec"
  PASS=$((PASS + 1))
else
  printf "  FAIL  %-32s %s\n" "OOM kills runaway alloc" "awk exit=$ec (expected non-zero)"
  FAIL=$((FAIL + 1))
fi

echo
echo "==> result: $PASS pass / $FAIL fail"
[[ $FAIL -eq 0 ]]
