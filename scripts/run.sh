#!/usr/bin/env bash
set -euo pipefail

# Build terraview scan arguments
ARGS=("scan" "${TV_SCANNER:-checkov}" "--plan" "${TV_PLAN}")

if [ -n "${TV_FORMAT:-}" ]; then
  ARGS+=("--format" "$TV_FORMAT")
fi

if [ -n "${TV_OUTPUT_DIR:-}" ]; then
  ARGS+=("--output" "$TV_OUTPUT_DIR")
fi

if [ -n "${TV_PROVIDER:-}" ]; then
  ARGS+=("--provider" "$TV_PROVIDER")
fi

if [ -n "${TV_MODEL:-}" ]; then
  ARGS+=("--model" "$TV_MODEL")
fi

# Extra verbatim args (split on spaces)
if [ -n "${TV_ARGS:-}" ]; then
  # shellcheck disable=SC2086
  read -ra EXTRA <<< "$TV_ARGS"
  ARGS+=("${EXTRA[@]}")
fi

# Export API key if provided
if [ -n "${TV_API_KEY:-}" ]; then
  # Detect provider and set the appropriate env var
  case "${TV_PROVIDER:-}" in
    claude*)   export ANTHROPIC_API_KEY="$TV_API_KEY" ;;
    gemini*)   export GEMINI_API_KEY="$TV_API_KEY" ;;
    openai*)   export OPENAI_API_KEY="$TV_API_KEY" ;;
    deepseek*) export DEEPSEEK_API_KEY="$TV_API_KEY" ;;
    openrouter*) export OPENROUTER_API_KEY="$TV_API_KEY" ;;
    *)         export OPENAI_API_KEY="$TV_API_KEY" ;;  # fallback
  esac
fi

echo "Running: terraview ${ARGS[*]}"
set +e
terraview "${ARGS[@]}"
EXIT_CODE=$?
set -e

# Write exit code output for downstream steps
echo "exit_code=${EXIT_CODE}" >> "$GITHUB_OUTPUT"

# Apply fail-on policy
FAIL_ON="${TV_FAIL_ON:-HIGH}"
case "$FAIL_ON" in
  NONE)
    exit 0
    ;;
  CRITICAL)
    # Fail only on CRITICAL (exit code 2)
    if [ "$EXIT_CODE" -eq 2 ]; then
      echo "TerraView found CRITICAL findings." >&2
      exit 2
    fi
    exit 0
    ;;
  HIGH|*)
    # Fail on HIGH or CRITICAL (exit code 1 or 2)
    if [ "$EXIT_CODE" -ge 1 ]; then
      echo "TerraView found HIGH or CRITICAL findings." >&2
      exit "$EXIT_CODE"
    fi
    exit 0
    ;;
esac
