#!/bin/bash

# Exit on any error
set -e

echo "🚀 Starting Firebase Emulator Suite..."

# Start Firebase emulators in the background
firebase emulators:start --only auth,firestore,storage &
EMULATOR_PID=$!

# Wait for emulators to start
echo "⏳ Waiting for emulators to start..."
sleep 10

# Check if emulators are running
if ! curl -s http://localhost:4000 > /dev/null; then
    echo "❌ Firebase emulators failed to start"
    kill $EMULATOR_PID 2>/dev/null || true
    exit 1
fi

echo "✅ Firebase emulators started successfully"

# Run integration tests
echo "🧪 Running integration tests..."
flutter test integration_test/app_test.dart

# Clean up
echo "🧹 Cleaning up..."
kill $EMULATOR_PID 2>/dev/null || true

echo "✅ Integration tests completed!" 