#!/bin/bash
set -e

DIR="$(cd "$(dirname "$0")" && pwd)"
echo "==> Compiling and running Aurelo 25-Feature Test Suite..."

mkdir -p "$DIR/build"

swiftc -O -target arm64-apple-macos13.0 \
    "$DIR/Sources/Theme.swift" \
    "$DIR/Sources/Models/Format.swift" \
    "$DIR/Sources/Engine/ProcessingEngine.swift" \
    "$DIR/Tests/test_engine.swift" \
    -o "$DIR/build/test_engine_bin"

"$DIR/build/test_engine_bin"
