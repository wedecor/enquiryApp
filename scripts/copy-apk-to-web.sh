#!/bin/bash

# Script to copy APK to build/web/android directory for Firebase Hosting

set -e

echo "📱 Copying APK to web build directory..."

# Create android directory in build/web if it doesn't exist
mkdir -p build/web/android

# Copy APK from android directory
if [ -f "android/app-release.apk" ]; then
    cp android/app-release.apk build/web/android/app-release.apk
    echo "✅ APK copied successfully"
    
    # Get APK size
    APK_SIZE=$(ls -lh android/app-release.apk | awk '{print $5}')
    echo "   Size: $APK_SIZE"
else
    echo "⚠️  Warning: android/app-release.apk not found"
    echo "   Building APK first..."
    flutter build apk --release
    cp build/app/outputs/flutter-apk/app-release.apk android/app-release.apk
    cp android/app-release.apk build/web/android/app-release.apk
    echo "✅ APK built and copied successfully"
fi

# Ensure index.html exists
if [ ! -f "build/web/android/index.html" ]; then
    echo "📄 Creating index.html..."
    cat > build/web/android/index.html << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Download We Decor Enquiries APK</title>
    <style>
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, sans-serif;
            display: flex;
            justify-content: center;
            align-items: center;
            min-height: 100vh;
            margin: 0;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: #333;
        }
        .container {
            background: white;
            padding: 2rem;
            border-radius: 12px;
            box-shadow: 0 10px 40px rgba(0,0,0,0.2);
            text-align: center;
            max-width: 500px;
        }
        h1 {
            margin-top: 0;
            color: #667eea;
        }
        .download-btn {
            display: inline-block;
            padding: 1rem 2rem;
            background: #667eea;
            color: white;
            text-decoration: none;
            border-radius: 8px;
            font-size: 1.1rem;
            font-weight: 600;
            margin-top: 1.5rem;
            transition: transform 0.2s, box-shadow 0.2s;
        }
        .download-btn:hover {
            transform: translateY(-2px);
            box-shadow: 0 5px 15px rgba(102, 126, 234, 0.4);
        }
        .info {
            margin-top: 1.5rem;
            color: #666;
            font-size: 0.9rem;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>📱 We Decor Enquiries</h1>
        <p>Download the Android app</p>
        <a href="app-release.apk" class="download-btn" download>Download APK</a>
        <div class="info">
            <p><strong>Version:</strong> 2.0.5 (Build 29)</p>
            <p><strong>Size:</strong> ~59 MB</p>
            <p style="margin-top: 1rem; font-size: 0.85rem; color: #999;">
                After downloading, enable "Install from unknown sources" in your Android settings to install the APK.
            </p>
        </div>
    </div>
</body>
</html>
EOF
    echo "✅ index.html created"
fi

echo "✅ APK setup complete for web deployment"

