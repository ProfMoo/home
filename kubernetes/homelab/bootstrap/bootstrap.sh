#!/usr/bin/env bash
set -Eeuo pipefail

export ROOT_DIR="$(git rev-parse --show-toplevel)"

# Log messages with structured output
function log() {
	local lvl="${1:?}" msg="${2:?}"
	shift 2
	gum log --time=rfc3339 --structured --level "${lvl}" "[${FUNCNAME[1]}] ${msg}" "$@"
}

# Apply Custom Resource Definitions (CRDs) using Helmfile
function apply_crds() {
	log info "Applying CRDs"

	local -r helmfile_file="${ROOT_DIR}/kubernetes/homelab/bootstrap/crds/helmfile.yaml"

	if [[ ! -f "${helmfile_file}" ]]; then
		log fatal "File does not exist" "file" "${helmfile_file}"
	fi

	if ! crds=$(helmfile --file "${helmfile_file}" template --include-crds --no-hooks --quiet | yq ea --exit-status 'select(.kind == "CustomResourceDefinition")' -) || [[ -z "${crds}" ]]; then
		log fatal "Failed to render CRDs from Helmfile" "file" "${helmfile_file}"
	fi

	if echo "${crds}" | kubectl diff --filename - &>/dev/null; then
		log info "CRDs are up-to-date"
		return
	fi

	if ! echo "${crds}" | kubectl apply --server-side --filename - &>/dev/null; then
		log fatal "Failed to apply crds from Helmfile" "file" "${helmfile_file}"
	fi

	log info "CRDs applied successfully"
}

# Apply applications using Helmfile
function apply_apps() {
	log info "Applying apps"

	local -r helmfile_file="${ROOT_DIR}/kubernetes/homelab/bootstrap/helmfile.yaml"

	if [[ ! -f "${helmfile_file}" ]]; then
		log fatal "File does not exist" "file" "${helmfile_file}"
	fi

	if ! helmfile --file "${helmfile_file}" sync --hide-notes; then
		log fatal "Failed to apply apps from Helmfile" "file" "${helmfile_file}"
	fi

	log info "Apps applied successfully"
}

function main() {
	apply_crds
	apply_apps
}

main "$@"
