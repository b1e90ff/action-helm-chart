#!/usr/bin/env bash
set -euo pipefail

: "${CHART_PATH:?CHART_PATH is required}"
: "${CHART_NAME:?CHART_NAME is required}"

echo "::group::Helm Template"

# Resolve dependencies first if any are declared
if grep -q "^dependencies:" "${CHART_PATH}/Chart.yaml" 2>/dev/null; then
  helm dependency build "${CHART_PATH}" --skip-refresh 2>/dev/null || true
fi

if ! helm template "${CHART_NAME}" "${CHART_PATH}" > /dev/null 2>&1; then
  echo "::error::Template rendering failed"
  helm template "${CHART_NAME}" "${CHART_PATH}" 2>&1 || true
  echo "::endgroup::"
  exit 1
fi

echo "Template OK"
echo "::endgroup::"
