SHELL := /bin/bash

LOCAL_UID ?= $(shell id -u)
LOCAL_GID ?= $(shell id -g)
HOST_PROJECT_ROOT ?= $(CURDIR)
DC = LOCAL_UID=$(LOCAL_UID) LOCAL_GID=$(LOCAL_GID) HOST_PROJECT_ROOT="$(HOST_PROJECT_ROOT)" docker compose

.PHONY: help image build watch lualatex watch-lualatex shell

help:
	@echo "Targets:"
	@echo "  make image                              Build Docker image"
	@echo "  make build FILE=figures/...tex          Build dark + light SVGs (pdflatex)"
	@echo "  make watch FILE=figures/...tex          Watch and rebuild dark + light SVGs"
	@echo "  make lualatex FILE=figures/...tex       Build dark + light SVGs with lualatex"
	@echo "  make watch-lualatex FILE=figures/...tex Watch dark + light SVGs with lualatex"
	@echo "  make shell                              Open a shell in container"

image:
	docker compose build tikz

build:
	@if [ -z "$(FILE)" ]; then \
		echo "Usage: make build FILE=figures/...tex"; \
		exit 1; \
	fi
	@$(DC) run --rm tikz ./.build.sh "$(FILE)"

watch:
	@if [ -z "$(FILE)" ]; then \
		echo "Usage: make watch FILE=figures/...tex"; \
		exit 1; \
	fi
	@$(DC) run --rm tikz ./.build.sh --watch "$(FILE)"; e=$$?; [ $$e -eq 130 ] || exit $$e

lualatex:
	@if [ -z "$(FILE)" ]; then \
		echo "Usage: make lualatex FILE=figures/...tex"; \
		exit 1; \
	fi
	@$(DC) run --rm tikz ./.build.sh --lualatex "$(FILE)"

watch-lualatex:
	@if [ -z "$(FILE)" ]; then \
		echo "Usage: make watch-lualatex FILE=figures/...tex"; \
		exit 1; \
	fi
	@$(DC) run --rm tikz ./.build.sh --lualatex --watch "$(FILE)"; e=$$?; [ $$e -eq 130 ] || exit $$e

shell:
	@$(DC) run --rm tikz bash
