#!/usr/bin/env bash
set -euo pipefail

: "${GITHUB_OUTPUT:?GITHUB_OUTPUT is required}"

# Writes multiple key=value pairs to GITHUB_OUTPUT
emit() { for kv in "$@"; do echo "${kv}" >> "${GITHUB_OUTPUT}"; done; }

# Builds a JSON string array from positional args
to_json_array() {
  local out="["
  local sep=""
  for item in "$@"; do
    # Escape backslashes and double-quotes
    item="${item//\\/\\\\}"
    item="${item//\"/\\\"}"
    out+="${sep}\"${item}\""
    sep=","
  done
  echo "${out}]"
}

if [[ "${INPUT_MODE}" == "discover" ]]; then
  echo "::group::Chart Discovery"
  echo "Pattern: ${INPUT_CHART_PATTERN}"

  charts=()
  shopt -s nullglob
  # shellcheck disable=SC2086
  for dir in ${INPUT_CHART_PATTERN}; do
    [[ -d "${dir}" && -f "${dir}/Chart.yaml" ]] || continue
    dir="${dir#./}"
    charts+=("${dir}")
    echo "  ${dir}"
  done
  shopt -u nullglob

  count=${#charts[@]}
  if (( count == 0 )); then
    echo "::warning::No charts matched '${INPUT_CHART_PATTERN}'"
    emit "charts_matrix=[]" "charts_count=0" "chart_found=false"
  else
    emit "charts_matrix=$(to_json_array "${charts[@]}")" "charts_count=${count}" "chart_found=true"
    echo "Found ${count} chart(s)"
  fi

  echo "::endgroup::"
  exit 0
fi

# Single-chart mode (validate / release)
if [[ -d "${INPUT_CHART_DIRECTORY}" && -f "${INPUT_CHART_DIRECTORY}/Chart.yaml" ]]; then
  emit "chart_found=true" "charts_matrix=$(to_json_array "${INPUT_CHART_DIRECTORY}")" "charts_count=1"
else
  echo "::warning::No valid chart at '${INPUT_CHART_DIRECTORY}'"
  emit "chart_found=false" "charts_matrix=[]" "charts_count=0"
fi
