#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/runtime-paths.sh"

CURRENT_ARCH="$(uname -m)"

if [[ -x "$RUNTIME_SUPPORT_DIR/node" ]]; then
  exit 0
fi

if [[ -x "$RUNTIME_DIR/node" && ( -z "$PACKAGE_ARCH" || "$PACKAGE_ARCH" == "$CURRENT_ARCH" ) ]]; then
  exit 0
fi

if command -v node >/dev/null 2>&1; then
  exit 0
fi

if [[ -z "$NODE_VERSION" ]]; then
  echo "No compatible Node runtime is available for this app bundle." >&2
  exit 1
fi

case "$CURRENT_ARCH" in
  arm64)
    NODE_ARCH="arm64"
    ;;
  x86_64)
    NODE_ARCH="x64"
    ;;
  *)
    echo "Unsupported macOS architecture: $CURRENT_ARCH" >&2
    exit 1
    ;;
esac

TMP_DIR="$(mktemp -d "${TMPDIR:-/tmp}/board-screenshots-node.XXXXXX")"
cleanup() {
  /bin/rm -rf "$TMP_DIR"
}
trap cleanup EXIT

ARCHIVE_URL="https://nodejs.org/dist/$NODE_VERSION/node-$NODE_VERSION-darwin-$NODE_ARCH.tar.gz"
ARCHIVE_PATH="$TMP_DIR/node.tar.gz"

mkdir -p "$RUNTIME_SUPPORT_DIR"

/usr/bin/curl -fL "$ARCHIVE_URL" -o "$ARCHIVE_PATH"
/usr/bin/tar -xzf "$ARCHIVE_PATH" -C "$TMP_DIR"

SOURCE_NODE="$(find "$TMP_DIR" -path "*/bin/node" -type f -print -quit)"
if [[ -z "$SOURCE_NODE" ]]; then
  echo "Downloaded Node archive did not contain a node binary." >&2
  exit 1
fi

/usr/bin/install -m 755 "$SOURCE_NODE" "$RUNTIME_SUPPORT_DIR/node"

echo "Installed Node runtime for $CURRENT_ARCH at $RUNTIME_SUPPORT_DIR/node"
