#!/usr/bin/env bash
set -euo pipefail

PROJECT_ID="${PROJECT_ID:-wedecorenquries}"
FIRESTORE_LOCATION="${FIRESTORE_LOCATION:-asia-south1}"

echo "Using project: ${PROJECT_ID}"
firebase use "${PROJECT_ID}"

echo "Attempting to create default Firestore database in ${FIRESTORE_LOCATION} (safe if already exists)…"
for i in 1 2 3; do
  if npx firebase-tools@latest firestore:databases:create "(default)" --location="${FIRESTORE_LOCATION}" --project "${PROJECT_ID}"; then
    echo "✅ Firestore default database ensured."
    exit 0
  else
    echo "…not ready yet (attempt ${i}/3). Waiting 15s and retrying…"
    sleep 15
  fi
done

echo "⚠️ Could not create DB via CLI. If it already exists, this is fine. Otherwise, open Firebase Console → Firestore → Create database → Native → ${FIRESTORE_LOCATION}."


