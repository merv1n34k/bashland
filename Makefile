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

MODE ?= course
ifeq ($(MODE),hard)
  DEV_PORT = 7682
  DEV_BASE = /hard
else ifeq ($(MODE),course)
  DEV_PORT = 7681
  DEV_BASE = /
else
  $(error MODE must be course or hard)
endif

dev: build
	docker run --rm -it \
	  --tmpfs /home/student:rw,size=64m,uid=1000,gid=1000,mode=0755 \
	  --tmpfs /tmp:rw,size=16m,mode=1777 \
	  -v $(PWD)/$(MODE):/opt/course:ro \
	  -e SESSION_ID=dev -e MODE=$(MODE) \
	  $(IMAGE)

test-integration: build
	./scripts/test-local.sh

dev-server: build
	@echo "==> open http://localhost:$(DEV_PORT)$(DEV_BASE)  (Ctrl-C to stop)"
	ttyd --port $(DEV_PORT) --interface 0.0.0.0 --base-path $(DEV_BASE) \
	  --writable --max-clients 50 --terminal-type xterm-256color \
	  -t titleFixed=BashLand \
	  ./scripts/spawn-session-dev.sh $(MODE)

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
