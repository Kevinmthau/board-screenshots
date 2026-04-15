#!/bin/bash

set -euo pipefail

LABEL="com.kevinthau.board-screenshot-app"
PLIST_PATH="$HOME/Library/LaunchAgents/$LABEL.plist"
USER_DOMAIN="gui/$(id -u)"

/bin/launchctl bootout "$USER_DOMAIN" "$PLIST_PATH" >/dev/null 2>&1 || true
/bin/rm -f "$PLIST_PATH"

echo "Removed launch agent: $PLIST_PATH"
