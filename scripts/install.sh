#!/usr/bin/env bash
set -euo pipefail

# Detect OS and architecture
OS="$(uname -s | tr '[:upper:]' '[:lower:]')"
ARCH="$(uname -m)"
case "$ARCH" in
  x86_64)  ARCH="amd64" ;;
  aarch64|arm64) ARCH="arm64" ;;
  *) echo "Unsupported architecture: $ARCH" >&2; exit 1 ;;
esac

# Resolve version
VERSION="${TV_VERSION:-latest}"
if [ "$VERSION" = "latest" ]; then
  VERSION="$(curl -fsSL https://api.github.com/repos/leonamvasquez/terraview/releases/latest \
    | grep '"tag_name"' | sed -E 's/.*"tag_name": *"([^"]+)".*/\1/')"
fi

echo "Installing TerraView ${VERSION} (${OS}/${ARCH})..."

# Build download URL — matches release asset naming: terraview-linux-amd64.tar.gz
EXT="tar.gz"
if [ "$OS" = "windows" ]; then EXT="zip"; fi

FILENAME="terraview-${OS}-${ARCH}.${EXT}"
URL="https://github.com/leonamvasquez/terraview/releases/download/${VERSION}/${FILENAME}"

TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT

curl -fsSL "$URL" -o "${TMPDIR}/${FILENAME}"

if [ "$EXT" = "zip" ]; then
  unzip -q "${TMPDIR}/${FILENAME}" -d "$TMPDIR"
else
  tar -xzf "${TMPDIR}/${FILENAME}" -C "$TMPDIR"
fi

INSTALL_DIR="${HOME}/.local/bin"
mkdir -p "$INSTALL_DIR"
mv "${TMPDIR}/terraview" "${INSTALL_DIR}/terraview"
chmod +x "${INSTALL_DIR}/terraview"

# Add to PATH for subsequent steps
echo "$INSTALL_DIR" >> "$GITHUB_PATH"

echo "TerraView ${VERSION} installed at ${INSTALL_DIR}/terraview"
