#!/bin/bash

# Script to copy APK to build/web/android directory for Firebase Hosting

set -e

echo "📱 Copying APK to web build directory..."

mkdir -p build/web/android

SRC="build/app/outputs/flutter-apk/app-release.apk"
if [ ! -f "$SRC" ]; then
    echo "❌ APK not found at $SRC"
    echo "   Build it first: flutter build apk --release (with the release keystore)"
    exit 1
fi

# Versioned filename from version.json (avoids Chrome reusing an old Downloads/app-release.apk)
VERSION_JSON="public/android/version.json"
APK_NAME="app-release.apk"
if [ -f "$VERSION_JSON" ]; then
  APK_NAME=$(node -e '
    const j=require("./public/android/version.json");
    const v=j.version||"0";
    const b=j.buildNumber||0;
    console.log(`we-decor-enquiries-${v}-${b}.apk`);
  ')
fi

cp "$SRC" "build/web/android/$APK_NAME"
cp "$SRC" "build/web/android/app-release.apk"
cp "$SRC" "public/android/$APK_NAME"
cp "$SRC" "public/android/app-release.apk"

# Point downloadUrl at the versioned file
if [ -f "$VERSION_JSON" ]; then
  node -e '
    const fs=require("fs");
    const p="public/android/version.json";
    const j=JSON.parse(fs.readFileSync(p,"utf8"));
    const name=process.argv[1];
    j.downloadUrl="https://wedecorenquries.web.app/android/"+name;
    fs.writeFileSync(p, JSON.stringify(j,null,2)+"\n");
    fs.copyFileSync(p, "build/web/android/version.json");
  ' "$APK_NAME"
fi

APK_SIZE=$(ls -lh "$SRC" | awk '{print $5}')
echo "✅ APK copied as $APK_NAME and app-release.apk ($APK_SIZE)"

if [ -f "public/android/index.html" ]; then
    cp public/android/index.html build/web/android/index.html
    echo "✅ Detailed index.html copied from public/android/"
else
    echo "📄 Creating simple index.html..."
    cat > build/web/android/index.html << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Download We Decor Enquiries APK</title>
</head>
<body>
    <h1>We Decor Enquiries</h1>
    <p><a id="apkLink" href="app-release.apk">Download APK</a></p>
    <script>
      fetch('version.json').then(r=>r.json()).then(v=>{
        document.getElementById('apkLink').href = v.downloadUrl;
      });
    </script>
</body>
</html>
EOF
fi

echo "✅ APK setup complete for web deployment"
