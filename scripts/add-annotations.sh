#!/usr/bin/env bash
set -euo pipefail

: "${CHART_PATH:?CHART_PATH is required}"
: "${SOURCE_REPO:?SOURCE_REPO is required}"

chart_yaml="${CHART_PATH}/Chart.yaml"
[[ -f "${chart_yaml}" ]] || { echo "::error::Chart.yaml not found"; exit 1; }

echo "::group::OCI Annotations"

annotation="org.opencontainers.image.source"

if command -v yq &>/dev/null; then
  yq eval -i ".annotations.\"${annotation}\" = \"${SOURCE_REPO}\"" "${chart_yaml}"
elif grep -q "^annotations:" "${chart_yaml}"; then
  if grep -q "${annotation}:" "${chart_yaml}"; then
    sed -i "s|${annotation}:.*|${annotation}: \"${SOURCE_REPO}\"|" "${chart_yaml}"
  else
    sed -i "/^annotations:/a\\  ${annotation}: \"${SOURCE_REPO}\"" "${chart_yaml}"
  fi
else
  printf '\nannotations:\n  %s: "%s"\n' "${annotation}" "${SOURCE_REPO}" >> "${chart_yaml}"
fi

echo "Source annotation set to ${SOURCE_REPO}"
echo "::endgroup::"
