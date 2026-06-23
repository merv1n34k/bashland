IMAGE := bashland-course:latest

.PHONY: setup build test test-integration test-all lint fmt clean

setup:
	@command -v shellcheck >/dev/null || { echo "missing: shellcheck"; exit 1; }
	@command -v hadolint   >/dev/null || { echo "missing: hadolint";   exit 1; }
	@command -v shfmt      >/dev/null || { echo "missing: shfmt";      exit 1; }
	@command -v docker     >/dev/null || { echo "missing: docker";     exit 1; }

build:
	docker build -t $(IMAGE) docker/

test:
	shellcheck bootstrap.sh scripts/*.sh docker/entrypoint.sh

test-integration: build
	./scripts/test-local.sh

test-all: test test-integration lint

lint:
	shellcheck bootstrap.sh scripts/*.sh docker/entrypoint.sh
	hadolint docker/Dockerfile

fmt:
	shfmt -w -i 2 -ci bootstrap.sh scripts/*.sh docker/entrypoint.sh

clean:
	docker rmi $(IMAGE) 2>/dev/null || true
