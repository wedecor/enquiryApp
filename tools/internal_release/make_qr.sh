#!/bin/bash

# QR Code Generator for APK Download
# Requires: qrencode (install with: brew install qrencode)

APK_URL="https://your-domain.com/internal/2024-rc1/app-release.apk"
OUTPUT_FILE="qr.png"

echo "🔗 Generating QR code for: $APK_URL"

if command -v qrencode &> /dev/null; then
    # Generate QR code with qrencode
    qrencode -s 8 -m 2 -o "$OUTPUT_FILE" "$APK_URL"
    echo "✅ QR code generated: $OUTPUT_FILE"
    
    # Display QR code in terminal (if supported)
    if command -v qrencode &> /dev/null; then
        echo "📱 QR Code (scan with phone):"
        qrencode -t ansiutf8 "$APK_URL"
    fi
else
    echo "❌ qrencode not found. Install with:"
    echo "  macOS: brew install qrencode"
    echo "  Ubuntu: sudo apt-get install qrencode"
    echo ""
    echo "🌐 Alternatively, use online QR generator:"
    echo "  URL: $APK_URL"
    exit 1
fi

echo ""
echo "📋 Next steps:"
echo "1. Update APK_URL in this script with your hosting URL"
echo "2. Replace QR placeholder in index.html with generated qr.png"
echo "3. Upload APK, checksum, and HTML to your hosting service"
