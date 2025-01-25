# Binaries needed for local development:
# talosctl
# kubectl
# flux
# terraform
# docker
# yamlfmt
# markdownlint-cli2
# hadolint
# shfmt

.PHONY: lint
lint: lint-yaml lint-markdown lint-terraform lint-docker lint-shell

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

.PHONY: lint-terraform
lint-terraform:
	@ echo "==> Linting Terraform files..."
	@ terraform fmt -check -recursive -diff
	@ echo "==> Done linting Terraform files"

.PHONY: lint-docker
lint-docker:
	@ echo "==> Linting Dockerfiles..."
	@ find . -type f -name "*Dockerfile*" -not -path "*/\.*" | xargs hadolint --config .hadolint.yaml
	@ echo "==> Done linting Dockerfiles"

.PHONY: lint-shell
lint-shell:
	@ echo "==> Linting shell scripts..."
	@ shfmt --diff .
	@ echo "==> Done linting shell scripts"


.PHONY: format
format: format-yaml format-markdown format-terraform format-shell

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

.PHONY: format-terraform
format-terraform:
	@ echo "==> Formatting Terraform files..."
	@ terraform fmt -recursive
	@ echo "==> Done formatting Terraform files"

.PHONY: format-shell
format-shell:
	@ echo "==> Formatting shell scripts..."
	@ shfmt --write .
	@ echo "==> Done formatting shell scripts"
