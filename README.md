# terraview-action

GitHub Action for scanning Terraform plans with [TerraView](https://github.com/leonamvasquez/terraview) — static analysis + optional AI contextual analysis.

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

```yaml
- name: TerraView scan (SARIF)
  uses: leonamvasquez/terraview-action@v1
  with:
    plan: plan.json
    format: sarif
    fail-on: CRITICAL   # only block on CRITICAL

- name: Upload SARIF
  uses: github/codeql-action/upload-sarif@v3
  if: always()
  with:
    sarif_file: results.sarif
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
          sarif_file: results.sarif
```
