#!/bin/bash
set -e

# Change directory to script's own path
cd "$(dirname "$0")"

echo "🧹 Cleaning previous builds..."
rm -rf .build
rm -rf MacDiff.app

echo "🚀 Building executable via Swift Package Manager (Release configuration)..."
swift build -c release

echo "📦 Packaging MacDiff.app bundle..."
mkdir -p MacDiff.app/Contents/MacOS
cp .build/release/MacDiff MacDiff.app/Contents/MacOS/MacDiff
cp MacDiff/Info.plist MacDiff.app/Contents/Info.plist

chmod +x MacDiff.app/Contents/MacOS/MacDiff

echo "✅ Success! MacDiff.app has been created in: $(pwd)/MacDiff.app"
