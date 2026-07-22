#!/bin/bash
# Builds SubtitleShade.app from SubtitleShade.swift.
# Requires the Xcode Command Line Tools (run: xcode-select --install).
set -e

DIR="$(cd "$(dirname "$0")" && pwd)"
APP="$DIR/SubtitleShade.app"

if ! command -v swiftc >/dev/null 2>&1; then
    echo "swiftc not found. Install the Xcode Command Line Tools:"
    echo "    xcode-select --install"
    exit 1
fi

echo "Compiling..."
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS"
BIN="$APP/Contents/MacOS/SubtitleShade"

# Try a universal binary (Apple Silicon + Intel) so it runs on any Mac;
# fall back to a native-only build if one of the SDK slices is missing.
if swiftc -O -target arm64-apple-macosx11.0   -o "$BIN.arm64" "$DIR/SubtitleShade.swift" 2>/dev/null \
&& swiftc -O -target x86_64-apple-macosx10.13 -o "$BIN.x86_64" "$DIR/SubtitleShade.swift" 2>/dev/null; then
    lipo -create -output "$BIN" "$BIN.arm64" "$BIN.x86_64"
    rm -f "$BIN.arm64" "$BIN.x86_64"
    echo "  (universal binary: arm64 + x86_64)"
else
    rm -f "$BIN.arm64" "$BIN.x86_64"
    swiftc -O -o "$BIN" "$DIR/SubtitleShade.swift"
    echo "  (native binary for this Mac)"
fi

cat > "$APP/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>            <string>SubtitleShade</string>
    <key>CFBundleDisplayName</key>     <string>SubtitleShade</string>
    <key>CFBundleExecutable</key>      <string>SubtitleShade</string>
    <key>CFBundleIdentifier</key>      <string>com.subtitleshade.app</string>
    <key>CFBundleVersion</key>         <string>1.0</string>
    <key>CFBundleShortVersionString</key><string>1.0</string>
    <key>CFBundlePackageType</key>     <string>APPL</string>
    <key>LSMinimumSystemVersion</key>  <string>10.13</string>
    <key>NSHighResolutionCapable</key> <true/>
</dict>
</plist>
PLIST

echo "Build OK -> SubtitleShade.app"
echo
echo "First launch: macOS Gatekeeper will block an unsigned app."
echo "Right-click SubtitleShade.app -> Open -> Open, or run:"
echo "    xattr -dr com.apple.quarantine \"$APP\""
