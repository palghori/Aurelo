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

"$DIR/build/package.sh"

echo "=========================================================="
echo "✨ Aurelo.app build complete!"
echo "📍 Location: $DIR/build/Aurelo.app"
echo "🚀 To launch: open '$DIR/build/Aurelo.app'"
echo "=========================================================="
