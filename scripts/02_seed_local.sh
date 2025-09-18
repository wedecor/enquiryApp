#!/bin/bash
set -euo pipefail

# Configuration
KEY_FILE="${KEY_FILE:-serviceAccountKey.json}"
ENV_FILE="${ENV_FILE:-.env}"

echo "🌱 WeDecor Local Seeding"
echo "Environment: $ENV_FILE"
echo "Service Account: $KEY_FILE"
echo ""

# Check if .env file exists
if [[ ! -f "$ENV_FILE" ]]; then
    echo "❌ Environment file not found: $ENV_FILE"
    echo "   Create it with: echo 'ADMIN_UID=your_firebase_auth_uid' > $ENV_FILE"
    exit 1
fi

# Read ADMIN_UID from .env
if ! grep -q "ADMIN_UID=" "$ENV_FILE"; then
    echo "❌ ADMIN_UID not found in $ENV_FILE"
    echo "   Add it with: echo 'ADMIN_UID=your_firebase_auth_uid' >> $ENV_FILE"
    exit 1
fi

ADMIN_UID=$(grep "ADMIN_UID=" "$ENV_FILE" | cut -d'=' -f2- | tr -d '"' | tr -d "'" | xargs)
if [[ -z "$ADMIN_UID" || "$ADMIN_UID" == "your_firebase_auth_uid" ]]; then
    echo "❌ ADMIN_UID not properly set in $ENV_FILE"
    echo "   Current value: '$ADMIN_UID'"
    echo "   Set it to your actual Firebase Auth UID"
    exit 1
fi

echo "✅ ADMIN_UID found: $ADMIN_UID"

# Set up credentials
if [[ -n "${GOOGLE_APPLICATION_CREDENTIALS:-}" ]]; then
    echo "✅ Using existing GOOGLE_APPLICATION_CREDENTIALS: $GOOGLE_APPLICATION_CREDENTIALS"
elif [[ -f "$KEY_FILE" ]]; then
    export GOOGLE_APPLICATION_CREDENTIALS="$PWD/$KEY_FILE"
    echo "✅ Using service account key: $GOOGLE_APPLICATION_CREDENTIALS"
else
    echo "❌ No authentication method found"
    echo "   Either:"
    echo "   1. Set GOOGLE_APPLICATION_CREDENTIALS environment variable"
    echo "   2. Create $KEY_FILE using: ./scripts/01_create_service_account_and_key.sh"
    exit 1
fi

# Install dependencies
echo "📦 Installing dependencies..."
if [[ -f "package-lock.json" ]]; then
    npm ci || {
        echo "❌ Failed to install dependencies with npm ci"
        exit 1
    }
else
    npm install || {
        echo "❌ Failed to install dependencies with npm install"
        exit 1
    }
fi

echo "✅ Dependencies installed"

# Run TypeScript type checking
echo "🔍 Running type check..."
npm run typecheck || {
    echo "❌ TypeScript type check failed"
    exit 1
}

echo "✅ Type check passed"

# Run the seeder
echo "🌱 Running Firestore seeder..."
npm run seed || {
    echo "❌ Seeding failed"
    exit 1
}

echo "✅ Seeding completed!"

# Run verification
echo ""
echo "🔍 Verifying seeded data..."
npm run verify-seed || {
    echo "❌ Verification failed"
    exit 1
}

echo ""
echo "🎉 Seeding and verification completed successfully!"
echo ""
echo "🎯 Next steps:"
echo "   1. Restart your Flutter app"
echo "   2. Loading symbols should be eliminated"
echo "   3. All dropdowns should work perfectly"
echo ""
echo "📊 Your Firestore now contains:"
echo "   • ✅ All dropdown collections (verified)"
echo "   • ✅ Admin user document (verified)"
echo "   • ✅ Sample enquiry with history (verified)"
