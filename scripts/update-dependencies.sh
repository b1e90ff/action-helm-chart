#!/usr/bin/env bash
set -euo pipefail

: "${CHART_PATH:?CHART_PATH is required}"

echo "::group::Dependencies"

if grep -q "^dependencies:" "${CHART_PATH}/Chart.yaml" 2>/dev/null; then
  helm dependency build "${CHART_PATH}" || { echo "::error::Dependency build failed"; echo "::endgroup::"; exit 1; }
else
  echo "No dependencies declared"
fi

echo "::endgroup::"
