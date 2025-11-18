#!/bin/bash

# Script to configure CORS for Firebase Storage via CLI
# Prerequisites: Firebase Storage must be enabled in Firebase Console first

set -e

echo "🔧 Setting up Firebase Storage CORS configuration..."

# Set Python path for gcloud
export CLOUDSDK_PYTHON=$(which python3)

# Path to gcloud/gsutil
GCLOUD_PATH="/opt/homebrew/share/google-cloud-sdk/bin"
GSUTIL="$GCLOUD_PATH/gsutil"
GCLOUD="$GCLOUD_PATH/gcloud"

# Check if gsutil exists
if [ ! -f "$GSUTIL" ]; then
    echo "❌ gsutil not found at $GSUTIL"
    echo "Please install Google Cloud SDK:"
    echo "  brew install --cask google-cloud-sdk"
    exit 1
fi

# Set project
PROJECT_ID="wedecorenquries"
BUCKET_NAME="${PROJECT_ID}.appspot.com"

echo "📋 Setting project to $PROJECT_ID..."
$GCLOUD config set project $PROJECT_ID

# Check if authenticated
echo "🔐 Checking authentication..."
if ! $GCLOUD auth list --filter=status:ACTIVE --format="value(account)" | grep -q .; then
    echo "⚠️  Not authenticated. Please authenticate:"
    echo "   $GCLOUD auth login"
    echo ""
    echo "Or for application default credentials:"
    echo "   $GCLOUD auth application-default login"
    exit 1
fi

# Check if bucket exists
echo "🔍 Checking if bucket exists..."
if ! $GSUTIL ls "gs://$BUCKET_NAME" &>/dev/null; then
    echo "❌ Bucket gs://$BUCKET_NAME does not exist!"
    echo ""
    echo "Please enable Firebase Storage first:"
    echo "  1. Go to https://console.firebase.google.com/project/$PROJECT_ID/storage"
    echo "  2. Click 'Get Started' to enable Storage"
    echo "  3. Then run this script again"
    exit 1
fi

# Apply CORS configuration
echo "🌐 Applying CORS configuration..."
CORS_FILE="storage-cors.json"

if [ ! -f "$CORS_FILE" ]; then
    echo "❌ CORS file $CORS_FILE not found!"
    exit 1
fi

$GSUTIL cors set "$CORS_FILE" "gs://$BUCKET_NAME"

if [ $? -eq 0 ]; then
    echo "✅ CORS configuration applied successfully!"
    echo ""
    echo "Verifying configuration:"
    $GSUTIL cors get "gs://$BUCKET_NAME"
else
    echo "❌ Failed to apply CORS configuration."
    exit 1
fi

