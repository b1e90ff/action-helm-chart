#!/usr/bin/env bash
set -euo pipefail

: "${CHART_NAME:?CHART_NAME is required}"
: "${CHART_VERSION:?CHART_VERSION is required}"
: "${TGZ_PATH:?TGZ_PATH is required}"
: "${CHARTS_OCI_URLS:?CHARTS_OCI_URLS is required}"

SKIP_EXISTING="${SKIP_EXISTING:-true}"

echo "::group::Publish"

for target in ${CHARTS_OCI_URLS}; do
  if [[ "${SKIP_EXISTING}" == "true" ]] \
    && helm show chart "${target}/${CHART_NAME}" --version "${CHART_VERSION}" &>/dev/null; then
    echo "${target}: ${CHART_VERSION} already there — skipped"
    continue
  fi

  echo "Target: ${target}/${CHART_NAME}:${CHART_VERSION}"
  if ! helm push "${TGZ_PATH}" "${target}"; then
    echo "::error::Push to ${target} failed"
    echo "::endgroup::"
    exit 1
  fi
  echo "::notice::Published ${CHART_NAME}:${CHART_VERSION} to ${target}"
done

echo "::endgroup::"
