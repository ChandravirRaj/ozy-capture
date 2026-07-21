#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP_SRC="$ROOT/app/build/macos/Build/Products/Release/oxy_capture.app"
APP_DEST="/Applications/Oxy Capture.app"

echo "Building Oxy Capture (release)..."
(cd "$ROOT/app" && flutter build macos --release)

if [[ ! -d "$APP_SRC" ]]; then
  echo "Build output not found: $APP_SRC" >&2
  exit 1
fi

if [[ ! -w "/Applications" ]]; then
  echo "Cannot write to /Applications. Run: sudo $0" >&2
  exit 1
fi

echo "Installing to $APP_DEST ..."
rm -rf "$APP_DEST"
ditto "$APP_SRC" "$APP_DEST"

if [[ ! -d "$APP_DEST" ]]; then
  echo "Install failed: $APP_DEST was not created." >&2
  exit 1
fi

echo ""
echo "Installed successfully:"
echo "  $APP_DEST"
echo ""
echo "Open with:"
echo "  open \"$APP_DEST\""
echo ""
echo "Or find it in Finder → Applications as \"Oxy Capture\"."
echo ""
echo "Note: Screen Recording settings only lists the app AFTER you launch it once."
