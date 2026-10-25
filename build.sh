#!/bin/bash
set -e

DIR="$(cd "$(dirname "$0")" && pwd)"
echo "==> Building Aurelo for Apple Silicon (ARM64)..."

mkdir -p "$DIR/build"

swiftc -O -target arm64-apple-macos13.0 \
    "$DIR/Sources/"*.swift \
    "$DIR/Sources/Models/"*.swift \
    "$DIR/Sources/Engine/"*.swift \
    "$DIR/Sources/Views/"*.swift \
    -o "$DIR/build/Aurelo_bin"

APP_BUNDLE="$DIR/build/Aurelo.app"
CONTENTS="$APP_BUNDLE/Contents"
MACOS="$CONTENTS/MacOS"
RESOURCES="$CONTENTS/Resources"

echo "==> Creating Aurelo.app bundle..."
rm -rf "$APP_BUNDLE"
mkdir -p "$MACOS"
mkdir -p "$RESOURCES"

echo "==> Copying binary..."
cp "$DIR/build/Aurelo_bin" "$MACOS/Aurelo"
chmod +x "$MACOS/Aurelo"

echo "==> Creating PkgInfo..."
echo "APPLAURL" > "$CONTENTS/PkgInfo"

echo "==> Creating Info.plist..."
cat << 'EOF' > "$CONTENTS/Info.plist"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>CFBundleDevelopmentRegion</key>
	<string>en</string>
	<key>CFBundleDisplayName</key>
	<string>Aurelo</string>
	<key>CFBundleExecutable</key>
	<string>Aurelo</string>
	<key>CFBundleIconFile</key>
	<string>AppIcon</string>
	<key>CFBundleIdentifier</key>
	<string>com.palghori.Aurelo</string>
	<key>CFBundleInfoDictionaryVersion</key>
	<string>6.0</string>
	<key>CFBundleName</key>
	<string>Aurelo</string>
	<key>CFBundlePackageType</key>
	<string>APPL</string>
	<key>CFBundleShortVersionString</key>
	<string>1.0.0</string>
	<key>CFBundleVersion</key>
	<string>1</string>
	<key>LSApplicationCategoryType</key>
	<string>public.app-category.utilities</string>
	<key>LSMinimumSystemVersion</key>
	<string>13.0</string>
	<key>NSPrincipalClass</key>
	<string>NSApplication</string>
	<key>NSHighResolutionCapable</key>
	<true/>
</dict>
</plist>
EOF

if [ -f "$DIR/Resources/AppIcon.icns" ]; then
    echo "==> Bundling AppIcon.icns..."
    cp "$DIR/Resources/AppIcon.icns" "$RESOURCES/AppIcon.icns"
fi

if [ -d "$DIR/Resources/Tools" ]; then
    echo "==> Bundling engine tools (ffmpeg, cwebp)..."
    cp -R "$DIR/Resources/Tools" "$RESOURCES/Tools"
fi

echo "==> Ad-hoc code signing Aurelo.app..."
codesign --force --deep --sign - "$APP_BUNDLE" 2>/dev/null || true

echo "=========================================================="
echo "✨ Aurelo.app build complete!"
echo "📍 Location: $APP_BUNDLE"
echo "🚀 To launch: open '$APP_BUNDLE'"
echo "=========================================================="
