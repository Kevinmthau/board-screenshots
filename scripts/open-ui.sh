#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/runtime-paths.sh"

URL="${1:-$DEFAULT_URL}"
TARGET_HEALTH_URL="${URL%/}/api/health"

mkdir -p "$LOG_DIR"

if ! /usr/bin/curl -sf "$TARGET_HEALTH_URL" >/dev/null 2>&1; then
  /bin/bash "$SCRIPT_DIR/ensure-runtime.sh" >/dev/null

  if [[ -f "$LAUNCH_AGENT_PATH" ]]; then
    /bin/launchctl kickstart "$USER_DOMAIN/$APP_LABEL" >/dev/null 2>&1 || true
  else
    /usr/bin/nohup /bin/bash "$SCRIPT_DIR/run-server.sh" >>"$LOG_DIR/manual.stdout.log" 2>>"$LOG_DIR/manual.stderr.log" &
  fi

  for _ in $(seq 1 40); do
    if /usr/bin/curl -sf "$TARGET_HEALTH_URL" >/dev/null 2>&1; then
      break
    fi
    /bin/sleep 0.25
  done
fi

open "$URL"
