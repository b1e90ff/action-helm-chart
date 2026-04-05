#!/usr/bin/env bash
set -euo pipefail

: "${CHART_NAME:?CHART_NAME is required}"
: "${CHART_VERSION:?CHART_VERSION is required}"
: "${TGZ_PATH:?TGZ_PATH is required}"
: "${OCI_REGISTRY:?OCI_REGISTRY is required}"
: "${REGISTRY_OWNER:?REGISTRY_OWNER is required}"
: "${CHARTS_REPO_NAME:?CHARTS_REPO_NAME is required}"

dest="oci://${OCI_REGISTRY}/${REGISTRY_OWNER}/${CHARTS_REPO_NAME}"

echo "::group::Publish"
echo "Target: ${dest}/${CHART_NAME}:${CHART_VERSION}"

helm push "${TGZ_PATH}" "${dest}" || { echo "::error::Push failed"; echo "::endgroup::"; exit 1; }

echo "::notice::Published ${CHART_NAME}:${CHART_VERSION}"
echo "::endgroup::"
