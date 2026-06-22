#!/bin/bash
# Local dev wrapper for ttyd. Mirrors spawn-session.sh but uses repo-local paths
# (no /srv/bashland needed) and skips the session log. Use via `make dev-server`.
set -u

REPO=$(cd "$(dirname "$0")/.." && pwd)
SESSION_ID=$(uuidgen | cut -c1-8)

exec docker run --rm -i -t \
  --name "bl-dev-$SESSION_ID" \
  --hostname bashland \
  --tmpfs /tmp:rw,size=16m,nosuid,nodev,mode=1777 \
  --tmpfs /home/student:rw,size=64m,nosuid,nodev,uid=1000,gid=1000,mode=0755 \
  --memory=256m \
  --memory-swap=256m \
  --cpus=0.5 \
  --pids-limit=64 \
  --ulimit nproc=64:64 \
  --ulimit nofile=256:256 \
  --ulimit fsize=20971520 \
  --security-opt no-new-privileges \
  --cap-drop=ALL \
  -v "$REPO/course":/opt/course:ro \
  -v "$REPO/banner.txt":/etc/banner.txt:ro \
  -e SESSION_ID="$SESSION_ID" \
  -e TERM=xterm-256color \
  bashland-course:latest
