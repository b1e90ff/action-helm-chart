# action-helm-chart

Composite GitHub Action that handles the full Helm chart lifecycle — from discovery and validation to packaging and publishing to OCI-compatible registries.

## Overview

This action operates in three distinct modes that can be combined in a pipeline:

1. **discover** — scans the repository for charts matching a glob pattern and outputs a matrix
2. **validate** — runs `helm lint` (strict) and `helm template` against a chart, unless `validate-chart` is off
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
| `github-token` | no | — | Token for registry login; not needed when every target uses a credential helper |
| `mode` | no | `validate` | `discover`, `validate`, or `release` |
| `chart-directory` | no | — | Chart path (validate/release) |
| `chart-pattern` | no | — | Glob for chart scanning (discover) |
| `charts-oci-url` | no | — | Target repository as a full `oci://` URL, one per line |
| `registry-username` | no | repo owner | User name for registry login |
| `gcp-credentials-json` | no | — | Service account key; used when a `*.pkg.dev` host is involved, ignored otherwise |
| `oci-registry` | no | `ghcr.io` | OCI registry hostname; superseded by `charts-oci-url` |
| `registry-owner` | no | repo owner | Registry namespace owner; superseded by `charts-oci-url` |
| `charts-repo-name` | no | `charts` | Repository name within the namespace; superseded by `charts-oci-url` |
| `source-repo` | no | current repo | URL for OCI source annotation |
| `helm-version` | no | `v3.17.3` | Helm CLI version |
| `skip-existing` | no | `true` | Skip publish when version exists |
| `lint-strict` | no | `true` | Strict lint mode |
| `validate-chart` | no | `true` | Lint and render the chart; turn off for charts that only render with deploy-time values |

## Outputs

| Name | Description |
|------|-------------|
| `charts_matrix` | JSON array for matrix strategy |
| `charts_count` | Number of charts discovered |
| `chart_name` | Name from Chart.yaml |
| `chart_version` | Version from Chart.yaml |
| `chart_app_version` | appVersion from Chart.yaml |
| `tgz_path` | Path to packaged .tgz |
| `skipped` | `true` if the version already existed in every target |
| `released` | `true` if chart was published |

## How Modes Work

| Mode | Steps | Required |
|------|-------|----------|
| `discover` | Glob scan, build JSON matrix | `chart-pattern` |
| `validate` | Lint (strict), template render | `chart-directory` |
| `release` | Lint, template, check registry, resolve deps, annotate, package, push | `chart-directory` |

Linting and rendering are skipped in both modes when `validate-chart` is `false`.

## Workflow Permissions

```yaml
permissions:
  contents: read
  packages: write
```

`validate` needs registry credentials too: linting and rendering a chart with dependencies
pulls the subcharts first. The login therefore covers both the publish targets and every
`oci://` repository the `Chart.yaml` depends on, which need not be the same host.

`packages: write` covers `ghcr.io`. A `*.pkg.dev` host authenticates through the gcloud
credential helper, for which the action needs a key:

```yaml
- uses: b1e90ff/action-helm-chart@v1
  with:
    mode: release
    chart-directory: helm
    charts-oci-url: oci://REGION-docker.pkg.dev/PROJECT/REPO/charts
    gcp-credentials-json: ${{ secrets.GCP_SA_KEY }}
```

The key is needed when a publish target or a chart dependency lives on `*.pkg.dev`, so a
repository that stays on `ghcr.io` can leave it out. `github-token` is the other way round:
needed for every host that is not `*.pkg.dev`. Pushing charts requires an account with write
access to the target repository — on Artifact Registry a virtual repository never accepts a
push, so the target has to be a standard one.

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
