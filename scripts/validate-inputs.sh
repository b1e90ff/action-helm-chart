#!/usr/bin/env bash
set -euo pipefail

case "${INPUT_MODE}" in
  discover)
    [[ -n "${INPUT_CHART_PATTERN:-}" ]] || { echo "::error::discover mode requires 'chart-pattern'"; exit 1; }
    ;;
  validate|release)
    [[ -n "${INPUT_CHART_DIRECTORY:-}" ]] || { echo "::error::${INPUT_MODE} mode requires 'chart-directory'"; exit 1; }
    [[ -d "${INPUT_CHART_DIRECTORY}" ]]   || { echo "::warning::Directory '${INPUT_CHART_DIRECTORY}' not found"; exit 0; }
    [[ -f "${INPUT_CHART_DIRECTORY}/Chart.yaml" ]] || { echo "::error::Chart.yaml not found in '${INPUT_CHART_DIRECTORY}'"; exit 1; }
    ;;
  *)
    echo "::error::Invalid mode '${INPUT_MODE}'. Expected: discover, validate, release"
    exit 1
    ;;
esac
