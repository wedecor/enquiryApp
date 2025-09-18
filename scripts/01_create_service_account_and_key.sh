#!/bin/bash
set -euo pipefail

# Configuration
PROJECT_ID="${PROJECT_ID:-wedecorenquries}"
SA_NAME="${SA_NAME:-wedecor-seeder}"
KEY_OUT="${KEY_OUT:-serviceAccountKey.json}"
FORCE="${FORCE:-false}"

echo "🚀 WeDecor Service Account Setup"
echo "Project: $PROJECT_ID"
echo "Service Account: $SA_NAME"
echo "Key Output: $KEY_OUT"
echo ""

# Check gcloud installation
if ! command -v gcloud >/dev/null 2>&1; then
    echo "❌ gcloud CLI not found. Install from: https://cloud.google.com/sdk/docs/install"
    exit 1
fi

# Check gcloud authentication
if ! gcloud config list account --format="value(core.account)" 2>/dev/null | grep -q "@"; then
    echo "❌ gcloud not authenticated. Run: gcloud auth login"
    exit 1
fi

echo "✅ gcloud CLI authenticated"

# Check if key file already exists
if [[ -f "$KEY_OUT" && "$FORCE" != "true" ]]; then
    echo "✅ Service account key already exists: $KEY_OUT"
    echo "   Use --force to recreate, or delete the file manually"
    echo ""
    echo "🎯 Next steps:"
    echo "   export GOOGLE_APPLICATION_CREDENTIALS=\$PWD/$KEY_OUT"
    echo "   echo 'ADMIN_UID=your_firebase_auth_uid' > .env"
    echo "   npm run seed"
    exit 0
fi

# Set active project
echo "🔧 Setting active project..."
gcloud config set project "$PROJECT_ID" || {
    echo "❌ Failed to set project $PROJECT_ID. Check project ID and permissions."
    exit 1
}

# Enable required APIs
echo "🔌 Enabling required APIs..."
gcloud services enable firestore.googleapis.com iam.googleapis.com --quiet || {
    echo "❌ Failed to enable APIs. Check project permissions."
    exit 1
}

echo "✅ APIs enabled"

# Create service account
SA_EMAIL="$SA_NAME@$PROJECT_ID.iam.gserviceaccount.com"
echo "👤 Creating service account..."

if gcloud iam service-accounts describe "$SA_EMAIL" >/dev/null 2>&1; then
    echo "✅ Service account already exists: $SA_EMAIL"
else
    gcloud iam service-accounts create "$SA_NAME" \
        --display-name="WeDecor Firestore Seeder" \
        --description="Service account for automated Firestore seeding" || {
        echo "❌ Failed to create service account"
        exit 1
    }
    echo "✅ Service account created: $SA_EMAIL"
fi

# Bind required roles
echo "🔐 Binding IAM roles..."

ROLES=(
    "roles/datastore.user"
    "roles/viewer"
    # "roles/datastore.importExportAdmin"  # Uncomment if you need import/export capabilities
)

for role in "${ROLES[@]}"; do
    echo "   Binding $role..."
    gcloud projects add-iam-policy-binding "$PROJECT_ID" \
        --member="serviceAccount:$SA_EMAIL" \
        --role="$role" \
        --quiet >/dev/null || {
        echo "❌ Failed to bind role $role"
        exit 1
    }
done

echo "✅ IAM roles bound successfully"

# Create and download key
echo "🔑 Creating service account key..."
gcloud iam service-accounts keys create "$KEY_OUT" \
    --iam-account="$SA_EMAIL" || {
    echo "❌ Failed to create service account key"
    exit 1
}

echo "✅ Service account key created: $KEY_OUT"

# Set environment variable
export GOOGLE_APPLICATION_CREDENTIALS="$PWD/$KEY_OUT"
echo ""
echo "🎉 Setup complete!"
echo ""
echo "🎯 Next steps:"
echo "   1. Set your admin UID:"
echo "      echo 'ADMIN_UID=your_firebase_auth_uid' > .env"
echo ""
echo "   2. Run the seeder:"
echo "      export GOOGLE_APPLICATION_CREDENTIALS=\$PWD/$KEY_OUT"
echo "      npm run seed"
echo ""
echo "   3. Or use the automated script:"
echo "      ./scripts/02_seed_local.sh"
echo ""
echo "📝 Service account details:"
echo "   Email: $SA_EMAIL"
echo "   Key file: $KEY_OUT"
echo "   Project: $PROJECT_ID"

