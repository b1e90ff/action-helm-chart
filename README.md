# action-helm-chart

Composite GitHub Action that handles the full Helm chart lifecycle — from discovery and validation to packaging and publishing to OCI-compatible registries.

## Overview

This action operates in three distinct modes that can be combined in a pipeline:

1. **discover** — scans the repository for charts matching a glob pattern and outputs a matrix
2. **validate** — runs `helm lint` (strict) and `helm template` against a chart
3. **release** — validates, packages, annotates, and pushes a chart to an OCI registry

## Quick Start

### Lint a chart

```yaml
- uses: b1e90ff/action-helm-chart@v1
  with:
    github-token: ${{ inputs.token }}
    mode: validate
    chart-directory: my-chart
```

### Publish a chart

```yaml
- uses: b1e90ff/action-helm-chart@v1
  with:
    github-token: ${{ inputs.token }}
    mode: release
    chart-directory: my-chart
```

### Pipeline with matrix discovery

```yaml
jobs:
  find:
    runs-on: ubuntu-latest
    outputs:
      matrix: ${{ steps.scan.outputs.charts_matrix }}
      count: ${{ steps.scan.outputs.charts_count }}
    steps:
      - uses: actions/checkout@v4
      - uses: b1e90ff/action-helm-chart@v1
        id: scan
        with:
          github-token: ${{ inputs.token }}
          mode: discover
          chart-pattern: "charts/*"

  publish:
    needs: find
    if: needs.find.outputs.count != '0'
    runs-on: ubuntu-latest
    strategy:
      fail-fast: false
      matrix:
        chart: ${{ fromJson(needs.find.outputs.matrix) }}
    steps:
      - uses: actions/checkout@v4
      - uses: b1e90ff/action-helm-chart@v1
        with:
          github-token: ${{ inputs.token }}
          mode: release
          chart-directory: ${{ matrix.chart }}
```

## Inputs

| Name | Required | Default | Description |
|------|----------|---------|-------------|
| `github-token` | **yes** | — | Token for OCI registry login and API access |
| `mode` | no | `validate` | `discover`, `validate`, or `release` |
| `chart-directory` | no | — | Chart path (validate/release) |
| `chart-pattern` | no | — | Glob for chart scanning (discover) |
| `oci-registry` | no | `ghcr.io` | OCI registry hostname |
| `registry-owner` | no | repo owner | Registry namespace owner |
| `charts-repo-name` | no | `charts` | Repository name within the namespace |
| `source-repo` | no | current repo | URL for OCI source annotation |
| `helm-version` | no | `v3.17.3` | Helm CLI version |
| `skip-existing` | no | `true` | Skip publish when version exists |
| `lint-strict` | no | `true` | Strict lint mode |

## Outputs

| Name | Description |
|------|-------------|
| `charts_matrix` | JSON array for matrix strategy |
| `charts_count` | Number of charts discovered |
| `chart_name` | Name from Chart.yaml |
| `chart_version` | Version from Chart.yaml |
| `chart_app_version` | appVersion from Chart.yaml |
| `tgz_path` | Path to packaged .tgz |
| `skipped` | `true` if version already existed |
| `released` | `true` if chart was published |

## How Modes Work

| Mode | Steps | Required |
|------|-------|----------|
| `discover` | Glob scan, build JSON matrix | `chart-pattern` |
| `validate` | Lint (strict), template render | `chart-directory` |
| `release` | Lint, template, check registry, resolve deps, annotate, package, push | `chart-directory` |

## Workflow Permissions

```yaml
permissions:
  contents: read
  packages: write
```

## Glob Pattern Reference

| Pattern | Example Matches |
|---------|-----------------|
| `charts/*` | `charts/api`, `charts/web` |
| `services/*/chart` | `services/auth/chart` |
| `**/Chart.yaml/..` | any nested chart |

## Pinning

```yaml
uses: b1e90ff/action-helm-chart@v1       # rolling latest within v1
uses: b1e90ff/action-helm-chart@v1.0.0   # exact
```
