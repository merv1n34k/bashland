SERVER ?= root@bashland.org
DOMAIN ?= bashland.org
EMAIL  ?= admin@bashland.org
IMAGE  := bashland-course:latest

.PHONY: setup dev build test test-all lint fmt clean deploy install-course logs

setup:
	@command -v shellcheck >/dev/null || { echo "missing: shellcheck"; exit 1; }
	@command -v hadolint   >/dev/null || { echo "missing: hadolint";   exit 1; }
	@command -v shfmt      >/dev/null || { echo "missing: shfmt";      exit 1; }
	@command -v docker     >/dev/null || { echo "missing: docker";     exit 1; }

dev: build
	docker run --rm -it \
	  --tmpfs /home/student:rw,size=64m,uid=1000,gid=1000,mode=0755 \
	  --tmpfs /tmp:rw,size=16m,mode=1777 \
	  -v $(PWD)/course:/opt/course:ro \
	  -v $(PWD)/banner.txt:/etc/banner.txt:ro \
	  -e SESSION_ID=dev \
	  $(IMAGE)

test-integration: build
	./scripts/test-local.sh

dev-server: build
	@echo "==> open http://localhost:7681  (Ctrl-C to stop)"
	ttyd --port 7681 --interface 0.0.0.0 --writable --max-clients 50 \
	  --terminal-type xterm-256color \
	  -t titleFixed=BashLand \
	  ./scripts/spawn-session-dev.sh

build:
	docker build -t $(IMAGE) docker/

test:
	shellcheck bootstrap.sh scripts/*.sh docker/entrypoint.sh

test-all: test lint

lint:
	shellcheck bootstrap.sh scripts/*.sh docker/entrypoint.sh
	hadolint docker/Dockerfile

fmt:
	shfmt -w -i 2 -ci bootstrap.sh scripts/*.sh docker/entrypoint.sh

clean:
	docker rmi $(IMAGE) 2>/dev/null || true

deploy:
	rsync -avz --delete --exclude='.git' --exclude='node_modules' ./ $(SERVER):/opt/bashland/
	ssh $(SERVER) 'cd /opt/bashland && ./bootstrap.sh $(DOMAIN) $(EMAIL)'

install-course:
	rsync -av --delete course/ $(SERVER):/srv/bashland/course/

logs:
	ssh $(SERVER) 'tail -F /srv/bashland/logs/sessions.log /var/log/nginx/bashland.access.log'
