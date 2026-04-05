#!/usr/bin/env bash
set -euo pipefail

: "${CHART_PATH:?CHART_PATH is required}"

echo "::group::Helm Lint"

args=("${CHART_PATH}")
[[ "${INPUT_LINT_STRICT:-true}" == "true" ]] && args+=("--strict")

helm lint "${args[@]}" || { echo "::error::Lint failed"; echo "::endgroup::"; exit 1; }

echo "::endgroup::"
