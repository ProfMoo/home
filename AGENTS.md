# AGENTS.md

## Repo Shape

Homelab IaC/GitOps mono-repo for `ProfMoo/home`.

- `kubernetes/`: Flux-managed cluster state. Main work usually happens here.
- `kubernetes/homelab/repo/ks.yaml`: root Flux Kustomization. It points Flux at `kubernetes/homelab/apps` and patches child Kustomizations/HelmReleases with SOPS + Helm defaults.
- `kubernetes/homelab/apps/<area>/<app>/`: app deployments. Typical layout is `ks.yaml` plus `app/` containing HelmRelease, Kustomization, dashboards, monitors, rules, secrets, etc.
- `kubernetes/homelab/common/`: reusable Kustomize components, especially VolSync PVC backup plumbing.
- `kubernetes/homelab/bootstrap/`: one-time/manual bootstrap pieces for Flux and base CRDs.
- `infrastructure/`: Terraform + Talos + Proxmox VM/node config. Generated node configs live in `infrastructure/nodes/`.
- `containers/`: local container build context(s), currently small.
- `docs/`: operational notes and investigations.

## Local Commands

Use `task --list` first. Common checks:

- `task l:lint`: all lint checks.
- `task f:format`: format YAML, Markdown, Terraform, shell.
- `task l:lint-yaml` / `task f:format-yaml`: YAML only.
- `task l:lint-markdown` / `task f:format-markdown`: Markdown only.
- `task l:lint-terraform` / `task f:format-terraform`: Terraform only.
- `task t:apply-dry-run`: Talos config dry-run against live nodes.
- `task t:apply`: apply all generated Talos node configs.

Direct tools expected locally: `talosctl`, `kubectl`, `flux`, `terraform`, `docker`, `yamlfmt`, `markdownlint-cli2`, `hadolint`, `shfmt`, `minijinja-cli`, `gum`, `sops`.

## Kubernetes Change Pattern

- Prefer smallest change in existing app directory.
- App entrypoint is usually `kubernetes/homelab/apps/<area>/<app>/ks.yaml`.
- Rendered resources are usually under `.../<app>/app/` with `kustomization.yaml` listing every file.
- If adding resource file, add it to nearest `kustomization.yaml`.
- If adding new app, add its `ks.yaml` to parent area `kustomization.yaml`.
- Use `wait: false` on Flux Kustomizations unless existing pattern needs health checks/dependencies.
- Put `dependsOn` where dependency matters. If only HelmRelease depends on another HelmRelease, prefer HR-level dependsOn; if raw manifests depend on it, use KS-level dependsOn.
- Keep `metadata.name` and `app.kubernetes.io/name` aligned with app where possible.
- Helm apps usually use Flux `HelmRelease` with schema comment and OCI `chartRef`.
- bjw-s `app-template` values are common; match nearby app style before inventing structure.

## Observability Pattern

- Observability apps live in `kubernetes/homelab/apps/observability/`.
- Prometheus Operator CRDs are used: `ServiceMonitor`, `PodMonitor`, `PrometheusRule`, `AlertmanagerConfig`.
- Add app-specific alert rules beside app manifests, e.g. `.../<app>/app/prometheus-rule.yaml`, then list in app `kustomization.yaml`.
- Existing alert style: one `PrometheusRule` per app, schema comment, `severity: critical`, concise `summary` annotation.
- `kube-prometheus-stack` sets selectors so standalone rules/monitors are discovered; no extra release values usually needed.
- iDRAC exporter lives at `kubernetes/homelab/apps/observability/idrac-exporter/`; targets are configured as ServiceMonitor endpoint `params.target` values.

## Secrets

- Never decrypt or print secrets unless user explicitly asks and it is necessary.
- SOPS rules are in `.sops.yaml`.
- Kubernetes deploy-time secrets match `kubernetes/.+\.secrets?.sops.ya?ml` and encrypt only `data`/`stringData`.
- Bootstrap secrets match `*.bootstrap.sops.yaml` and may use both age + KMS.
- Infrastructure secrets match `infrastructure/*.sops.yaml` and use KMS.

## Infrastructure Pattern

- Terraform root is `infrastructure/`; modules live under `infrastructure/modules/`.
- Node inventory and generated Talos machine config are in `infrastructure/nodes/*.yaml`.
- `infrastructure/create_talos_node_configs` creates per-node Talos configs after Terraform/config changes.
- Validate infra edits with `terraform fmt -recursive` or `task l:lint-terraform`; use `terraform plan` from `infrastructure/` only when credentials/state are available.
- Do not hand-edit generated Talos node configs unless task explicitly targets them.

## Formatting And Style

- YAML starts with `---`; `.yamlfmt.yaml` enforces document start and trims whitespace.
- Include the schema in the YAML at the top if it's not a Kubernetes standard component.
- Do not format `*.sops.yaml` or Talos templates in `infrastructure/configs/`; yamlfmt excludes them.
- Markdown lint ignores line length and inline HTML; root README uses HTML badges/layout.
- Shell scripts should pass `shfmt -d .`.
- Terraform should pass `terraform fmt -check -recursive -diff`.

## Operational Caution

- This repo controls real homelab infra. DO NOT make destructive commands unless user asks.
- ALWAYS Prefer GitOps file changes over direct `kubectl` mutation.
- Direct cluster commands are okay for inspection and validation; avoid changing live state without explicit intent.
- Do not revert unrelated dirty worktree changes.
- Do not commit unless user asks.
