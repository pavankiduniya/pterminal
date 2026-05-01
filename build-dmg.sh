#!/bin/bash
set -e

APP_NAME="PTerminal"
BUILD_DIR=".build/release"
APP_BUNDLE="${APP_NAME}.app"
DMG_NAME="${APP_NAME}.dmg"

echo "🔨 Building ${APP_NAME} in release mode..."

# Eject any previously mounted DMG volumes
for vol in /Volumes/${APP_NAME}*; do
    [ -d "$vol" ] && hdiutil detach "$vol" 2>/dev/null || true
done

# Kill any running instance
killall "${APP_NAME}" 2>/dev/null || true

swift build -c release

echo "📦 Creating app bundle..."
rm -rf "${APP_BUNDLE}"
mkdir -p "${APP_BUNDLE}/Contents/MacOS"
mkdir -p "${APP_BUNDLE}/Contents/Resources"

# Copy binary
cp "${BUILD_DIR}/${APP_NAME}" "${APP_BUNDLE}/Contents/MacOS/${APP_NAME}"

# Copy Info.plist
cp Info.plist "${APP_BUNDLE}/Contents/Info.plist"

# Copy app icon
[ -f AppIcon.icns ] && cp AppIcon.icns "${APP_BUNDLE}/Contents/Resources/AppIcon.icns"

echo "✅ App bundle created: ${APP_BUNDLE}"

# Create DMG
echo "💿 Creating DMG..."
rm -f "${DMG_NAME}"

# Create a temporary directory for DMG contents
DMG_TEMP="dmg_temp"
rm -rf "${DMG_TEMP}"
mkdir -p "${DMG_TEMP}"
cp -R "${APP_BUNDLE}" "${DMG_TEMP}/"

# Create a symlink to /Applications for drag-and-drop install
ln -s /Applications "${DMG_TEMP}/Applications"

# Create the DMG
hdiutil create -volname "${APP_NAME}" \
    -srcfolder "${DMG_TEMP}" \
    -ov -format UDZO \
    "${DMG_NAME}"

# Cleanup
rm -rf "${DMG_TEMP}"

echo ""
echo "🎉 Done! Your DMG is ready:"
echo "   $(pwd)/${DMG_NAME}"
echo ""
echo "Double-click the DMG to mount it, then drag PTerminal to Applications."
