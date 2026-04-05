#!/usr/bin/env bash
set -euo pipefail

: "${CHART_PATH:?CHART_PATH is required}"

chart_yaml="${CHART_PATH}/Chart.yaml"
[[ -f "${chart_yaml}" ]] || { echo "::error::Chart.yaml not found at ${chart_yaml}"; exit 1; }

echo "::group::Chart Metadata"

# Simple YAML field extractor (top-level scalar fields only)
field() {
  grep -m1 -E "^${1}:" "${chart_yaml}" | sed "s/^${1}:[[:space:]]*//" | tr -d "\"'" || echo ""
}

name=$(field name)
version=$(field version)
app_version=$(field appVersion)

[[ -n "${name}" ]]    || { echo "::error::Missing 'name' in Chart.yaml";    exit 1; }
[[ -n "${version}" ]] || { echo "::error::Missing 'version' in Chart.yaml"; exit 1; }

{
  echo "name=${name}"
  echo "version=${version}"
  echo "app_version=${app_version:-}"
} >> "${GITHUB_OUTPUT}"

echo "Name:       ${name}"
echo "Version:    ${version}"
echo "AppVersion: ${app_version:-N/A}"
echo "::endgroup::"
