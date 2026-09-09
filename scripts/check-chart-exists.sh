#!/usr/bin/env bash
set -euo pipefail

: "${CHART_NAME:?CHART_NAME is required}"
: "${CHART_VERSION:?CHART_VERSION is required}"
: "${CHARTS_OCI_URLS:?CHARTS_OCI_URLS is required}"
: "${GITHUB_OUTPUT:?GITHUB_OUTPUT is required}"

SKIP_EXISTING="${SKIP_EXISTING:-true}"

echo "::group::Registry Check"

if [[ "${SKIP_EXISTING}" != "true" ]]; then
  echo "skip-existing is off — publishing regardless"
  echo "skip_processing=false" >> "${GITHUB_OUTPUT}"
  echo "::endgroup::"
  exit 0
fi

missing=()
for target in ${CHARTS_OCI_URLS}; do
  if helm show chart "${target}/${CHART_NAME}" --version "${CHART_VERSION}" &>/dev/null; then
    echo "present in ${target}"
  else
    echo "missing in ${target}"
    missing+=("${target}")
  fi
done

# One missing target still has to be served, which is what makes a partial push re-runnable.
if [[ ${#missing[@]} -eq 0 ]]; then
  echo "::notice::${CHART_NAME}:${CHART_VERSION} already in every registry — skipping"
  echo "skip_processing=true" >> "${GITHUB_OUTPUT}"
else
  echo "${CHART_NAME}:${CHART_VERSION} missing in ${#missing[@]} of the targets — will publish"
  echo "skip_processing=false" >> "${GITHUB_OUTPUT}"
fi

echo "::endgroup::"
