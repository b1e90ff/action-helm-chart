#!/usr/bin/env bash
set -euo pipefail

: "${CHARTS_OCI_URLS:?CHARTS_OCI_URLS is required}"

host_of() {
  local rest="${1#oci://}"
  printf '%s\n' "${rest%%/*}"
}

hosts=()
for target in ${CHARTS_OCI_URLS}; do
  hosts+=("$(host_of "${target}")")
done

# helm dependency update pulls from the repository the Chart.yaml names, which need not be
# one of the publish targets.
if [ -n "${CHART_PATH:-}" ] && [ -f "${CHART_PATH}/Chart.yaml" ]; then
  while IFS= read -r dep; do
    [ -z "${dep}" ] && continue
    hosts+=("$(host_of "${dep}")")
  done < <(grep -E '^[[:space:]]*repository:' "${CHART_PATH}/Chart.yaml" \
    | grep -oE 'oci://[^"'"'"' ]+' || true)
fi

echo "::group::Registry Login"

declare -A seen=()
for host in "${hosts[@]}"; do
  [[ -n "${seen[${host}]:-}" ]] && continue
  seen["${host}"]=1

  if [[ "${host}" == *.pkg.dev ]]; then
    if ! command -v gcloud &>/dev/null; then
      echo "::error::${host} needs gcloud; add google-github-actions/auth and setup-gcloud before this action"
      exit 1
    fi
    # Helm reads the Docker credential helper, so nothing is stored that could expire mid-run.
    gcloud auth configure-docker "${host}" --quiet
    echo "Credential helper configured for ${host}"
  else
    : "${GITHUB_TOKEN:?GITHUB_TOKEN is required to log in to ${host}}"
    : "${REGISTRY_USERNAME:?REGISTRY_USERNAME is required to log in to ${host}}"
    echo "${GITHUB_TOKEN}" | helm registry login "${host}" \
      --username "${REGISTRY_USERNAME}" \
      --password-stdin
    echo "Authenticated with ${host}"
  fi
done

echo "::endgroup::"
