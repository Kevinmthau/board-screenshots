#!/bin/bash

set -euo pipefail

APP_NAME="Board Screenshots"
BUNDLE_ID="com.kevinthau.board-screenshots"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
DIST_DIR="${1:-$PROJECT_DIR/dist}"
APP_PATH="$DIST_DIR/$APP_NAME.app"
CONTENTS_DIR="$APP_PATH/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"
EXECUTABLE_NAME="board-screenshots-launcher"
EXECUTABLE_PATH="$MACOS_DIR/$EXECUTABLE_NAME"
ICON_NAME="board-screenshots"
ICON_PATH="$RESOURCES_DIR/$ICON_NAME.icns"
ICON_PREVIEW_PATH="$DIST_DIR/$APP_NAME Icon.png"
TMP_DIR="$(mktemp -d "${TMPDIR:-/tmp}/board-screenshots-launcher.XXXXXX")"
ICONSET_DIR="$TMP_DIR/$ICON_NAME.iconset"
PACKAGE_JSON="$PROJECT_DIR/package.json"

cleanup() {
  /bin/rm -rf "$TMP_DIR"
}
trap cleanup EXIT

require_tool() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Missing required tool: $1" >&2
    exit 1
  fi
}

require_tool iconutil
require_tool swift

APP_VERSION="1.0.0"
if command -v node >/dev/null 2>&1; then
  VERSION_FROM_PACKAGE="$(cd "$PROJECT_DIR" && node -p 'require("./package.json").version' 2>/dev/null || true)"
  if [[ -n "$VERSION_FROM_PACKAGE" ]]; then
    APP_VERSION="$VERSION_FROM_PACKAGE"
  fi
fi

OPEN_SCRIPT="$PROJECT_DIR/scripts/open-ui.sh"
PROJECT_DIR_ESCAPED="${PROJECT_DIR//\\/\\\\}"
PROJECT_DIR_ESCAPED="${PROJECT_DIR_ESCAPED//\"/\\\"}"
OPEN_SCRIPT_ESCAPED="${OPEN_SCRIPT//\\/\\\\}"
OPEN_SCRIPT_ESCAPED="${OPEN_SCRIPT_ESCAPED//\"/\\\"}"

mkdir -p "$DIST_DIR" "$MACOS_DIR" "$RESOURCES_DIR"

swift "$PROJECT_DIR/scripts/generate-icon.swift" "$ICONSET_DIR"
iconutil -c icns "$ICONSET_DIR" -o "$ICON_PATH"
/bin/cp "$ICONSET_DIR/icon_512x512@2x.png" "$ICON_PREVIEW_PATH"

cat > "$EXECUTABLE_PATH" <<EOF
#!/bin/bash

set -euo pipefail

PROJECT_DIR="$PROJECT_DIR_ESCAPED"
OPEN_SCRIPT="$OPEN_SCRIPT_ESCAPED"

if [[ ! -x "\$OPEN_SCRIPT" ]]; then
  echo "Missing launcher script: \$OPEN_SCRIPT" >&2
  exit 1
fi

cd "\$PROJECT_DIR"
exec /bin/bash "\$OPEN_SCRIPT"
EOF
chmod +x "$EXECUTABLE_PATH"

cat > "$CONTENTS_DIR/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleDevelopmentRegion</key>
  <string>en</string>
  <key>CFBundleDisplayName</key>
  <string>$APP_NAME</string>
  <key>CFBundleExecutable</key>
  <string>$EXECUTABLE_NAME</string>
  <key>CFBundleIconFile</key>
  <string>$ICON_NAME.icns</string>
  <key>CFBundleIconName</key>
  <string>$ICON_NAME</string>
  <key>CFBundleIdentifier</key>
  <string>$BUNDLE_ID</string>
  <key>CFBundleInfoDictionaryVersion</key>
  <string>6.0</string>
  <key>CFBundleName</key>
  <string>$APP_NAME</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleShortVersionString</key>
  <string>$APP_VERSION</string>
  <key>CFBundleVersion</key>
  <string>1</string>
  <key>LSMinimumSystemVersion</key>
  <string>13.0</string>
  <key>NSHighResolutionCapable</key>
  <true/>
</dict>
</plist>
EOF

printf 'APPL????' > "$CONTENTS_DIR/PkgInfo"

if command -v codesign >/dev/null 2>&1; then
  /usr/bin/codesign --force --deep --sign - "$APP_PATH" >/dev/null 2>&1 || true
fi

echo "Built launcher app: $APP_PATH"
echo "Icon preview: $ICON_PREVIEW_PATH"
echo "Drag the app into the Dock to launch Board Screenshots."
