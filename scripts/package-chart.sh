#!/usr/bin/env bash
set -euo pipefail

: "${CHART_PATH:?CHART_PATH is required}"
: "${CHART_NAME:?CHART_NAME is required}"
: "${CHART_VERSION:?CHART_VERSION is required}"
: "${DESTINATION_DIR:?DESTINATION_DIR is required}"

echo "::group::Package"

mkdir -p "${DESTINATION_DIR}"
helm package "${CHART_PATH}" --destination "${DESTINATION_DIR}" || { echo "::error::Packaging failed"; echo "::endgroup::"; exit 1; }

tgz="${DESTINATION_DIR}/${CHART_NAME}-${CHART_VERSION}.tgz"
[[ -f "${tgz}" ]] || { echo "::error::Expected ${tgz} not found"; echo "::endgroup::"; exit 1; }

echo "Packaged: ${tgz}"
echo "tgz_path=${tgz}" >> "${GITHUB_OUTPUT}"

echo "::endgroup::"
