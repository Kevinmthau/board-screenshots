#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/runtime-paths.sh"

/bin/launchctl bootout "$USER_DOMAIN" "$LAUNCH_AGENT_PATH" >/dev/null 2>&1 || true
/bin/rm -f "$LAUNCH_AGENT_PATH"

echo "Removed launch agent: $LAUNCH_AGENT_PATH"
