#!/bin/bash

set -euo pipefail

LABEL="com.kevinthau.board-screenshot-app"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
LAUNCH_AGENTS_DIR="$HOME/Library/LaunchAgents"
PLIST_PATH="$LAUNCH_AGENTS_DIR/$LABEL.plist"
RUN_SCRIPT="$PROJECT_DIR/scripts/run-server.sh"
OPEN_COMMAND="$PROJECT_DIR/Open Board Screenshots.command"
LOG_DIR="$PROJECT_DIR/logs"
USER_DOMAIN="gui/$(id -u)"

mkdir -p "$LAUNCH_AGENTS_DIR" "$LOG_DIR"
chmod +x "$RUN_SCRIPT" "$PROJECT_DIR/scripts/open-ui.sh" "$PROJECT_DIR/scripts/uninstall-launch-agent.sh" "$OPEN_COMMAND"

cat > "$PLIST_PATH" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>$LABEL</string>
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
  <string>$PROJECT_DIR</string>
  <key>StandardOutPath</key>
  <string>$LOG_DIR/server.stdout.log</string>
  <key>StandardErrorPath</key>
  <string>$LOG_DIR/server.stderr.log</string>
</dict>
</plist>
EOF

/bin/launchctl bootout "$USER_DOMAIN" "$PLIST_PATH" >/dev/null 2>&1 || true
/bin/launchctl bootstrap "$USER_DOMAIN" "$PLIST_PATH"
/bin/launchctl enable "$USER_DOMAIN/$LABEL" >/dev/null 2>&1 || true
/bin/launchctl kickstart -k "$USER_DOMAIN/$LABEL" >/dev/null 2>&1 || true

echo "Installed launch agent: $PLIST_PATH"
echo "The server will now start automatically at login."
echo "Open the UI with: $OPEN_COMMAND"
