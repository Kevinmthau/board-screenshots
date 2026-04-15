#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

export PATH="/usr/local/bin:/opt/homebrew/bin:/usr/bin:/bin:/usr/sbin:/sbin:${PATH:-}"

if [[ -z "${ADB_PATH:-}" ]]; then
  if [[ -x "$HOME/Library/Android/sdk/platform-tools/adb" ]]; then
    export ADB_PATH="$HOME/Library/Android/sdk/platform-tools/adb"
  elif [[ -n "${ANDROID_SDK_ROOT:-}" && -x "$ANDROID_SDK_ROOT/platform-tools/adb" ]]; then
    export ADB_PATH="$ANDROID_SDK_ROOT/platform-tools/adb"
  elif [[ -n "${ANDROID_HOME:-}" && -x "$ANDROID_HOME/platform-tools/adb" ]]; then
    export ADB_PATH="$ANDROID_HOME/platform-tools/adb"
  fi
fi

NODE_BIN="$(command -v node || true)"
if [[ -z "$NODE_BIN" ]]; then
  echo "Could not find node on PATH." >&2
  exit 1
fi

mkdir -p "$PROJECT_DIR/logs" "$PROJECT_DIR/screenshots"
cd "$PROJECT_DIR"

exec "$NODE_BIN" "$PROJECT_DIR/server.js"
