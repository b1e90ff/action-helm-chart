#!/usr/bin/env bash
set -euo pipefail

: "${CHART_PATH:?CHART_PATH is required}"
: "${CHART_NAME:?CHART_NAME is required}"

echo "::group::Helm Template"

if grep -q "^dependencies:" "${CHART_PATH}/Chart.yaml" 2>/dev/null; then
  helm dependency update "${CHART_PATH}" 2>/dev/null || true
fi

HAS_FAILURE=0

VALUES_FILES=$(find "${CHART_PATH}" -maxdepth 1 -name 'values*.yaml' -o -name 'values*.yml' | sort)

if [ -z "${VALUES_FILES}" ]; then
  echo "No values files found, running template without values"
  if ! helm template "${CHART_NAME}" "${CHART_PATH}" > /dev/null 2>&1; then
    echo "::error::Template rendering failed (no values)"
    helm template "${CHART_NAME}" "${CHART_PATH}" 2>&1 || true
    HAS_FAILURE=1
  else
    echo "Template OK (no values)"
  fi
else
  for values_file in ${VALUES_FILES}; do
    filename=$(basename "${values_file}")
    echo "Validating with ${filename}..."
    if ! helm template "${CHART_NAME}" "${CHART_PATH}" -f "${values_file}" > /dev/null 2>&1; then
      echo "::error::Template rendering failed with ${filename}"
      helm template "${CHART_NAME}" "${CHART_PATH}" -f "${values_file}" 2>&1 || true
      HAS_FAILURE=1
    else
      echo "Template OK (${filename})"
    fi
  done
fi

echo "::endgroup::"

if [ "${HAS_FAILURE}" -ne 0 ]; then
  exit 1
fi
