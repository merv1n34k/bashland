#!/bin/bash
set -u

SESSION_ID=$(uuidgen | cut -c1-8)
LOG=/srv/bashland/logs/sessions.log

printf '%s spawn %s\n' "$(date -u +%FT%TZ)" "$SESSION_ID" >>"$LOG"
trap 'printf "%s end   %s\n" "$(date -u +%FT%TZ)" "$SESSION_ID" >>"$LOG"' EXIT

exec docker run --rm -i -t \
  --name "bl-$SESSION_ID" \
  --hostname bashland \
  --read-only \
  --tmpfs /tmp:rw,size=16m,nosuid,nodev,mode=1777 \
  --tmpfs /run:rw,size=4m,nosuid,nodev \
  --tmpfs /var/tmp:rw,size=8m,nosuid,nodev,mode=1777 \
  --tmpfs /home/student:rw,size=64m,nosuid,nodev,uid=1000,gid=1000,mode=0755 \
  --memory=256m \
  --memory-swap=256m \
  --memory-swappiness=0 \
  --cpus=0.5 \
  --pids-limit=64 \
  --ulimit nproc=64:64 \
  --ulimit nofile=256:256 \
  --ulimit fsize=20971520 \
  --security-opt no-new-privileges \
  --cap-drop=ALL \
  --network=bashland-egress \
  --dns=1.1.1.1 --dns=9.9.9.9 \
  --stop-signal=SIGHUP \
  --stop-timeout=2 \
  -v /srv/bashland/course:/opt/course:ro \
  -v /srv/bashland/banner.txt:/etc/banner.txt:ro \
  -e SESSION_ID="$SESSION_ID" \
  -e TERM=xterm-256color \
  bashland-course:latest
