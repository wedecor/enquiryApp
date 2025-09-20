#!/bin/bash

# Android Bug Report Collection Script
# Generates comprehensive device bug report for detailed analysis

set -e

TIMESTAMP=$(date +%F_%H-%M)
BUGREPORT_DIR="build/bugreports"

echo "🐛 Android Bug Report Collection - We Decor Enquiries QA"
echo "⏰ Timestamp: $TIMESTAMP"

# Create bugreport directory
mkdir -p "$BUGREPORT_DIR"

# Check if device is connected
echo "🔍 Checking connected devices..."
if ! adb devices | grep -q "device$"; then
    echo "❌ No Android device connected"
    echo "💡 Connect device and enable USB debugging"
    exit 1
fi

DEVICE_MODEL=$(adb shell getprop ro.product.model | tr -d '\r')
ANDROID_VERSION=$(adb shell getprop ro.build.version.release | tr -d '\r')
echo "📱 Device: $DEVICE_MODEL (Android $ANDROID_VERSION)"

# Generate bug report
echo "📋 Generating comprehensive bug report..."
echo "⏳ This may take 2-3 minutes..."

BUGREPORT_FILE="$BUGREPORT_DIR/bugreport_${DEVICE_MODEL// /_}_$TIMESTAMP"

# Use newer bugreport format if available
if adb bugreport --help 2>/dev/null | grep -q "output"; then
    # Android 7.0+ format
    adb bugreport "$BUGREPORT_FILE.zip"
    echo "✅ Bug report saved: $BUGREPORT_FILE.zip"
else
    # Legacy format
    adb bugreport > "$BUGREPORT_FILE.txt"
    echo "✅ Bug report saved: $BUGREPORT_FILE.txt"
fi

# Collect additional app-specific information
echo "📱 Collecting app-specific diagnostics..."
{
    echo "=== APP PACKAGE INFO ==="
    adb shell dumpsys package com.example.we_decor_enquiries | grep -A 20 "Package \["
    echo ""
    
    echo "=== APP PERMISSIONS ==="
    adb shell dumpsys package com.example.we_decor_enquiries | grep -A 10 "requested permissions"
    echo ""
    
    echo "=== APP ACTIVITIES ==="
    adb shell dumpsys activity activities | grep -A 5 "we_decor_enquiries"
    echo ""
    
    echo "=== APP SERVICES ==="
    adb shell dumpsys activity services | grep -A 5 "we_decor_enquiries"
    echo ""
    
    echo "=== NETWORK STATE ==="
    adb shell dumpsys connectivity | grep -A 5 "Active default network"
    echo ""
    
} > "$BUGREPORT_DIR/app_diagnostics_$TIMESTAMP.txt"

# Collect crash logs if available
echo "💥 Checking for crash logs..."
adb shell ls /data/tombstones/ 2>/dev/null | head -5 > "$BUGREPORT_DIR/tombstones_$TIMESTAMP.txt" || echo "No tombstones found" > "$BUGREPORT_DIR/tombstones_$TIMESTAMP.txt"

echo ""
echo "✅ Bug report collection completed!"
echo "📁 Files created in $BUGREPORT_DIR/:"
ls -lh "$BUGREPORT_DIR/"*"$TIMESTAMP"*

echo ""
echo "📋 Next steps:"
echo "1. Attach bug report files to GitHub issue"
echo "2. Include device model and Android version in bug report"
echo "3. Describe steps to reproduce the issue"
echo "4. Add screenshots or screen recordings if applicable"
