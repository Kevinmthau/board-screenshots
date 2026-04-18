#!/bin/bash

APP_NAME="Board Screenshots"
APP_LABEL="com.board-screenshots.app"
DEFAULT_HOST="127.0.0.1"
DEFAULT_PORT="4820"
DEFAULT_URL="http://$DEFAULT_HOST:$DEFAULT_PORT"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ -f "$SCRIPT_DIR/../app/server.js" ]]; then
  APP_ROOT="$(cd "$SCRIPT_DIR/../app" && pwd)"
  RESOURCES_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
  DEFAULT_DATA_DIR="$HOME/Library/Application Support/$APP_NAME"
elif [[ -f "$SCRIPT_DIR/../server.js" ]]; then
  APP_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
  RESOURCES_DIR="$APP_ROOT"
  DEFAULT_DATA_DIR="$APP_ROOT"
else
  echo "Could not determine Board Screenshots runtime layout." >&2
  return 1 2>/dev/null || exit 1
fi

RUNTIME_DIR="$RESOURCES_DIR/runtime"
LAUNCH_AGENTS_DIR="$HOME/Library/LaunchAgents"
LAUNCH_AGENT_PATH="$LAUNCH_AGENTS_DIR/$APP_LABEL.plist"
USER_DOMAIN="gui/$(id -u)"
APP_DATA_DIR="${APP_DATA_DIR:-$DEFAULT_DATA_DIR}"
APP_SUPPORT_DIR="$APP_DATA_DIR"
RUNTIME_SUPPORT_DIR="${RUNTIME_SUPPORT_DIR:-$APP_DATA_DIR/runtime}"
SCREENSHOTS_DIR="${SCREENSHOTS_DIR:-$APP_DATA_DIR/screenshots}"
LOG_DIR="${LOG_DIR:-$APP_DATA_DIR/logs}"
HEALTH_URL="${DEFAULT_URL%/}/api/health"
PACKAGE_ARCH=""
NODE_VERSION=""

if [[ -f "$RUNTIME_DIR/metadata.env" ]]; then
  # shellcheck disable=SC1090
  source "$RUNTIME_DIR/metadata.env"
fi
