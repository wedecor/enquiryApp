#!/bin/bash

# Script to create OAuth 2.0 client IDs for We Decor Enquiries
# Make sure you're authenticated: gcloud auth login

set -e

PROJECT_ID="wedecorenquries"
WEB_NAME="We Decor Enquiries Web"
ANDROID_NAME="We Decor Enquiries Android"
IOS_NAME="We Decor Enquiries iOS"
ANDROID_PACKAGE="com.example.we_decor_enquiries"
IOS_BUNDLE="com.example.weDecorEnquiries"

echo "🚀 Creating OAuth Client IDs for project: $PROJECT_ID"
echo ""

# Set the project
gcloud config set project $PROJECT_ID

# 1. Create Web Application OAuth Client
echo "📱 Creating Web Application OAuth Client..."
WEB_CLIENT=$(gcloud alpha iap oauth-clients create \
  --display_name="$WEB_NAME" \
  --format="value(name)" 2>/dev/null || \
gcloud alpha iap oauth-clients create \
  --display_name="$WEB_NAME" \
  --format="value(name)")

if [ -z "$WEB_CLIENT" ]; then
  echo "⚠️  Web client creation failed, trying alternative method..."
  # Alternative: Use gcloud auth application-default login and create via API
  echo "Please create Web client manually via console or use:"
  echo "gcloud alpha iap oauth-clients create --display_name='$WEB_NAME'"
else
  echo "✅ Web client created: $WEB_CLIENT"
fi

# Note: gcloud doesn't have a direct command to create OAuth clients
# We need to use the REST API or console
echo ""
echo "⚠️  Note: gcloud CLI doesn't have a direct command to create OAuth 2.0 client IDs."
echo "   You have two options:"
echo ""
echo "Option 1: Use Google Cloud Console (Recommended)"
echo "   1. Go to: https://console.cloud.google.com/apis/credentials?project=$PROJECT_ID"
echo "   2. Click 'Create Credentials' > 'OAuth client ID'"
echo "   3. Create Web, Android, and iOS clients"
echo ""
echo "Option 2: Use REST API (requires authentication)"
echo "   See: https://cloud.google.com/iam/docs/reference/rest/v1/projects.locations.oauthClients/create"
echo ""
echo "📋 Details needed:"
echo ""
echo "Web Application:"
echo "  - Name: $WEB_NAME"
echo "  - Authorized JavaScript origins:"
echo "    * http://localhost:5000"
echo "    * https://wedecorenquries.web.app"
echo "    * https://wedecorenquries.firebaseapp.com"
echo "  - Authorized redirect URIs:"
echo "    * http://localhost:5000"
echo "    * https://wedecorenquries.web.app"
echo "    * https://wedecorenquries.firebaseapp.com"
echo ""
echo "Android Application:"
echo "  - Name: $ANDROID_NAME"
echo "  - Package name: $ANDROID_PACKAGE"
echo "  - SHA-1 fingerprint: (get from: keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android)"
echo ""
echo "iOS Application:"
echo "  - Name: $IOS_NAME"
echo "  - Bundle ID: $IOS_BUNDLE"
echo ""
