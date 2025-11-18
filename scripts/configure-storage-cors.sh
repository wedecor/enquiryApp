#!/bin/bash

# Script to configure CORS for Firebase Storage
# This allows web apps to upload files to Firebase Storage

echo "🔧 Configuring CORS for Firebase Storage..."

# Check if gcloud is installed
if ! command -v gcloud &> /dev/null; then
    echo "❌ Google Cloud SDK (gcloud) is not installed."
    echo ""
    echo "Please install it from: https://cloud.google.com/sdk/docs/install"
    echo ""
    echo "After installing, run:"
    echo "  gcloud auth login"
    echo "  gcloud config set project wedecorenquries"
    echo "  gsutil cors set storage-cors.json gs://wedecorenquries.appspot.com"
    exit 1
fi

# Check if gsutil is available
if ! command -v gsutil &> /dev/null; then
    echo "❌ gsutil is not installed. Please install Google Cloud SDK."
    exit 1
fi

# Set the project
echo "📋 Setting project to wedecorenquries..."
gcloud config set project wedecorenquries

# Apply CORS configuration
echo "🌐 Applying CORS configuration..."
gsutil cors set storage-cors.json gs://wedecorenquries.appspot.com

if [ $? -eq 0 ]; then
    echo "✅ CORS configuration applied successfully!"
    echo ""
    echo "You can verify the configuration with:"
    echo "  gsutil cors get gs://wedecorenquries.appspot.com"
else
    echo "❌ Failed to apply CORS configuration."
    echo ""
    echo "Make sure:"
    echo "  1. Firebase Storage is enabled in Firebase Console"
    echo "  2. You have the necessary permissions"
    echo "  3. The bucket name is correct (wedecorenquries.appspot.com)"
    exit 1
fi

