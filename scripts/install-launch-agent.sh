#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/runtime-paths.sh"

RUN_SCRIPT="$SCRIPT_DIR/run-server.sh"
OPEN_SCRIPT="$SCRIPT_DIR/open-ui.sh"

mkdir -p "$LAUNCH_AGENTS_DIR" "$APP_SUPPORT_DIR" "$RUNTIME_SUPPORT_DIR" "$LOG_DIR" "$SCREENSHOTS_DIR"
chmod +x \
  "$RUN_SCRIPT" \
  "$OPEN_SCRIPT" \
  "$SCRIPT_DIR/ensure-runtime.sh" \
  "$SCRIPT_DIR/uninstall-launch-agent.sh"

/bin/bash "$SCRIPT_DIR/ensure-runtime.sh"

cat > "$LAUNCH_AGENT_PATH" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>$APP_LABEL</string>
  <key>ProgramArguments</key>
  <array>
    <string>/bin/bash</string>
    <string>$RUN_SCRIPT</string>
  </array>
  <key>EnvironmentVariables</key>
  <dict>
    <key>HOME</key>
    <string>$HOME</string>
    <key>PATH</key>
    <string>/usr/local/bin:/opt/homebrew/bin:/usr/bin:/bin:/usr/sbin:/sbin</string>
  </dict>
  <key>KeepAlive</key>
  <true/>
  <key>RunAtLoad</key>
  <true/>
  <key>WorkingDirectory</key>
  <string>$APP_ROOT</string>
  <key>StandardOutPath</key>
  <string>$LOG_DIR/server.stdout.log</string>
  <key>StandardErrorPath</key>
  <string>$LOG_DIR/server.stderr.log</string>
</dict>
</plist>
EOF

/bin/launchctl bootout "$USER_DOMAIN" "$LAUNCH_AGENT_PATH" >/dev/null 2>&1 || true
/bin/launchctl bootstrap "$USER_DOMAIN" "$LAUNCH_AGENT_PATH"
/bin/launchctl enable "$USER_DOMAIN/$APP_LABEL" >/dev/null 2>&1 || true
/bin/launchctl kickstart -k "$USER_DOMAIN/$APP_LABEL" >/dev/null 2>&1 || true

echo "Installed launch agent: $LAUNCH_AGENT_PATH"
echo "The server will now start automatically at login."
echo "Open the UI with: /bin/bash \"$OPEN_SCRIPT\""
