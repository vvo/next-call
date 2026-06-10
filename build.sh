#!/bin/bash
set -e

BUILD_DIR=".build"
BUNDLE_NAME="Next Call.app"

echo "Building NextCall..."
swift build -c release

echo "Creating app bundle..."
rm -rf "./$BUNDLE_NAME"
mkdir -p "$BUNDLE_NAME/Contents/MacOS"
mkdir -p "$BUNDLE_NAME/Contents/Resources"

cp "$BUILD_DIR/release/NextCall" "$BUNDLE_NAME/Contents/MacOS/"
cp Info.plist "$BUNDLE_NAME/Contents/"
cp AppIcon.icns "$BUNDLE_NAME/Contents/Resources/"

# SPM resource bundle (provider logos)
if [ -d "$BUILD_DIR/release/NextCall_NextCall.bundle" ]; then
    cp -R "$BUILD_DIR/release/NextCall_NextCall.bundle" "$BUNDLE_NAME/Contents/Resources/"
fi

echo "Code signing (ad-hoc)..."
codesign --force --deep --sign - "$BUNDLE_NAME"

echo ""
echo "Build complete: $BUNDLE_NAME"
echo "Run with:  open '$BUNDLE_NAME'"
echo "On first run, grant calendar access when prompted."
