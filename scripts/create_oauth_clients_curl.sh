#!/bin/bash

# Script to create OAuth 2.0 client IDs using Google Cloud REST API
# Requires: gcloud CLI installed and authenticated

set -e

PROJECT_ID="wedecorenquries"

echo "🚀 Creating OAuth Client IDs for project: $PROJECT_ID"
echo ""

# Check if gcloud is authenticated
if ! gcloud auth print-access-token &>/dev/null; then
    echo "❌ Not authenticated. Please run:"
    echo "   gcloud auth login"
    exit 1
fi

# Get access token
ACCESS_TOKEN=$(gcloud auth print-access-token)
echo "✅ Authenticated"

# Set project
gcloud config set project $PROJECT_ID

echo ""
echo "📱 Creating Web Application OAuth Client..."

# Create Web Application OAuth Client
WEB_RESPONSE=$(curl -s -X POST \
  "https://iam.googleapis.com/v1/projects/$PROJECT_ID/locations/global/oauthClients" \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "displayName": "We Decor Enquiries Web",
    "web": {
      "redirectUris": [
        "http://localhost:5000",
        "https://wedecorenquries.web.app",
        "https://wedecorenquries.firebaseapp.com"
      ],
      "javascriptOrigins": [
        "http://localhost:5000",
        "https://wedecorenquries.web.app",
        "https://wedecorenquries.firebaseapp.com"
      ]
    }
  }' 2>&1)

if echo "$WEB_RESPONSE" | grep -q "clientId"; then
    WEB_CLIENT_ID=$(echo "$WEB_RESPONSE" | grep -o '"clientId":"[^"]*"' | cut -d'"' -f4)
    echo "✅ Web Client created: $WEB_CLIENT_ID"
else
    echo "❌ Failed to create Web client"
    echo "Response: $WEB_RESPONSE"
fi

echo ""
echo "📱 Creating Android Application OAuth Client..."
echo "⚠️  Note: You need to provide SHA-1 fingerprint"
echo "   Get it with: keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android"
echo ""
read -p "Enter SHA-1 fingerprint (or press Enter to skip): " SHA1

if [ -n "$SHA1" ]; then
    ANDROID_RESPONSE=$(curl -s -X POST \
      "https://iam.googleapis.com/v1/projects/$PROJECT_ID/locations/global/oauthClients" \
      -H "Authorization: Bearer $ACCESS_TOKEN" \
      -H "Content-Type: application/json" \
      -d "{
        \"displayName\": \"We Decor Enquiries Android\",
        \"android\": {
          \"packageName\": \"com.example.we_decor_enquiries\",
          \"sha1Fingerprints\": [\"$SHA1\"]
        }
      }" 2>&1)
    
    if echo "$ANDROID_RESPONSE" | grep -q "clientId"; then
        ANDROID_CLIENT_ID=$(echo "$ANDROID_RESPONSE" | grep -o '"clientId":"[^"]*"' | cut -d'"' -f4)
        echo "✅ Android Client created: $ANDROID_CLIENT_ID"
    else
        echo "❌ Failed to create Android client"
        echo "Response: $ANDROID_RESPONSE"
    fi
else
    echo "⏭️  Skipping Android client"
fi

echo ""
echo "📱 Creating iOS Application OAuth Client..."

IOS_RESPONSE=$(curl -s -X POST \
  "https://iam.googleapis.com/v1/projects/$PROJECT_ID/locations/global/oauthClients" \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "displayName": "We Decor Enquiries iOS",
    "ios": {
      "bundleId": "com.example.weDecorEnquiries"
    }
  }' 2>&1)

if echo "$IOS_RESPONSE" | grep -q "clientId"; then
    IOS_CLIENT_ID=$(echo "$IOS_RESPONSE" | grep -o '"clientId":"[^"]*"' | cut -d'"' -f4)
    echo "✅ iOS Client created: $IOS_CLIENT_ID"
else
    echo "❌ Failed to create iOS client"
    echo "Response: $IOS_RESPONSE"
fi

echo ""
echo "✅ Done! OAuth clients created."
echo ""
echo "📋 Client IDs created:"
[ -n "$WEB_CLIENT_ID" ] && echo "   Web: $WEB_CLIENT_ID"
[ -n "$ANDROID_CLIENT_ID" ] && echo "   Android: $ANDROID_CLIENT_ID"
[ -n "$IOS_CLIENT_ID" ] && echo "   iOS: $IOS_CLIENT_ID"

