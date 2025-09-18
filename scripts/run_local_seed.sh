#!/usr/bin/env sh
set -eu

echo "▶️  Local Firestore Seeding (UID → seed → verify)"

KEY="${GOOGLE_APPLICATION_CREDENTIALS:-$PWD/serviceAccountKey.json}"
if [ ! -f "$KEY" ]; then
  echo "❌ serviceAccountKey.json not found at: $KEY"
  echo "   Place your key at ./serviceAccountKey.json or export GOOGLE_APPLICATION_CREDENTIALS to its absolute path."
  exit 1
fi

export GOOGLE_APPLICATION_CREDENTIALS="$KEY"
echo "✅ Using key: $GOOGLE_APPLICATION_CREDENTIALS"

echo "👤 Ensuring admin user + writing .env (ADMIN_UID, ADMIN_EMAIL)…"
npm run admin-uid

echo "🌱 Seeding Firestore…"
npm run seed

echo "🔍 Verifying…"
npm run verify-seed

echo "🎉 Done! Seeding + verification complete."

