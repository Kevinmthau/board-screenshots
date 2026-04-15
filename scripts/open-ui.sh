#!/bin/bash

set -euo pipefail

LABEL="com.kevinthau.board-screenshot-app"
URL="${1:-http://127.0.0.1:4820}"
HEALTH_URL="${URL%/}/api/health"
USER_DOMAIN="gui/$(id -u)"

if ! /usr/bin/curl -sf "$HEALTH_URL" >/dev/null 2>&1; then
  /bin/launchctl kickstart "$USER_DOMAIN/$LABEL" >/dev/null 2>&1 || true

  for _ in $(seq 1 40); do
    if /usr/bin/curl -sf "$HEALTH_URL" >/dev/null 2>&1; then
      break
    fi
    /bin/sleep 0.25
  done
fi

open "$URL"
