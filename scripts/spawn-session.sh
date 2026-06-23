#!/bin/bash
# Called by ttyd-bashland@.service for each WebSocket connection.
# $1 = mode ("course" or "hard"); selects the matching /srv/bashland/$mode bind.
# Resource caps are identical for both modes — hard mode is harder *content*,
# not a bigger sandbox.
set -u

MODE=${1:?usage: spawn-session.sh MODE}
SESSION_ID=$(uuidgen | tr -d - | cut -c1-16)
LOG=/srv/bashland/logs/sessions.log
MAX_CONCURRENT=150

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

exec docker run --rm -i -t \
  --name "bl-$MODE-$SESSION_ID" \
  --label "bashland.mode=$MODE" \
  --label "bashland.session=$SESSION_ID" \
  --hostname bashland \
  --read-only \
  --tmpfs /tmp:rw,size=16m,nosuid,nodev,mode=1777 \
  --tmpfs /run:rw,size=4m,nosuid,nodev \
  --tmpfs /var/tmp:rw,size=8m,nosuid,nodev,mode=1777 \
  --tmpfs /home/student:rw,size=64m,nosuid,nodev,uid=1000,gid=1000,mode=0755 \
  --memory=128m \
  --memory-swap=128m \
  --cpus=0.25 \
  --pids-limit=16 \
  --ulimit nproc=16:16 \
  --ulimit nofile=32:32 \
  --ulimit fsize=5242880 \
  --ulimit cpu=300 \
  --blkio-weight=100 \
  --oom-score-adj=1000 \
  --security-opt no-new-privileges \
  --cap-drop=ALL \
  --network=bashland-egress \
  --dns=1.1.1.1 --dns=9.9.9.9 \
  --stop-signal=SIGHUP \
  --stop-timeout=2 \
  -v "/srv/bashland/$MODE":/opt/course:ro \
  -e SESSION_ID="$SESSION_ID" \
  -e MODE="$MODE" \
  -e TERM=xterm-256color \
  bashland-course:latest
