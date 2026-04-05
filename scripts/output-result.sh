#!/usr/bin/env bash
set -euo pipefail

: "${INPUT_MODE:?INPUT_MODE is required}"
: "${CHART_FOUND:?CHART_FOUND is required}"

if [[ "${CHART_FOUND}" != "true" ]]; then
  echo "released=false" >> "${GITHUB_OUTPUT}"
  exit 0
fi

case "${INPUT_MODE}" in
  validate)
    echo "released=false" >> "${GITHUB_OUTPUT}"
    ;;
  release)
    if [[ "${SKIP_PROCESSING:-false}" == "true" ]]; then
      echo "released=false" >> "${GITHUB_OUTPUT}"
    else
      echo "released=true" >> "${GITHUB_OUTPUT}"
    fi
    ;;
esac
