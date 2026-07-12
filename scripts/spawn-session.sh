#!/bin/bash
# Called by ttyd-bashland@.service for each WebSocket connection.
# $1 = mode ("course" or "hard"); selects the matching /srv/bashland/$mode bind
# AND the per-mode resource caps below. Hard mode gets more headroom because
# the report-style analysis tasks chew more memory/CPU than the guided intro.
set -u

MODE=${1:?usage: spawn-session.sh MODE}
SESSION_ID=$(uuidgen | tr -d - | cut -c1-16)
LOG=/srv/bashland/logs/sessions.log
MAX_CONCURRENT=400

case "$MODE" in
  course)
    MEMORY=192m
    TMPFS_HOME=96m
    CPUS=0.25
    PIDS_LIMIT=20
    ULIMIT_NPROC=20
    ULIMIT_NOFILE=256
    ULIMIT_FSIZE=20971520    # 20 MB
    ULIMIT_CPU=3600          # 60 min
    ;;
  hard)
    MEMORY=256m
    TMPFS_HOME=128m
    CPUS=0.4
    PIDS_LIMIT=32
    ULIMIT_NPROC=32
    ULIMIT_NOFILE=512
    ULIMIT_FSIZE=33554432    # 32 MB
    ULIMIT_CPU=5400          # 90 min
    ;;
  *)
    echo "unknown mode: $MODE" >&2
    exit 1
    ;;
esac

# Global capacity check: count live bashland containers (labelled).
running=$(docker ps -q --filter "label=bashland.mode" 2>/dev/null | wc -l)
if [ "$running" -ge "$MAX_CONCURRENT" ]; then
  printf '%s reject %s s=%s reason=capacity (%d/%d)\n' \
    "$(date -u +%FT%TZ)" "$MODE" "$SESSION_ID" "$running" "$MAX_CONCURRENT" >>"$LOG"
  echo
  echo "  BashLand is at capacity (${running}/${MAX_CONCURRENT} active sessions)."
  echo "  Please try again in a few minutes."
  echo
  sleep 8
  exit 0
fi

printf '%s spawn %s %s\n' "$(date -u +%FT%TZ)" "$MODE" "$SESSION_ID" >>"$LOG"
trap 'printf "%s end   %s %s\n" "$(date -u +%FT%TZ)" "$MODE" "$SESSION_ID" >>"$LOG"' EXIT

# Note: --read-only + --security-opt no-new-privileges are NOT set so that
# `sudo apt-get ...` (whitelisted in /etc/sudoers.d/student-apt) actually
# works. Containment still comes from: minimal cap allowlist, network egress
# filter, memory/pid/fsize ulimits, --rm wipe on disconnect.
exec docker run --rm -i -t \
  --name "bl-$MODE-$SESSION_ID" \
  --label "bashland.mode=$MODE" \
  --label "bashland.session=$SESSION_ID" \
  --hostname bashland \
  --tmpfs /tmp:rw,size=32m,nosuid,nodev,mode=1777 \
  --tmpfs /run:rw,size=8m,nosuid,nodev \
  --tmpfs /var/tmp:rw,size=16m,nosuid,nodev,mode=1777 \
  --tmpfs "/home/student:rw,size=${TMPFS_HOME},nosuid,nodev,uid=1000,gid=1000,mode=0755" \
  --memory="$MEMORY" \
  --memory-swap="$MEMORY" \
  --cpus="$CPUS" \
  --pids-limit="$PIDS_LIMIT" \
  --ulimit "nproc=${ULIMIT_NPROC}:${ULIMIT_NPROC}" \
  --ulimit "nofile=${ULIMIT_NOFILE}:${ULIMIT_NOFILE}" \
  --ulimit "fsize=${ULIMIT_FSIZE}" \
  --ulimit "cpu=${ULIMIT_CPU}" \
  --blkio-weight=100 \
  --oom-score-adj=1000 \
  --cap-drop=ALL \
  --cap-add=CHOWN --cap-add=DAC_OVERRIDE --cap-add=FOWNER --cap-add=FSETID \
  --cap-add=SETUID --cap-add=SETGID --cap-add=SETPCAP \
  --network=bashland-egress \
  --dns=1.1.1.1 --dns=9.9.9.9 \
  --stop-signal=SIGHUP \
  --stop-timeout=2 \
  -v "/srv/bashland/$MODE":/opt/course:ro \
  -e SESSION_ID="$SESSION_ID" \
  -e MODE="$MODE" \
  -e TERM=xterm-256color \
  bashland-course:latest
