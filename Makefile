.PHONY: format
format: format-yaml

.PHONY: format-yaml
format-yaml:
	@ echo "==> Formatting YAML files..."
	@ yamlfmt -conf .yamlfmt.yaml
	@ echo "==> Done formatting YAML files"

.PHONY: formay-markdown
format-markdown:
	@ echo "==> Formatting Markdown files..."
	@ markdownfmt --config .markdownlint.yaml "**/*.md"
	@ echo "==> Done formatting Markdown files"
