#!/usr/bin/env bash
set -euo pipefail

: "${CHART_PATH:?CHART_PATH is required}"

echo "::group::Helm Lint"

if grep -q "^dependencies:" "${CHART_PATH}/Chart.yaml" 2>/dev/null; then
  helm dependency build "${CHART_PATH}" || true
fi

args=("${CHART_PATH}")
[[ "${INPUT_LINT_STRICT:-true}" == "true" ]] && args+=("--strict")

helm lint "${args[@]}" || { echo "::error::Lint failed"; echo "::endgroup::"; exit 1; }

echo "::endgroup::"
