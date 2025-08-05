#!/bin/bash

# Build script for Flutter web with environment variables
# This script ensures API keys are properly handled during build

set -e

echo "🔒 Building Flutter web app with secure environment variables..."

# Check if required environment variables are set
if [ -z "$NEXT_PUBLIC_GOOGLE_API_KEY" ] && [ -z "$FIREBASE_API_KEY" ]; then
    echo "⚠️  WARNING: No Firebase API key environment variables found!"
    echo "   Set NEXT_PUBLIC_GOOGLE_API_KEY or FIREBASE_API_KEY for production builds"
    echo "   Using placeholder values for development..."
fi

# Clean previous build
echo "🧹 Cleaning previous build..."
flutter clean

# Get dependencies
echo "📦 Getting dependencies..."
flutter pub get

# Build web app
echo "🏗️  Building web app..."
flutter build web --release

# Replace placeholder API keys with environment variables if available
if [ ! -z "$NEXT_PUBLIC_GOOGLE_API_KEY" ]; then
    echo "🔑 Injecting API key from environment variables..."
    
    # Replace placeholder in the built JavaScript files
    find build/web -name "*.js" -type f -exec sed -i '' "s/WEB_API_KEY_FROM_ENV/$NEXT_PUBLIC_GOOGLE_API_KEY/g" {} \;
    find build/web -name "*.js" -type f -exec sed -i '' "s/MOBILE_API_KEY_FROM_ENV/$NEXT_PUBLIC_GOOGLE_API_KEY/g" {} \;
    
    echo "✅ API key injected successfully"
else
    echo "⚠️  No API key provided - using placeholder values"
fi

echo "✅ Build completed successfully!"
echo "📁 Output directory: build/web"
echo "🚀 Ready for deployment to Vercel" 