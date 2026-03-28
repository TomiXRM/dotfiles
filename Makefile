.PHONY: validate validate-templates validate-shell validate-json validate-python validate-toml validate-stage

CHEZMOI ?= chezmoi
PYTHON ?= python3
VALIDATE_SOURCE_PREFIX ?= /tmp/chezmoi-validate-source
VALIDATE_DEST_PREFIX ?= /tmp/chezmoi-validate-home

validate: validate-templates validate-shell validate-json validate-python validate-toml validate-stage

validate-templates:
	@set -eu; \
	files="$$(rg --files -g '*.tmpl' || true)"; \
	for file in $$files; do \
		case "$$file" in \
			*.sh.tmpl|*.bash.tmpl) \
				echo "bash -n $$file"; \
				$(CHEZMOI) execute-template --file "$$file" | bash -n; \
				;; \
			dot_z*.tmpl|*.zsh.tmpl) \
				echo "zsh -n $$file"; \
				$(CHEZMOI) execute-template --file "$$file" | zsh -n; \
				;; \
			*) \
				echo "render $$file"; \
				$(CHEZMOI) execute-template --file "$$file" >/dev/null; \
				;; \
		esac; \
	done

validate-shell:
	@set -eu; \
	files="$$(rg --files -g '*.sh' -g '*.bash' -g 'dot_zprofile' -g 'dot_xinputrc' || true)"; \
	for file in $$files; do \
		case "$$file" in \
			dot_zprofile|dot_zshenv|dot_zlogin|dot_zlogout|dot_zshrc) \
				echo "zsh -n $$file"; \
				zsh -n "$$file"; \
				;; \
			*) \
				echo "bash -n $$file"; \
				bash -n "$$file"; \
				;; \
		esac; \
	done

validate-json:
	@set -eu; \
	files="$$(rg --files -g '*.json' || true)"; \
	for file in $$files; do \
		echo "jq empty $$file"; \
		jq empty "$$file" >/dev/null; \
	done

validate-python:
	@set -eu; \
	files="$$(rg --files -g '*.py' || true)"; \
	for file in $$files; do \
		echo "$(PYTHON) -m py_compile $$file"; \
		$(PYTHON) -m py_compile "$$file"; \
	done

validate-toml:
	@set -eu; \
	files="$$(rg --files -g '*.toml' || true)"; \
	for file in $$files; do \
		echo "$(PYTHON) tomllib $$file"; \
		$(PYTHON) -c 'import sys, tomllib; tomllib.load(open(sys.argv[1], "rb"))' "$$file"; \
	done

validate-stage:
	@set -eu; \
	source="$$(mktemp -d "$(VALIDATE_SOURCE_PREFIX).XXXXXX")"; \
	dest="$$(mktemp -d "$(VALIDATE_DEST_PREFIX).XXXXXX")"; \
	trap 'rm -rf "$$source" "$$dest"' EXIT HUP INT TERM; \
	tar --exclude=.git --exclude=.chezmoiexternal.toml -cf - . | tar -xf - -C "$$source"; \
	echo "chezmoi apply --source $$source --destination $$dest --exclude=scripts"; \
	$(CHEZMOI) apply --source "$$source" --destination "$$dest" --exclude=scripts; \
	echo "chezmoi verify --source $$source --destination $$dest --exclude=scripts"; \
	$(CHEZMOI) verify --source "$$source" --destination "$$dest" --exclude=scripts
