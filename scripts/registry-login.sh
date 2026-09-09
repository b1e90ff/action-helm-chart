#!/usr/bin/env bash
set -euo pipefail

: "${REGISTRY_HOSTS:?REGISTRY_HOSTS is required}"

echo "::group::Registry Login"

for host in ${REGISTRY_HOSTS}; do
  if [[ "${host}" == *.pkg.dev ]]; then
    if ! gcloud auth print-access-token &>/dev/null; then
      echo "::error::${host} needs an authenticated gcloud: pass gcp-credentials-json, or authenticate before this action"
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
