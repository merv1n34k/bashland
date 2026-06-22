#!/bin/bash
set -euo pipefail

DOMAIN="${1:?usage: bootstrap.sh DOMAIN EMAIL}"
EMAIL="${2:?usage: bootstrap.sh DOMAIN EMAIL}"

[[ $EUID -eq 0 ]] || {
  echo "must run as root"
  exit 1
}

REPO=$(cd "$(dirname "$0")" && pwd)
TTYD_VERSION=1.7.7

echo "==> apt packages"
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y --no-install-recommends \
  ca-certificates curl gnupg lsb-release rsync uuid-runtime \
  nginx certbot \
  iptables iptables-persistent

echo "==> docker"
if ! command -v docker >/dev/null; then
  install -m 0755 -d /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
  chmod a+r /etc/apt/keyrings/docker.gpg
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" \
    >/etc/apt/sources.list.d/docker.list
  apt-get update
  apt-get install -y docker-ce docker-ce-cli containerd.io
  systemctl enable --now docker
fi

echo "==> ttyd"
if ! command -v ttyd >/dev/null; then
  case "$(uname -m)" in
    x86_64) TTYD_ARCH=x86_64 ;;
    aarch64) TTYD_ARCH=aarch64 ;;
    *)
      echo "unsupported arch: $(uname -m)"
      exit 1
      ;;
  esac
  curl -fsSL -o /usr/local/bin/ttyd \
    "https://github.com/tsl0922/ttyd/releases/download/${TTYD_VERSION}/ttyd.${TTYD_ARCH}"
  chmod +x /usr/local/bin/ttyd
fi

echo "==> ttyd service user"
if ! id ttyd >/dev/null 2>&1; then
  useradd -r -s /usr/sbin/nologin -G docker ttyd
fi

echo "==> directories"
install -d -m 0755 /srv/bashland /srv/bashland/course
install -d -m 0755 -o ttyd -g ttyd /srv/bashland/logs
if [ -z "$(ls -A /srv/bashland/course 2>/dev/null)" ]; then
  rsync -a "$REPO/course/" /srv/bashland/course/
fi
cp "$REPO/banner.txt" /srv/bashland/banner.txt

echo "==> docker image"
docker build -t bashland-course:latest "$REPO/docker/"

echo "==> docker network + egress filter"
"$REPO/scripts/network-setup.sh"
mkdir -p /etc/iptables
iptables-save >/etc/iptables/rules.v4

echo "==> systemd unit"
install -m 0644 "$REPO/systemd/ttyd-bashland.service" /etc/systemd/system/
systemctl daemon-reload

echo "==> nginx stage 1 (HTTP only, for ACME)"
mkdir -p /var/www/html
cat >/etc/nginx/sites-available/bashland-acme <<EOF
server {
    listen 80;
    listen [::]:80;
    server_name $DOMAIN www.$DOMAIN;
    location /.well-known/acme-challenge/ { root /var/www/html; }
    location / { return 200 "bashland setup in progress\n"; add_header Content-Type text/plain; }
}
EOF
ln -sfn /etc/nginx/sites-available/bashland-acme /etc/nginx/sites-enabled/bashland
rm -f /etc/nginx/sites-enabled/default
nginx -t
systemctl reload nginx

echo "==> TLS via certbot"
certbot certonly --webroot -w /var/www/html --non-interactive --agree-tos \
  -d "$DOMAIN" -d "www.$DOMAIN" -m "$EMAIL"

echo "==> nginx stage 2 (HTTPS + WS upgrade)"
sed "s/__DOMAIN__/$DOMAIN/g" "$REPO/nginx/bashland.conf" >/etc/nginx/sites-available/bashland
ln -sfn /etc/nginx/sites-available/bashland /etc/nginx/sites-enabled/bashland
rm -f /etc/nginx/sites-enabled/bashland-acme || true
nginx -t
systemctl reload nginx

echo "==> verify egress filter"
"$REPO/scripts/verify-egress.sh"

echo "==> start ttyd"
systemctl enable --now ttyd-bashland
sleep 1
systemctl status --no-pager ttyd-bashland | head -10

echo
echo "bashland live at https://$DOMAIN"
echo "session log: /srv/bashland/logs/sessions.log"
echo "nginx log:   /var/log/nginx/bashland.access.log"
