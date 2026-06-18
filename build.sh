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
ICON_SOURCE="$ROOT/Assets/AppIcon.png"
ICON_FILE="$ROOT/Assets/AppIcon.icns"
ICONSET_DIR="$OUTPUT_DIR/AppIcon.iconset"
ICON_BASE="$OUTPUT_DIR/AppIcon-1024.png"
SWIFT_BUILD_DIR="${SWIFT_BUILD_DIR:-${TMPDIR:-/tmp}/pathconverter-swift-build}"
export CLANG_MODULE_CACHE_PATH="${CLANG_MODULE_CACHE_PATH:-${TMPDIR:-/tmp}/pathconverter-clang-cache}"

swift build -c release --disable-sandbox --package-path "$ROOT" --build-path "$SWIFT_BUILD_DIR"

mkdir -p "$OUTPUT_DIR" "$BACKUP_DIR"
if [ -d "$APP_DIR" ]; then
  mv "$APP_DIR" "$BACKUP_DIR/$APP_NAME.app.$(date +%Y%m%d%H%M%S)"
fi

mkdir -p "$MACOS_DIR" "$RESOURCES_DIR" "$CONFIG_DIR"
cp "$SWIFT_BUILD_DIR/release/$APP_NAME" "$MACOS_DIR/$APP_NAME"
chmod +x "$MACOS_DIR/$APP_NAME"

if [ ! -f "$CONFIG_DIR/config.json" ]; then
  cp "$ROOT/data/config.json" "$CONFIG_DIR/config.json"
fi

cp "$ROOT/data/config.json" "$RESOURCES_DIR/config.json"

if [ -f "$ICON_FILE" ]; then
  cp "$ICON_FILE" "$RESOURCES_DIR/AppIcon.icns"
elif [ -f "$ICON_SOURCE" ]; then
  rm -rf "$ICONSET_DIR"
  mkdir -p "$ICONSET_DIR"
  sips -s format png -z 1024 1024 "$ICON_SOURCE" --out "$ICON_BASE" >/dev/null
  sips -z 16 16 "$ICON_BASE" --out "$ICONSET_DIR/icon_16x16.png" >/dev/null
  sips -z 32 32 "$ICON_BASE" --out "$ICONSET_DIR/icon_16x16@2x.png" >/dev/null
  sips -z 32 32 "$ICON_BASE" --out "$ICONSET_DIR/icon_32x32.png" >/dev/null
  sips -z 64 64 "$ICON_BASE" --out "$ICONSET_DIR/icon_32x32@2x.png" >/dev/null
  sips -z 128 128 "$ICON_BASE" --out "$ICONSET_DIR/icon_128x128.png" >/dev/null
  sips -z 256 256 "$ICON_BASE" --out "$ICONSET_DIR/icon_128x128@2x.png" >/dev/null
  sips -z 256 256 "$ICON_BASE" --out "$ICONSET_DIR/icon_256x256.png" >/dev/null
  sips -z 512 512 "$ICON_BASE" --out "$ICONSET_DIR/icon_256x256@2x.png" >/dev/null
  sips -z 512 512 "$ICON_BASE" --out "$ICONSET_DIR/icon_512x512.png" >/dev/null
  cp "$ICON_BASE" "$ICONSET_DIR/icon_512x512@2x.png"
  iconutil -c icns "$ICONSET_DIR" -o "$RESOURCES_DIR/AppIcon.icns"
fi

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
  <key>CFBundleIconFile</key>
  <string>AppIcon</string>
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
if [ -f "$RESOURCES_DIR/AppIcon.icns" ]; then
  echo "Icon: $RESOURCES_DIR/AppIcon.icns"
fi
