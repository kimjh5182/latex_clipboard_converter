#!/bin/bash

# LaTeX Clipboard Converter - DMG Creator
# Creates a beautiful DMG installer with drag-to-Applications UI

set -e

APP_NAME="LaTeXClipboardConverter"
DMG_NAME="LaTeXClipboardConverter"
VOLUME_NAME="LaTeX Clipboard Converter"
DMG_DIR="dist"
TEMP_DMG="temp.dmg"
FINAL_DMG="${DMG_DIR}/${DMG_NAME}.dmg"

# Build the app first
echo "🔨 Building Release..."
xcodebuild -project ${APP_NAME}.xcodeproj \
           -scheme ${APP_NAME} \
           -configuration Release \
           -derivedDataPath build \
           clean build

# Find the built app
APP_PATH=$(find build -name "${APP_NAME}.app" -type d | head -1)

if [ -z "$APP_PATH" ]; then
    echo "❌ Error: Could not find built app"
    exit 1
fi

echo "📦 Found app at: $APP_PATH"

# Create dist directory
mkdir -p "${DMG_DIR}"

# Remove old DMG if exists
rm -f "${FINAL_DMG}"
rm -f "${TEMP_DMG}"

# Create a temporary directory for DMG contents
TEMP_DIR=$(mktemp -d)
echo "📁 Temp directory: $TEMP_DIR"

# Copy the app
cp -R "$APP_PATH" "${TEMP_DIR}/"

# Create Applications symlink
ln -s /Applications "${TEMP_DIR}/Applications"

# Create the DMG
echo "💿 Creating DMG..."
hdiutil create -srcfolder "${TEMP_DIR}" \
               -volname "${VOLUME_NAME}" \
               -fs HFS+ \
               -fsargs "-c c=64,a=16,e=16" \
               -format UDRW \
               "${TEMP_DMG}"

# Mount the DMG
echo "🔧 Customizing DMG appearance..."
MOUNT_DIR=$(hdiutil attach -readwrite -noverify "${TEMP_DMG}" | grep -E '^/dev/' | tail -1 | awk '{print $NF}')

if [ -z "$MOUNT_DIR" ]; then
    MOUNT_DIR="/Volumes/${VOLUME_NAME}"
fi

echo "📀 Mounted at: $MOUNT_DIR"

# Wait for mount
sleep 2

# Create background directory
mkdir -p "${MOUNT_DIR}/.background"

# Create a simple background image using Python
python3 << 'PYTHON_SCRIPT'
from PIL import Image, ImageDraw, ImageFont
import os

# Create background image (540x380)
width, height = 540, 380
img = Image.new('RGB', (width, height), color=(30, 30, 35))
draw = ImageDraw.Draw(img)

# Draw gradient-like effect
for y in range(height):
    gray = int(30 + (y / height) * 15)
    draw.line([(0, y), (width, y)], fill=(gray, gray, gray + 5))

# Draw arrow
arrow_y = height // 2
arrow_start = 180
arrow_end = 360

# Arrow body
draw.rectangle([arrow_start, arrow_y - 3, arrow_end - 30, arrow_y + 3], fill=(100, 100, 110))

# Arrow head
draw.polygon([
    (arrow_end - 30, arrow_y - 15),
    (arrow_end, arrow_y),
    (arrow_end - 30, arrow_y + 15)
], fill=(100, 100, 110))

# Draw text
try:
    font = ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", 14)
except:
    font = ImageFont.load_default()

text = "Drag to Applications to install"
bbox = draw.textbbox((0, 0), text, font=font)
text_width = bbox[2] - bbox[0]
draw.text(((width - text_width) // 2, height - 50), text, fill=(150, 150, 160), font=font)

# Save
output_path = os.environ.get('MOUNT_DIR', '/tmp') + '/.background/background.png'
img.save(output_path)
print(f"Background saved to {output_path}")
PYTHON_SCRIPT

# Apply DMG styling using AppleScript
osascript << APPLESCRIPT
tell application "Finder"
    tell disk "${VOLUME_NAME}"
        open
        set current view of container window to icon view
        set toolbar visible of container window to false
        set statusbar visible of container window to false
        set the bounds of container window to {100, 100, 640, 480}
        set viewOptions to the icon view options of container window
        set arrangement of viewOptions to not arranged
        set icon size of viewOptions to 100
        try
            set background picture of viewOptions to file ".background:background.png"
        end try
        set position of item "${APP_NAME}.app" of container window to {130, 180}
        set position of item "Applications" of container window to {410, 180}
        close
        open
        update without registering applications
        delay 2
    end tell
end tell
APPLESCRIPT

# Unmount
echo "📤 Finalizing..."
sync
hdiutil detach "${MOUNT_DIR}" -force || true

# Convert to compressed DMG
hdiutil convert "${TEMP_DMG}" \
                -format UDZO \
                -imagekey zlib-level=9 \
                -o "${FINAL_DMG}"

# Cleanup
rm -f "${TEMP_DMG}"
rm -rf "${TEMP_DIR}"
rm -rf build

echo ""
echo "✅ DMG created successfully!"
echo "📍 Location: ${FINAL_DMG}"
echo ""
echo "File size: $(du -h "${FINAL_DMG}" | cut -f1)"
