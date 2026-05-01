#!/bin/bash
set -e
killall PTerminal 2>/dev/null || true
swift build -c release
# Create app bundle
rm -rf PTerminal.app
mkdir -p PTerminal.app/Contents/MacOS
mkdir -p PTerminal.app/Contents/Resources
cp .build/release/PTerminal PTerminal.app/Contents/MacOS/PTerminal
cp Info.plist PTerminal.app/Contents/Info.plist
[ -f AppIcon.icns ] && cp AppIcon.icns PTerminal.app/Contents/Resources/AppIcon.icns
open PTerminal.app
