#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
APP_NAME="PathConverter"
OUTPUT_DIR="$ROOT/output"
APP_DIR="$ROOT/$APP_NAME.app"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"
CONFIG_DIR="$ROOT/data"
BACKUP_DIR="$OUTPUT_DIR/.previous-builds"

swift build -c release --package-path "$ROOT"

mkdir -p "$OUTPUT_DIR" "$BACKUP_DIR"
if [ -d "$APP_DIR" ]; then
  mv "$APP_DIR" "$BACKUP_DIR/$APP_NAME.app.$(date +%Y%m%d%H%M%S)"
fi

mkdir -p "$MACOS_DIR" "$RESOURCES_DIR" "$CONFIG_DIR"
cp "$ROOT/.build/release/$APP_NAME" "$MACOS_DIR/$APP_NAME"
chmod +x "$MACOS_DIR/$APP_NAME"

if [ ! -f "$CONFIG_DIR/config.json" ]; then
  cp "$ROOT/data/config.json" "$CONFIG_DIR/config.json"
fi

cp "$ROOT/data/config.json" "$RESOURCES_DIR/config.json"

cat > "$CONTENTS_DIR/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleDevelopmentRegion</key>
  <string>en</string>
  <key>CFBundleExecutable</key>
  <string>$APP_NAME</string>
  <key>CFBundleIdentifier</key>
  <string>local.pathconverter</string>
  <key>CFBundleName</key>
  <string>Path Converter</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleShortVersionString</key>
  <string>0.1.0</string>
  <key>CFBundleVersion</key>
  <string>1</string>
  <key>LSMinimumSystemVersion</key>
  <string>14.0</string>
  <key>LSUIElement</key>
  <true/>
  <key>NSHighResolutionCapable</key>
  <true/>
</dict>
</plist>
PLIST

if command -v codesign >/dev/null 2>&1; then
  codesign --force --deep --sign - "$APP_DIR" >/dev/null
fi

echo "Built: $APP_DIR"
echo "Default config: $APP_DIR/Contents/Resources/config.json"
