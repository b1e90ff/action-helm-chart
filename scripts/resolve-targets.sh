#!/usr/bin/env bash
set -euo pipefail

: "${GITHUB_OUTPUT:?GITHUB_OUTPUT is required}"

INPUT_CHARTS_OCI_URL="${INPUT_CHARTS_OCI_URL:-}"

host_of() {
  local rest="${1#oci://}"
  printf '%s\n' "${rest%%/*}"
}

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

declare -A target_seen=()
unique=()
for target in "${targets[@]}"; do
  [[ -n "${target_seen[${target}]:-}" ]] && continue
  target_seen["${target}"]=1
  unique+=("${target}")
done

hosts=()
for target in "${unique[@]}"; do
  hosts+=("$(host_of "${target}")")
done

# helm dependency update pulls from the repository the Chart.yaml names, which need not be
# one of the publish targets.
if [ -n "${CHART_PATH:-}" ] && [ -f "${CHART_PATH}/Chart.yaml" ]; then
  while IFS= read -r dep; do
    [ -z "${dep}" ] && continue
    hosts+=("$(host_of "${dep}")")
  done < <(tr -d '\r' < "${CHART_PATH}/Chart.yaml" | grep -E '^[[:space:]]*repository:' \
    | grep -oE 'oci://[^"'"'"' ]+' || true)
fi

declare -A host_seen=()
unique_hosts=()
needs_gcp=false
for host in "${hosts[@]}"; do
  [[ -n "${host_seen[${host}]:-}" ]] && continue
  host_seen["${host}"]=1
  unique_hosts+=("${host}")
  [[ "${host}" == *.pkg.dev ]] && needs_gcp=true
done

echo "::group::Registries"
echo "Publish targets: ${unique[*]}"
echo "Hosts to authenticate: ${unique_hosts[*]}"
echo "::endgroup::"

{
  echo "urls=${unique[*]}"
  echo "hosts=${unique_hosts[*]}"
  echo "needs_gcp=${needs_gcp}"
} >> "${GITHUB_OUTPUT}"
