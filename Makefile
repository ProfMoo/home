# Binaries needed for local development:
# talosctl
# kubectl
# flux
# terraform
# docker
# yamlfmt
# markdownlint-cli2

.PHONY: lint
lint: lint-yaml lint-markdown

.PHONY: lint-yaml
lint-yaml:
	@ echo "==> Linting YAML files..."
	@ yamlfmt -conf .yamlfmt.yaml -lint
	@ echo "==> Done linting YAML files"

.PHONY: lint-markdown
lint-markdown:
	@ echo "==> Linting Markdown files..."
	@ markdownlint-cli2 --config .markdownlint-cli2.yaml
	@ echo "==> Done linting Markdown files"

.PHONY: format
format: format-yaml format-markdown

.PHONY: format-yaml
format-yaml:
	@ echo "==> Formatting YAML files..."
	@ yamlfmt -conf .yamlfmt.yaml
	@ echo "==> Done formatting YAML files"

.PHONY: format-markdown
format-markdown:
	@ echo "==> Formatting Markdown files..."
	@ markdownlint-cli2 --config .markdownlint-cli2.yaml "**/*.md" --fix
	@ echo "==> Done formatting Markdown files"
