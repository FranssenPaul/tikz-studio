SHELL := /bin/bash

LOCAL_UID ?= $(shell id -u)
LOCAL_GID ?= $(shell id -g)
HOST_PROJECT_ROOT ?= $(CURDIR)
THEME ?= dark
DC = LOCAL_UID=$(LOCAL_UID) LOCAL_GID=$(LOCAL_GID) HOST_PROJECT_ROOT="$(HOST_PROJECT_ROOT)" docker compose

.PHONY: help image build watch lualatex watch-lualatex shell

help:
	@echo "Targets:"
	@echo "  make image                              Build Docker image"
	@echo "  make build FILE=figures/...tex [THEME=dark|light]          Build one file (pdflatex)"
	@echo "  make watch FILE=figures/...tex [THEME=dark|light]          Watch and rebuild on save"
	@echo "  make lualatex FILE=figures/...tex [THEME=dark|light]       Build one file with lualatex"
	@echo "  make watch-lualatex FILE=figures/...tex [THEME=dark|light] Watch with lualatex"
	@echo "  make shell                              Open a shell in container"

image:
	docker compose build tikz

build:
	@if [ -z "$(FILE)" ]; then \
		echo "Usage: make build FILE=figures/...tex"; \
		exit 1; \
	fi
	@if [ "$(THEME)" != "dark" ] && [ "$(THEME)" != "light" ]; then \
		echo "Usage: make build FILE=figures/...tex [THEME=dark|light]"; \
		exit 1; \
	fi
	@$(DC) run --rm tikz ./.build.sh --$(THEME) "$(FILE)"

watch:
	@if [ -z "$(FILE)" ]; then \
		echo "Usage: make watch FILE=figures/...tex"; \
		exit 1; \
	fi
	@if [ "$(THEME)" != "dark" ] && [ "$(THEME)" != "light" ]; then \
		echo "Usage: make watch FILE=figures/...tex [THEME=dark|light]"; \
		exit 1; \
	fi
	@$(DC) run --rm tikz ./.build.sh --$(THEME) --watch "$(FILE)"; e=$$?; [ $$e -eq 130 ] || exit $$e

lualatex:
	@if [ -z "$(FILE)" ]; then \
		echo "Usage: make lualatex FILE=figures/...tex"; \
		exit 1; \
	fi
	@if [ "$(THEME)" != "dark" ] && [ "$(THEME)" != "light" ]; then \
		echo "Usage: make lualatex FILE=figures/...tex [THEME=dark|light]"; \
		exit 1; \
	fi
	@$(DC) run --rm tikz ./.build.sh --$(THEME) --lualatex "$(FILE)"

watch-lualatex:
	@if [ -z "$(FILE)" ]; then \
		echo "Usage: make watch-lualatex FILE=figures/...tex"; \
		exit 1; \
	fi
	@if [ "$(THEME)" != "dark" ] && [ "$(THEME)" != "light" ]; then \
		echo "Usage: make watch-lualatex FILE=figures/...tex [THEME=dark|light]"; \
		exit 1; \
	fi
	@$(DC) run --rm tikz ./.build.sh --$(THEME) --lualatex --watch "$(FILE)"; e=$$?; [ $$e -eq 130 ] || exit $$e

shell:
	@$(DC) run --rm tikz bash
