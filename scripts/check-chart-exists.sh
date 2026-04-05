#!/usr/bin/env bash
set -euo pipefail

: "${CHART_NAME:?CHART_NAME is required}"
: "${CHART_VERSION:?CHART_VERSION is required}"
: "${OCI_REGISTRY:?OCI_REGISTRY is required}"
: "${REGISTRY_OWNER:?REGISTRY_OWNER is required}"
: "${CHARTS_REPO_NAME:?CHARTS_REPO_NAME is required}"

ref="oci://${OCI_REGISTRY}/${REGISTRY_OWNER}/${CHARTS_REPO_NAME}/${CHART_NAME}"

echo "::group::Registry Check"

if helm show chart "${ref}" --version "${CHART_VERSION}" &>/dev/null; then
  echo "::notice::${CHART_NAME}:${CHART_VERSION} already in registry — skipping"
  echo "skip_processing=true" >> "${GITHUB_OUTPUT}"
else
  echo "${CHART_NAME}:${CHART_VERSION} not found — will publish"
  echo "skip_processing=false" >> "${GITHUB_OUTPUT}"
fi

echo "::endgroup::"
