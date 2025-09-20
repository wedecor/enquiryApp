#!/bin/bash

# Android Log Collection Script for QA Testing
# Collects app logs, system performance, and device info

set -e

TIMESTAMP=$(date +%F_%H-%M)
LOG_DIR="logs"
PACKAGE_NAME="com.example.we_decor_enquiries"

echo "📱 Android Log Collection - We Decor Enquiries QA"
echo "⏰ Timestamp: $TIMESTAMP"

# Create logs directory
mkdir -p "$LOG_DIR"

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

# Collect device information
echo "📋 Collecting device information..."
adb shell getprop > "$LOG_DIR/device_props_$TIMESTAMP.txt"

# Collect system information
echo "🔧 Collecting system information..."
{
    echo "=== DEVICE INFO ==="
    echo "Model: $DEVICE_MODEL"
    echo "Android: $ANDROID_VERSION"
    echo "Timestamp: $(date)"
    echo ""
    
    echo "=== MEMORY INFO ==="
    adb shell cat /proc/meminfo | head -10
    echo ""
    
    echo "=== STORAGE INFO ==="
    adb shell df -h | grep -E "(data|system|cache)"
    echo ""
    
    echo "=== BATTERY INFO ==="
    adb shell dumpsys battery | grep -E "(level|status|health)"
    echo ""
} > "$LOG_DIR/system_info_$TIMESTAMP.txt"

# Collect app-specific logs
echo "📱 Collecting app logs (press Ctrl+C to stop)..."
echo "💡 Reproduce the issue now, then stop this script"

# Start logcat with app filter
adb logcat -v time "$PACKAGE_NAME:V" "*:S" | tee "$LOG_DIR/app_log_$TIMESTAMP.txt" &
LOGCAT_PID=$!

# Monitor app memory usage
echo "📊 Monitoring app performance..."
{
    echo "=== APP MEMORY USAGE ==="
    adb shell dumpsys meminfo "$PACKAGE_NAME"
    echo ""
    
    echo "=== APP PROCESSES ==="
    adb shell ps | grep "$PACKAGE_NAME"
    echo ""
} > "$LOG_DIR/app_memory_$TIMESTAMP.txt" &

# Wait for user to stop
echo ""
echo "🎯 Log collection started. Reproduce the issue, then press Ctrl+C to stop."
echo "📁 Logs will be saved to: $LOG_DIR/"

# Wait for interrupt
trap "echo ''; echo '⏹️ Stopping log collection...'; kill $LOGCAT_PID 2>/dev/null; exit 0" INT
wait $LOGCAT_PID

echo "✅ Log collection completed!"
echo "📁 Files created:"
ls -lh "$LOG_DIR/"*"$TIMESTAMP"*
