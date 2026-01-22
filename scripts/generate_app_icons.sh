#!/bin/bash

# Script to generate app icons from a source image
# Usage: ./scripts/generate_app_icons.sh /path/to/source/icon.png

set -e

SOURCE_IMAGE="$1"

if [ -z "$SOURCE_IMAGE" ]; then
    echo "❌ Error: Please provide a source image path"
    echo "Usage: ./scripts/generate_app_icons.sh /path/to/icon.png"
    exit 1
fi

if [ ! -f "$SOURCE_IMAGE" ]; then
    echo "❌ Error: Source image not found: $SOURCE_IMAGE"
    exit 1
fi

echo "🎨 Generating app icons from: $SOURCE_IMAGE"
echo ""

# Create directories if they don't exist
mkdir -p android/app/src/main/res/mipmap-mdpi
mkdir -p android/app/src/main/res/mipmap-hdpi
mkdir -p android/app/src/main/res/mipmap-xhdpi
mkdir -p android/app/src/main/res/mipmap-xxhdpi
mkdir -p android/app/src/main/res/mipmap-xxxhdpi
mkdir -p web/icons
mkdir -p ios/Runner/Assets.xcassets/AppIcon.appiconset
mkdir -p macos/Runner/Assets.xcassets/AppIcon.appiconset

# Check if sips is available (macOS)
if command -v sips &> /dev/null; then
    echo "✅ Using macOS sips tool"
    
    # Android icons
    echo "📱 Generating Android icons..."
    sips -z 48 48 "$SOURCE_IMAGE" --out android/app/src/main/res/mipmap-mdpi/ic_launcher.png
    sips -z 72 72 "$SOURCE_IMAGE" --out android/app/src/main/res/mipmap-hdpi/ic_launcher.png
    sips -z 96 96 "$SOURCE_IMAGE" --out android/app/src/main/res/mipmap-xhdpi/ic_launcher.png
    sips -z 144 144 "$SOURCE_IMAGE" --out android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png
    sips -z 192 192 "$SOURCE_IMAGE" --out android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png
    
    # Web icons
    echo "🌐 Generating Web icons..."
    sips -z 192 192 "$SOURCE_IMAGE" --out web/icons/Icon-192.png
    sips -z 512 512 "$SOURCE_IMAGE" --out web/icons/Icon-512.png
    sips -z 192 192 "$SOURCE_IMAGE" --out web/icons/Icon-maskable-192.png
    sips -z 512 512 "$SOURCE_IMAGE" --out web/icons/Icon-maskable-512.png
    sips -z 64 64 "$SOURCE_IMAGE" --out web/favicon.png
    
    # Copy to public/web for deployment
    cp web/icons/*.png public/web/icons/ 2>/dev/null || true
    cp web/favicon.png public/web/favicon.png 2>/dev/null || true
    
    # iOS icons (various sizes)
    echo "🍎 Generating iOS icons..."
    sips -z 40 40 "$SOURCE_IMAGE" --out ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@1x.png
    sips -z 80 80 "$SOURCE_IMAGE" --out ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@2x.png
    sips -z 120 120 "$SOURCE_IMAGE" --out ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@3x.png
    sips -z 60 60 "$SOURCE_IMAGE" --out ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-60x60@1x.png
    sips -z 120 120 "$SOURCE_IMAGE" --out ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-60x60@2x.png
    sips -z 180 180 "$SOURCE_IMAGE" --out ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-60x60@3x.png
    sips -z 29 29 "$SOURCE_IMAGE" --out ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@1x.png
    sips -z 58 58 "$SOURCE_IMAGE" --out ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@2x.png
    sips -z 87 87 "$SOURCE_IMAGE" --out ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@3x.png
    sips -z 20 20 "$SOURCE_IMAGE" --out ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@1x.png
    sips -z 40 40 "$SOURCE_IMAGE" --out ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@2x.png
    sips -z 60 60 "$SOURCE_IMAGE" --out ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@3x.png
    sips -z 76 76 "$SOURCE_IMAGE" --out ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-76x76@1x.png
    sips -z 152 152 "$SOURCE_IMAGE" --out ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-76x76@2x.png
    sips -z 167 167 "$SOURCE_IMAGE" --out ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-83.5x83.5@2x.png
    sips -z 1024 1024 "$SOURCE_IMAGE" --out ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png
    
    # macOS icons
    echo "💻 Generating macOS icons..."
    sips -z 16 16 "$SOURCE_IMAGE" --out macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_16.png
    sips -z 32 32 "$SOURCE_IMAGE" --out macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_32.png
    sips -z 64 64 "$SOURCE_IMAGE" --out macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_64.png
    sips -z 128 128 "$SOURCE_IMAGE" --out macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_128.png
    sips -z 256 256 "$SOURCE_IMAGE" --out macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_256.png
    sips -z 512 512 "$SOURCE_IMAGE" --out macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_512.png
    sips -z 1024 1024 "$SOURCE_IMAGE" --out macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_1024.png
    
    echo ""
    echo "✅ All icons generated successfully!"
    echo ""
    echo "📱 Android icons: android/app/src/main/res/mipmap-*/ic_launcher.png"
    echo "🌐 Web icons: web/icons/"
    echo "🍎 iOS icons: ios/Runner/Assets.xcassets/AppIcon.appiconset/"
    echo "💻 macOS icons: macos/Runner/Assets.xcassets/AppIcon.appiconset/"
    
else
    echo "❌ Error: Image processing tool not found"
    echo "Please install ImageMagick or use macOS (which has sips built-in)"
    echo ""
    echo "Alternative: Use online tools like:"
    echo "  - https://www.appicon.co/"
    echo "  - https://icon.kitchen/"
    exit 1
fi

