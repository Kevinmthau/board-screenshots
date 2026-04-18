#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/runtime-paths.sh"

export PATH="/usr/local/bin:/opt/homebrew/bin:/usr/bin:/bin:/usr/sbin:/sbin:${PATH:-}"

/bin/bash "$SCRIPT_DIR/ensure-runtime.sh" >/dev/null

CURRENT_ARCH="$(uname -m)"
NODE_BIN=""

if [[ -x "$RUNTIME_SUPPORT_DIR/node" ]]; then
  NODE_BIN="$RUNTIME_SUPPORT_DIR/node"
elif [[ -x "$RUNTIME_DIR/node" && ( -z "$PACKAGE_ARCH" || "$PACKAGE_ARCH" == "$CURRENT_ARCH" ) ]]; then
  NODE_BIN="$RUNTIME_DIR/node"
else
  NODE_BIN="$(command -v node || true)"
fi

if [[ -z "$NODE_BIN" ]]; then
  echo "Could not find a compatible node runtime." >&2
  exit 1
fi

if [[ -z "${ADB_PATH:-}" ]]; then
  for candidate in \
    "$RUNTIME_SUPPORT_DIR/adb" \
    "$RUNTIME_DIR/adb" \
    "$HOME/Library/Android/sdk/platform-tools/adb" \
    "$HOME/Android/Sdk/platform-tools/adb" \
    "${ANDROID_SDK_ROOT:-}/platform-tools/adb" \
    "${ANDROID_HOME:-}/platform-tools/adb"
  do
    if [[ -n "$candidate" && -x "$candidate" ]]; then
      export ADB_PATH="$candidate"
      break
    fi
  done
fi

if [[ -z "${ADB_PATH:-}" ]]; then
  ADB_FROM_PATH="$(command -v adb || true)"
  if [[ -n "$ADB_FROM_PATH" ]]; then
    export ADB_PATH="$ADB_FROM_PATH"
  fi
fi

mkdir -p "$APP_SUPPORT_DIR" "$RUNTIME_SUPPORT_DIR" "$LOG_DIR" "$SCREENSHOTS_DIR"
cd "$APP_ROOT"

export APP_DATA_DIR
export SCREENSHOTS_DIR

exec "$NODE_BIN" "$APP_ROOT/server.js"
