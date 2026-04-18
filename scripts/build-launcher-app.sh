#!/bin/bash

set -euo pipefail

APP_NAME="Board Screenshots"
BUNDLE_ID="com.board-screenshots.app"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
DIST_DIR="${1:-$PROJECT_DIR/dist}"
APP_PATH="$DIST_DIR/$APP_NAME.app"
CONTENTS_DIR="$APP_PATH/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"
APP_RESOURCES_DIR="$RESOURCES_DIR/app"
RUNTIME_DIR="$RESOURCES_DIR/runtime"
SCRIPT_RESOURCES_DIR="$RESOURCES_DIR/scripts"
EXECUTABLE_NAME="board-screenshots-launcher"
EXECUTABLE_PATH="$MACOS_DIR/$EXECUTABLE_NAME"
ICON_NAME="board-screenshots"
ICON_PATH="$RESOURCES_DIR/$ICON_NAME.icns"
ICON_PREVIEW_PATH="$DIST_DIR/$APP_NAME Icon.png"
TMP_DIR="$(mktemp -d "${TMPDIR:-/tmp}/board-screenshots-launcher.XXXXXX")"
ICONSET_DIR="$TMP_DIR/$ICON_NAME.iconset"

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

resolve_adb_path() {
  local candidate

  for candidate in \
    "${ADB_PATH:-}" \
    "$HOME/Library/Android/sdk/platform-tools/adb" \
    "$HOME/Android/Sdk/platform-tools/adb" \
    "${ANDROID_SDK_ROOT:-}/platform-tools/adb" \
    "${ANDROID_HOME:-}/platform-tools/adb"
  do
    if [[ -n "$candidate" && -x "$candidate" ]]; then
      printf '%s\n' "$candidate"
      return 0
    fi
  done

  candidate="$(command -v adb || true)"
  if [[ -n "$candidate" ]]; then
    printf '%s\n' "$candidate"
    return 0
  fi

  return 1
}

require_tool iconutil
require_tool swift
require_tool node
require_tool ditto

NODE_BIN="$(command -v node)"
NODE_VERSION="$("$NODE_BIN" -p 'process.version')"
PACKAGE_ARCH="$(uname -m)"
ADB_BIN="$(resolve_adb_path || true)"

if [[ -z "$ADB_BIN" ]]; then
  echo "Could not find adb to bundle. Set ADB_PATH or install Android platform-tools first." >&2
  exit 1
fi

APP_VERSION="$(cd "$PROJECT_DIR" && "$NODE_BIN" -p 'require("./package.json").version' 2>/dev/null || true)"
if [[ -z "$APP_VERSION" ]]; then
  APP_VERSION="1.0.0"
fi

/bin/rm -rf "$APP_PATH"
mkdir -p "$DIST_DIR" "$MACOS_DIR" "$APP_RESOURCES_DIR/public" "$RUNTIME_DIR" "$SCRIPT_RESOURCES_DIR"

swift "$PROJECT_DIR/scripts/generate-icon.swift" "$ICONSET_DIR"
iconutil -c icns "$ICONSET_DIR" -o "$ICON_PATH"
/bin/cp "$ICONSET_DIR/icon_512x512@2x.png" "$ICON_PREVIEW_PATH"

/usr/bin/ditto "$PROJECT_DIR/public" "$APP_RESOURCES_DIR/public"
/bin/cp "$PROJECT_DIR/server.js" "$APP_RESOURCES_DIR/server.js"

for runtime_script in \
  ensure-runtime.sh \
  install-launch-agent.sh \
  open-ui.sh \
  run-server.sh \
  runtime-paths.sh \
  uninstall-launch-agent.sh
do
  /bin/cp "$PROJECT_DIR/scripts/$runtime_script" "$SCRIPT_RESOURCES_DIR/$runtime_script"
done

/bin/cp "$NODE_BIN" "$RUNTIME_DIR/node"
/bin/cp "$ADB_BIN" "$RUNTIME_DIR/adb"

cat > "$RUNTIME_DIR/metadata.env" <<EOF
PACKAGE_ARCH="$PACKAGE_ARCH"
NODE_VERSION="$NODE_VERSION"
EOF

chmod +x "$RUNTIME_DIR/node" "$RUNTIME_DIR/adb" "$SCRIPT_RESOURCES_DIR"/*.sh

cat > "$EXECUTABLE_PATH" <<'EOF'
#!/bin/bash

set -euo pipefail

EXECUTABLE_DIR="$(cd "$(dirname "$0")" && pwd)"
RESOURCES_DIR="$(cd "$EXECUTABLE_DIR/../Resources" && pwd)"

exec /bin/bash "$RESOURCES_DIR/scripts/open-ui.sh"
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

echo "Built macOS app bundle: $APP_PATH"
echo "Bundled node: $NODE_BIN"
echo "Bundled adb: $ADB_BIN"
echo "Icon preview: $ICON_PREVIEW_PATH"
