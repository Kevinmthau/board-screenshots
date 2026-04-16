#!/bin/bash

set -euo pipefail

APP_NAME="Board Screenshots.app"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
BUILD_SCRIPT="$PROJECT_DIR/scripts/build-launcher-app.sh"
SOURCE_APP="$PROJECT_DIR/dist/$APP_NAME"
TARGET_DIR="$HOME/Applications"
TARGET_APP="$TARGET_DIR/$APP_NAME"

"$BUILD_SCRIPT"

mkdir -p "$TARGET_DIR"
/bin/rm -rf "$TARGET_APP"
/usr/bin/ditto "$SOURCE_APP" "$TARGET_APP"

echo "Installed launcher app: $TARGET_APP"
echo "You can open it from Finder or drag it into the Dock."
