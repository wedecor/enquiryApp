#!/bin/bash

# Complete Firebase Storage Setup Script
# Run this AFTER enabling Firebase Storage in Firebase Console

set -e

echo "🚀 Complete Firebase Storage Setup"
echo "=================================="
echo ""

# Set Python path
export CLOUDSDK_PYTHON=$(which python3)

# Paths
GCLOUD_PATH="/opt/homebrew/share/google-cloud-sdk/bin"
GSUTIL="$GCLOUD_PATH/gsutil"
GCLOUD="$GCLOUD_PATH/gcloud"
PROJECT_ID="wedecorenquries"
BUCKET_NAME="${PROJECT_ID}.appspot.com"

# Step 1: Set project
echo "📋 Step 1: Setting project..."
$GCLOUD config set project $PROJECT_ID --quiet

# Step 2: Check authentication
echo ""
echo "🔐 Step 2: Checking authentication..."
if ! $GCLOUD auth list --filter=status:ACTIVE --format="value(account)" | grep -q .; then
    echo "❌ Not authenticated. Please run:"
    echo "   $GCLOUD auth login"
    exit 1
fi
echo "✅ Authenticated as: $($GCLOUD auth list --filter=status:ACTIVE --format='value(account)')"

# Step 3: Check if bucket exists
echo ""
echo "🔍 Step 3: Checking if Storage bucket exists..."
if ! $GSUTIL ls "gs://$BUCKET_NAME" &>/dev/null; then
    echo "❌ Bucket gs://$BUCKET_NAME does not exist!"
    echo ""
    echo "Please enable Firebase Storage first:"
    echo "  1. Go to: https://console.firebase.google.com/project/$PROJECT_ID/storage"
    echo "  2. Click 'Get Started'"
    echo "  3. Choose 'Start in production mode' or 'Start in test mode'"
    echo "  4. Select a location (e.g., asia-south1)"
    echo "  5. Click 'Done'"
    echo ""
    echo "Then run this script again."
    exit 1
fi
echo "✅ Bucket exists: gs://$BUCKET_NAME"

# Step 4: Deploy storage rules
echo ""
echo "📜 Step 4: Deploying storage rules..."
firebase deploy --only storage

# Step 5: Configure CORS
echo ""
echo "🌐 Step 5: Configuring CORS..."
if [ ! -f "storage-cors.json" ]; then
    echo "❌ storage-cors.json not found!"
    exit 1
fi

$GSUTIL cors set storage-cors.json "gs://$BUCKET_NAME"

if [ $? -eq 0 ]; then
    echo "✅ CORS configuration applied!"
    echo ""
    echo "📋 Current CORS configuration:"
    $GSUTIL cors get "gs://$BUCKET_NAME"
else
    echo "❌ Failed to apply CORS configuration."
    exit 1
fi

echo ""
echo "✅ Setup complete! Firebase Storage is now configured."
echo ""
echo "You can now upload images from your web app."

