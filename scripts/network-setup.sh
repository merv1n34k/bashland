#!/bin/bash
set -euo pipefail

NETWORK=bashland-egress
SUBNET=172.30.0.0/24
BRIDGE=br-bashland

if ! docker network inspect "$NETWORK" >/dev/null 2>&1; then
  docker network create \
    --driver bridge \
    --subnet "$SUBNET" \
    --opt com.docker.network.bridge.name="$BRIDGE" \
    --opt com.docker.network.bridge.enable_icc=false \
    "$NETWORK"
fi

# Docker normally creates DOCKER-USER on first start, but lazily. Ensure it
# exists and is referenced from FORWARD before we add anything to it.
iptables -N DOCKER-USER 2>/dev/null || true
iptables -C FORWARD -j DOCKER-USER 2>/dev/null || iptables -I FORWARD -j DOCKER-USER

# Idempotency: remove any prior rules of ours. Capture into a variable so
# grep-no-match doesn't trip pipefail before we get to add the new rules.
existing=$(iptables -S DOCKER-USER 2>/dev/null | grep -- "-i $BRIDGE" || true)
if [ -n "$existing" ]; then
  echo "$existing" | sed 's/^-A /-D /' | while read -r r; do
    # shellcheck disable=SC2086
    iptables $r 2>/dev/null || true
  done
fi

# -I inserts at top. Apply bottom-up so eval order is top-to-bottom as listed:
#   1. allow return traffic     2. drop lateral / metadata
#   3. allow DNS+HTTP+HTTPS      4. drop everything else
iptables -A DOCKER-USER -i "$BRIDGE" -j DROP
iptables -I DOCKER-USER -i "$BRIDGE" -p tcp --dport 443 -j ACCEPT
iptables -I DOCKER-USER -i "$BRIDGE" -p tcp --dport 80  -j ACCEPT
iptables -I DOCKER-USER -i "$BRIDGE" -p tcp --dport 53  -j ACCEPT
iptables -I DOCKER-USER -i "$BRIDGE" -p udp --dport 53  -j ACCEPT
iptables -I DOCKER-USER -i "$BRIDGE" -d 169.254.0.0/16 -j DROP
iptables -I DOCKER-USER -i "$BRIDGE" -d 192.168.0.0/16 -j DROP
iptables -I DOCKER-USER -i "$BRIDGE" -d 172.16.0.0/12  -j DROP
iptables -I DOCKER-USER -i "$BRIDGE" -d 10.0.0.0/8     -j DROP
iptables -I DOCKER-USER -i "$BRIDGE" -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

echo "bashland-egress network + DOCKER-USER rules installed"
