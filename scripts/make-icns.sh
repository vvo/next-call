#!/bin/bash
# Rebuilds AppIcon.icns from the generated icon-1024.png
set -e
cd "$(dirname "$0")/.."

swift scripts/icon.swift

ICONSET="AppIcon.iconset"
rm -rf "$ICONSET"
mkdir "$ICONSET"

for s in 16 32 128 256 512; do
    sips -z $s $s icon-1024.png --out "$ICONSET/icon_${s}x${s}.png" >/dev/null
    d=$((s * 2))
    sips -z $d $d icon-1024.png --out "$ICONSET/icon_${s}x${s}@2x.png" >/dev/null
done

iconutil -c icns "$ICONSET" -o AppIcon.icns
rm -rf "$ICONSET" icon-1024.png
echo "wrote AppIcon.icns"
