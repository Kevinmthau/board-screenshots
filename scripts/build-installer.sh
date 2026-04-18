#!/bin/bash

set -euo pipefail

APP_NAME="Board Screenshots"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
DIST_DIR="${1:-$PROJECT_DIR/dist}"
INSTALLER_DIR="$DIST_DIR/$APP_NAME Installer"
APP_PATH="$DIST_DIR/$APP_NAME.app"
BUILD_APP_SCRIPT="$PROJECT_DIR/scripts/build-launcher-app.sh"

bash "$BUILD_APP_SCRIPT" "$DIST_DIR"

/bin/rm -rf "$INSTALLER_DIR"
mkdir -p "$INSTALLER_DIR"
/usr/bin/ditto "$APP_PATH" "$INSTALLER_DIR/$APP_NAME.app"

cat > "$INSTALLER_DIR/Install Board Screenshots.command" <<'EOF'
#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_NAME="Board Screenshots.app"
TARGET_DIR="$HOME/Applications"
SOURCE_APP="$SCRIPT_DIR/$APP_NAME"
TARGET_APP="$TARGET_DIR/$APP_NAME"

mkdir -p "$TARGET_DIR"
/bin/rm -rf "$TARGET_APP"
/usr/bin/ditto "$SOURCE_APP" "$TARGET_APP"
/usr/bin/xattr -dr com.apple.quarantine "$TARGET_APP" >/dev/null 2>&1 || true

/bin/bash "$TARGET_APP/Contents/Resources/scripts/install-launch-agent.sh"
open "$TARGET_APP"

echo "Installed Board Screenshots to $TARGET_APP"
EOF

cat > "$INSTALLER_DIR/Uninstall Board Screenshots.command" <<'EOF'
#!/bin/bash

set -euo pipefail

APP_PATH="$HOME/Applications/Board Screenshots.app"
DATA_DIR="$HOME/Library/Application Support/Board Screenshots"

if [[ -d "$APP_PATH" ]]; then
  /bin/bash "$APP_PATH/Contents/Resources/scripts/uninstall-launch-agent.sh" || true
  /bin/rm -rf "$APP_PATH"
fi

echo "Removed Board Screenshots.app"
echo "Screenshots and logs were kept in: $DATA_DIR"
EOF

cat > "$INSTALLER_DIR/README.txt" <<'EOF'
Board Screenshots Installer

1. Double-click "Install Board Screenshots.command".
2. If macOS warns about an app downloaded from the internet, use right-click > Open.
3. The installer copies Board Screenshots.app into ~/Applications and enables launch-at-login.
4. Open the app from Finder or the Dock to bring up the browser UI.

Saved screenshots and logs live in:
~/Library/Application Support/Board Screenshots
EOF

chmod +x \
  "$INSTALLER_DIR/Install Board Screenshots.command" \
  "$INSTALLER_DIR/Uninstall Board Screenshots.command"

echo "Built installer folder: $INSTALLER_DIR"
