#!/usr/bin/env bash
set -euo pipefail

: "${HELM_VERSION:?HELM_VERSION is required}"
: "${OCI_REGISTRY:?OCI_REGISTRY is required}"
: "${REGISTRY_OWNER:?REGISTRY_OWNER is required}"
: "${GITHUB_TOKEN:?GITHUB_TOKEN is required}"

echo "::group::Helm Setup"

installed=$(helm version --short 2>/dev/null | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+' || echo "none")

if [[ "${installed}" != "${HELM_VERSION}" ]]; then
  echo "Installing Helm ${HELM_VERSION} (current: ${installed})..."
  curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 \
    | DESIRED_VERSION="${HELM_VERSION}" bash
else
  echo "Helm ${HELM_VERSION} already present"
fi

echo "::endgroup::"

echo "::group::Registry Login"
echo "${GITHUB_TOKEN}" | helm registry login "${OCI_REGISTRY}" \
  --username "${REGISTRY_OWNER}" \
  --password-stdin
echo "Authenticated with ${OCI_REGISTRY}"
echo "::endgroup::"
