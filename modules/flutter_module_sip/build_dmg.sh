#!/bin/bash

# Build DMG for macOS app
# Usage: ./build_dmg.sh

set -e

APP_NAME="OneCX"
DMG_NAME="OneCX"
VERSION="1.0.0"
BUILT_APP_NAME="siprix_voip_sdk_example"

echo "🚀 Building macOS app..."
flutter build macos --release

echo "📦 Preparing DMG..."

# Paths
BUILD_DIR="build/macos/Build/Products/Release"
BUILT_APP_PATH="$BUILD_DIR/$BUILT_APP_NAME.app"
RENAMED_APP_PATH="$BUILD_DIR/$APP_NAME.app"
DMG_DIR="build/dmg"
DMG_PATH="build/$DMG_NAME-$VERSION.dmg"

# Check if app exists
if [ ! -d "$BUILT_APP_PATH" ]; then
    echo "❌ Error: App not found at $BUILT_APP_PATH"
    echo "Looking for .app files..."
    find build/macos -name "*.app" -type d
    exit 1
fi

echo "✅ App found at: $BUILT_APP_PATH"

# Rename app
echo "📝 Renaming app to $APP_NAME.app..."
if [ -d "$RENAMED_APP_PATH" ]; then
    rm -rf "$RENAMED_APP_PATH"
fi
cp -R "$BUILT_APP_PATH" "$RENAMED_APP_PATH"
APP_PATH="$RENAMED_APP_PATH"

echo "✅ App found at: $APP_PATH"

# Clean up old DMG
rm -rf "$DMG_DIR"
rm -f "$DMG_PATH"

# Create DMG directory
mkdir -p "$DMG_DIR"

# Copy app to DMG directory
echo "📋 Copying app..."
cp -R "$APP_PATH" "$DMG_DIR/"

# Create Applications symlink
echo "🔗 Creating Applications symlink..."
ln -s /Applications "$DMG_DIR/Applications"

# Create DMG
echo "💿 Creating DMG..."
hdiutil create -volname "$APP_NAME" \
    -srcfolder "$DMG_DIR" \
    -ov -format UDZO \
    "$DMG_PATH"

# Clean up
rm -rf "$DMG_DIR"

echo "✅ DMG created successfully!"
echo "📍 Location: $DMG_PATH"
echo "📊 Size:"
ls -lh "$DMG_PATH"

# Open folder
open build/
