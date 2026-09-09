#!/usr/bin/env bash
set -euo pipefail

: "${GITHUB_OUTPUT:?GITHUB_OUTPUT is required}"

INPUT_CHARTS_OCI_URL="${INPUT_CHARTS_OCI_URL:-}"

targets=()

if [[ -n "${INPUT_CHARTS_OCI_URL//[[:space:]]/}" ]]; then
  while IFS= read -r line; do
    line="$(printf '%s' "${line}" | tr -d '[:space:]')"
    [[ -z "${line}" ]] && continue
    if [[ "${line}" != oci://*/* ]]; then
      echo "::error::'${line}' is not a repository URL of the form oci://<host>/<path>"
      exit 1
    fi
    targets+=("${line}")
  done <<< "${INPUT_CHARTS_OCI_URL}"
else
  : "${OCI_REGISTRY:?OCI_REGISTRY is required when charts-oci-url is empty}"
  : "${REGISTRY_OWNER:?REGISTRY_OWNER is required when charts-oci-url is empty}"
  : "${CHARTS_REPO_NAME:?CHARTS_REPO_NAME is required when charts-oci-url is empty}"
  targets+=("oci://${OCI_REGISTRY}/${REGISTRY_OWNER}/${CHARTS_REPO_NAME}")
fi

declare -A seen=()
unique=()
for target in "${targets[@]}"; do
  [[ -n "${seen[${target}]:-}" ]] && continue
  seen["${target}"]=1
  unique+=("${target}")
done

echo "::group::Registry Targets"
printf '%s\n' "${unique[@]}"
echo "::endgroup::"

echo "urls=${unique[*]}" >> "${GITHUB_OUTPUT}"
