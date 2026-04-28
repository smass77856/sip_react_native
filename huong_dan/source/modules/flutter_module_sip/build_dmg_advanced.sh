#!/bin/bash

# Advanced DMG builder with custom appearance
# Usage: ./build_dmg_advanced.sh

set -e

APP_NAME="OneCX"
DMG_NAME="OneCX"
VERSION="1.0.0"
BUILT_APP_NAME="siprix_voip_sdk_example"

echo "🚀 Building macOS app..."
flutter build macos --release

echo "📦 Preparing DMG with custom appearance..."

# Paths
BUILD_DIR="build/macos/Build/Products/Release"
BUILT_APP_PATH="$BUILD_DIR/$BUILT_APP_NAME.app"
RENAMED_APP_PATH="$BUILD_DIR/$APP_NAME.app"
DMG_DIR="build/dmg_temp"
DMG_TEMP="build/$DMG_NAME-temp.dmg"
DMG_PATH="build/$DMG_NAME-$VERSION.dmg"

# Check if app exists
if [ ! -d "$BUILT_APP_PATH" ]; then
    echo "❌ Error: App not found at $BUILT_APP_PATH"
    exit 1
fi

echo "✅ App found at: $BUILT_APP_PATH"

# Rename app
echo "📝 Renaming app to $APP_NAME.app..."
if [ -d "$RENAMED_APP_PATH" ]; then
    rm -rf "$RENAMED_APP_PATH"
fi
cp -R "$BUILT_APP_PATH" "$RENAMED_APP_PATH"

# Clean up old files
rm -rf "$DMG_DIR"
rm -f "$DMG_TEMP"
rm -f "$DMG_PATH"

# Create DMG directory
mkdir -p "$DMG_DIR"

# Copy app
echo "📋 Copying app..."
cp -R "$RENAMED_APP_PATH" "$DMG_DIR/"

# Create Applications symlink
echo "🔗 Creating Applications symlink..."
ln -s /Applications "$DMG_DIR/Applications"

# Create temporary DMG
echo "💿 Creating temporary DMG..."
hdiutil create -volname "$APP_NAME" \
    -srcfolder "$DMG_DIR" \
    -ov -format UDRW \
    -fs HFS+ \
    "$DMG_TEMP"

# Mount the DMG
echo "📂 Mounting DMG..."
MOUNT_DIR=$(hdiutil attach -readwrite -noverify -noautoopen "$DMG_TEMP" | grep Volumes | awk '{print $3}')

if [ -z "$MOUNT_DIR" ]; then
    echo "❌ Failed to mount DMG"
    exit 1
fi

echo "✅ Mounted at: $MOUNT_DIR"

# Set DMG window properties using AppleScript
echo "🎨 Setting DMG appearance..."
osascript <<EOF
tell application "Finder"
    tell disk "$APP_NAME"
        open
        set current view of container window to icon view
        set toolbar visible of container window to false
        set statusbar visible of container window to false
        set the bounds of container window to {100, 100, 700, 450}
        set viewOptions to the icon view options of container window
        set arrangement of viewOptions to not arranged
        set icon size of viewOptions to 128
        set background picture of viewOptions to file ".background:background.png"
        set position of item "$APP_NAME.app" of container window to {150, 150}
        set position of item "Applications" of container window to {450, 150}
        close
        open
        update without registering applications
        delay 2
    end tell
end tell
EOF

# Unmount
echo "💾 Finalizing DMG..."
sync
hdiutil detach "$MOUNT_DIR"

# Convert to compressed DMG
echo "🗜️ Compressing DMG..."
hdiutil convert "$DMG_TEMP" \
    -format UDZO \
    -imagekey zlib-level=9 \
    -o "$DMG_PATH"

# Clean up
rm -f "$DMG_TEMP"
rm -rf "$DMG_DIR"

echo ""
echo "✅ DMG created successfully!"
echo "📍 Location: $DMG_PATH"
echo "📊 Size:"
ls -lh "$DMG_PATH"
echo ""
echo "🎉 Done! Opening build folder..."
open build/
