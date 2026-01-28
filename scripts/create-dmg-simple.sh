#!/bin/bash

# LaTeX Clipboard Converter - Simple DMG Creator
# Creates a clean DMG installer with drag-to-Applications UI
# No external dependencies required

set -e

APP_NAME="LaTeXClipboardConverter"
DMG_NAME="LaTeXClipboardConverter"
VOLUME_NAME="LaTeX Clipboard Converter"
DMG_DIR="dist"
TEMP_DMG="temp.dmg"
FINAL_DMG="${DMG_DIR}/${DMG_NAME}.dmg"

echo "🚀 LaTeX Clipboard Converter - DMG Creator"
echo "==========================================="

# Build the app first
echo ""
echo "🔨 Building Release..."
xcodebuild -project ${APP_NAME}.xcodeproj \
           -scheme ${APP_NAME} \
           -configuration Release \
           -derivedDataPath build \
           clean build 2>&1 | tail -5

# Find the built app
APP_PATH=$(find build -name "${APP_NAME}.app" -type d | head -1)

if [ -z "$APP_PATH" ]; then
    echo "❌ Error: Could not find built app"
    exit 1
fi

echo "✅ Build successful"
echo "📦 App location: $APP_PATH"

# Create dist directory
mkdir -p "${DMG_DIR}"

# Remove old DMG if exists
rm -f "${FINAL_DMG}"
rm -f "${TEMP_DMG}"

# Create a temporary directory for DMG contents
TEMP_DIR=$(mktemp -d)

# Copy the app
cp -R "$APP_PATH" "${TEMP_DIR}/"

# Create Applications symlink
ln -s /Applications "${TEMP_DIR}/Applications"

# Create the DMG
echo ""
echo "💿 Creating DMG..."
hdiutil create -srcfolder "${TEMP_DIR}" \
               -volname "${VOLUME_NAME}" \
               -fs HFS+ \
               -fsargs "-c c=64,a=16,e=16" \
               -format UDRW \
               -size 200m \
               "${TEMP_DMG}" 2>/dev/null

# Mount the DMG
DEVICE=$(hdiutil attach -readwrite -noverify "${TEMP_DMG}" | grep -E '^/dev/' | head -1 | awk '{print $1}')
MOUNT_DIR="/Volumes/${VOLUME_NAME}"

echo "🔧 Customizing DMG appearance..."
sleep 2

# Apply DMG styling using AppleScript
osascript << EOF
tell application "Finder"
    tell disk "${VOLUME_NAME}"
        open
        set current view of container window to icon view
        set toolbar visible of container window to false
        set statusbar visible of container window to false
        set the bounds of container window to {200, 120, 680, 400}
        set viewOptions to the icon view options of container window
        set arrangement of viewOptions to not arranged
        set icon size of viewOptions to 80
        set position of item "${APP_NAME}.app" of container window to {120, 140}
        set position of item "Applications" of container window to {360, 140}
        close
        open
        update without registering applications
        delay 2
    end tell
end tell
EOF

# Unmount
echo "📤 Finalizing..."
sync
sleep 1
hdiutil detach "${DEVICE}" -force 2>/dev/null || hdiutil detach "${MOUNT_DIR}" -force 2>/dev/null || true

# Convert to compressed DMG
hdiutil convert "${TEMP_DMG}" \
                -format UDZO \
                -imagekey zlib-level=9 \
                -o "${FINAL_DMG}" 2>/dev/null

# Cleanup
rm -f "${TEMP_DMG}"
rm -rf "${TEMP_DIR}"
rm -rf build

echo ""
echo "============================================"
echo "✅ DMG created successfully!"
echo ""
echo "📍 Location: ${FINAL_DMG}"
echo "📏 Size: $(du -h "${FINAL_DMG}" | cut -f1)"
echo ""
echo "Next steps:"
echo "  1. Open the DMG file"
echo "  2. Drag the app to Applications"
echo "  3. Enjoy! 🎉"
echo "============================================"
