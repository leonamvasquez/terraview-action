<p align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/leonamvasquez/terraview/main/.github/assets/terraview-logo-dark-theme.png" width="340" />
    <source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/leonamvasquez/terraview/main/.github/assets/terraview-logo-white-theme.png" width="340" />
    <img alt="TerraView" src="https://raw.githubusercontent.com/leonamvasquez/terraview/main/.github/assets/terraview-logo-white-theme.png" width="340" />
  </picture>
</p>

<p align="center">
  <strong>GitHub Action for scanning Terraform plans with AI-powered contextual analysis</strong>
</p>

<p align="center">
  <a href="https://github.com/leonamvasquez/terraview/releases/latest"><img src="https://img.shields.io/github/v/release/leonamvasquez/terraview?label=terraview&color=7c3aed" alt="Latest Release" /></a>
  <a href="https://github.com/marketplace/actions/terraview"><img src="https://img.shields.io/badge/GitHub%20Marketplace-TerraView-7c3aed" alt="GitHub Marketplace" /></a>
  <a href="https://github.com/leonamvasquez/terraview/blob/main/LICENSE"><img src="https://img.shields.io/github/license/leonamvasquez/terraview?color=7c3aed" alt="License" /></a>
</p>

## Prerequisites

The static scanner must be available on the runner before this action runs:

```yaml
# Install Checkov (default scanner)
- run: pip install checkov

# Or tfsec
- uses: aquasecurity/tfsec-action@v1
  # run tfsec separately, then pass findings via args: '--findings tfsec.json'
```

> If no scanner is found, TerraView degrades gracefully to AI-only analysis (requires `provider` input).

## Usage

```yaml
- name: Generate Terraform plan
  run: |
    terraform init
    terraform plan -out=tfplan
    terraform show -json tfplan > plan.json

- name: TerraView security scan
  uses: leonamvasquez/terraview-action@v1
  with:
    plan: plan.json
```

### With AI analysis

```yaml
- name: TerraView scan with AI
  uses: leonamvasquez/terraview-action@v1
  with:
    plan: plan.json
    provider: gemini
    model: gemini-2.0-flash
    api-key: ${{ secrets.GEMINI_API_KEY }}
```

### Upload SARIF to GitHub Security tab

When using `format: sarif`, TerraView writes `review.sarif.json` to the output directory (defaults to the working directory).

```yaml
- name: TerraView scan (SARIF)
  uses: leonamvasquez/terraview-action@v1
  with:
    plan: plan.json
    format: sarif
    fail-on: CRITICAL

- name: Upload SARIF
  uses: github/codeql-action/upload-sarif@v3
  if: always()
  with:
    sarif_file: review.sarif.json
```

## Inputs

| Input | Description | Default |
|-------|-------------|---------|
| `plan` | Path to Terraform plan JSON (`terraform show -json`) | **required** |
| `scanner` | Static scanner: `checkov`, `tfsec`, `terrascan` | `checkov` |
| `provider` | AI provider: `gemini`, `claude`, `openai`, `deepseek`, `openrouter` | — |
| `model` | AI model (provider-specific) | — |
| `api-key` | AI provider API key — use a GitHub secret | — |
| `format` | Output format: `pretty`, `json`, `sarif`, `html`, `markdown` | `pretty` |
| `output-dir` | Directory for output files. SARIF → `review.sarif.json`, HTML → `report/` | working dir |
| `fail-on` | Minimum severity to fail the job: `HIGH`, `CRITICAL`, `NONE` | `HIGH` |
| `version` | TerraView version (e.g. `v0.5.0`). Defaults to latest. | `latest` |
| `args` | Extra arguments passed verbatim to `terraview scan` | — |

## Outputs

| Output | Description |
|--------|-------------|
| `exit-code` | `0` = safe, `1` = HIGH findings, `2` = CRITICAL findings |

## Exit codes & fail-on

| `fail-on` | Fails when |
|-----------|-----------|
| `HIGH` (default) | Any HIGH or CRITICAL finding |
| `CRITICAL` | Only CRITICAL findings |
| `NONE` | Never (informational only) |

## Full pipeline example

```yaml
name: Terraform Security Scan

on:
  pull_request:
    paths:
      - '**.tf'
      - '**.tfvars'

jobs:
  terraview:
    runs-on: ubuntu-latest
    permissions:
      contents: read
      security-events: write   # required for SARIF upload

    steps:
      - uses: actions/checkout@v4

      - uses: hashicorp/setup-terraform@v3

      - name: Install Checkov
        run: pip install checkov

      - name: Terraform init & plan
        run: |
          terraform init
          terraform plan -out=tfplan
          terraform show -json tfplan > plan.json
        working-directory: ./infra

      - name: TerraView scan
        uses: leonamvasquez/terraview-action@v1
        with:
          plan: infra/plan.json
          scanner: checkov
          provider: gemini
          model: gemini-2.0-flash
          api-key: ${{ secrets.GEMINI_API_KEY }}
          format: sarif
          fail-on: HIGH

      - name: Upload SARIF
        uses: github/codeql-action/upload-sarif@v3
        if: always()
        with:
          sarif_file: review.sarif.json
```
