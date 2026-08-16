#!/usr/bin/env bash
set -euo pipefail

MODE="${1:-run}"
APP_NAME="BarKeep"
BUNDLE_ID="com.bharatsoni.BarKeep"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST_DIR="$ROOT_DIR/dist"
STAGE_DIR="/tmp/com.bharatsoni.BarKeep-build-$UID"
APP_BUNDLE="$STAGE_DIR/$APP_NAME.app"
DIST_APP="$DIST_DIR/$APP_NAME.app"
APP_CONTENTS="$APP_BUNDLE/Contents"
APP_MACOS="$APP_CONTENTS/MacOS"
APP_RESOURCES="$APP_CONTENTS/Resources"
APP_BINARY="$APP_MACOS/$APP_NAME"
SIGN_IDENTITY="${BARKEEP_CODESIGN_IDENTITY:--}"

pkill -x "$APP_NAME" >/dev/null 2>&1 || true

BUILD_CONFIGURATION="debug"
if [[ "$MODE" == "--package" || "$MODE" == "package" ]]; then
  BUILD_CONFIGURATION="release"
fi

swift build -c "$BUILD_CONFIGURATION"
BUILD_BINARY="$(swift build -c "$BUILD_CONFIGURATION" --show-bin-path)/$APP_NAME"

rm -rf "$APP_BUNDLE"
mkdir -p "$APP_MACOS" "$APP_RESOURCES"
cp "$BUILD_BINARY" "$APP_BINARY"
cp "$ROOT_DIR/Packaging/Info.plist" "$APP_CONTENTS/Info.plist"
cp "$ROOT_DIR/Packaging/AppIcon.icns" "$APP_RESOURCES/AppIcon.icns"
chmod +x "$APP_BINARY"
xattr -cr "$APP_BUNDLE"
xattr -d com.apple.FinderInfo "$APP_BUNDLE" >/dev/null 2>&1 || true
xattr -d 'com.apple.fileprovider.fpfs#P' "$APP_BUNDLE" >/dev/null 2>&1 || true
codesign --force --deep --sign "$SIGN_IDENTITY" "$APP_BUNDLE" >/dev/null
codesign --verify --deep --strict "$APP_BUNDLE"

mkdir -p "$DIST_DIR"
rm -rf "$DIST_APP"
ditto --norsrc --noextattr --noqtn --noacl "$APP_BUNDLE" "$DIST_APP"
xattr -d com.apple.FinderInfo "$DIST_APP" >/dev/null 2>&1 || true
xattr -d 'com.apple.fileprovider.fpfs#P' "$DIST_APP" >/dev/null 2>&1 || true
codesign --verify --deep --strict "$DIST_APP"

open_app() {
  /usr/bin/open -n "$DIST_APP"
}

case "$MODE" in
  run)
    open_app
    ;;
  --debug|debug)
    lldb -- "$DIST_APP/Contents/MacOS/$APP_NAME"
    ;;
  --logs|logs)
    open_app
    /usr/bin/log stream --info --style compact --predicate "process == \"$APP_NAME\""
    ;;
  --telemetry|telemetry)
    open_app
    /usr/bin/log stream --info --style compact --predicate "subsystem == \"$BUNDLE_ID\""
    ;;
  --verify|verify)
    open_app
    sleep 2
    pgrep -x "$APP_NAME" >/dev/null
    echo "$APP_NAME is running from $DIST_APP"
    ;;
  --package|package)
    rm -f "$DIST_DIR/$APP_NAME-1.0.0.zip" "$DIST_DIR/$APP_NAME-1.0.0.zip.sha256"
    ditto -c -k --norsrc --noextattr --noqtn --noacl --keepParent "$APP_BUNDLE" "$DIST_DIR/$APP_NAME-1.0.0.zip"
    shasum -a 256 "$DIST_DIR/$APP_NAME-1.0.0.zip" > "$DIST_DIR/$APP_NAME-1.0.0.zip.sha256"
    echo "Created $DIST_DIR/$APP_NAME-1.0.0.zip"
    ;;
  *)
    echo "usage: $0 [run|--debug|--logs|--telemetry|--verify|--package]" >&2
    exit 2
    ;;
esac
