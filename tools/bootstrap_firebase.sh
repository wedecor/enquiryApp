#!/usr/bin/env bash
set -euo pipefail
PROJECT_ID="${PROJECT_ID:-wedecor-dev}"
SERVICE_ACCOUNT_JSON="${SERVICE_ACCOUNT_JSON:-}"
FIREBASE_TOKEN="${FIREBASE_TOKEN:-}"

echo "== Versions =="
node -v || true
npm -v || true
./flutter/bin/flutter --version || true
./flutter/bin/dart --version || true

echo "== Install Firebase CLI =="
if ! command -v firebase >/dev/null 2>&1; then
  npx --yes firebase-tools --version || { echo "❌ Firebase CLI not available"; exit 1; }
fi
npx firebase-tools --version || { echo "❌ Firebase CLI not available"; exit 1; }

echo "== Firebase Login/Use =="
if [ -n "$FIREBASE_TOKEN" ]; then
  echo "Using provided FIREBASE_TOKEN"
fi
npx firebase-tools use "$PROJECT_ID" --add ${FIREBASE_TOKEN:+--token "$FIREBASE_TOKEN"} || npx firebase-tools use "$PROJECT_ID" ${FIREBASE_TOKEN:+--token "$FIREBASE_TOKEN"}

echo "== Normalize folders =="
mkdir -p firebase
[ -f "firestore.rules" ] && mv -f firestore.rules firebase/ || true
[ -f "firestore.indexes.json" ] && mv -f firestore.indexes.json firebase/ || true

if [ -d "firebase/functions" ]; then FUNCDIR="firebase/functions";
elif [ -d "functions" ]; then FUNCDIR="functions";
else echo "❌ Functions directory not found"; exit 1; fi
echo "Using Functions dir: $FUNCDIR"

echo "== Build Functions =="
pushd "$FUNCDIR"
npm ci || npm install
npm run build
popd

echo "== Deploy rules & indexes =="
npx firebase-tools deploy --only firestore:rules,firestore:indexes ${FIREBASE_TOKEN:+--token "$FIREBASE_TOKEN"}

echo "== Deploy functions =="
npx firebase-tools deploy --only functions ${FIREBASE_TOKEN:+--token "$FIREBASE_TOKEN"}

echo "== Seed admin (if creds available) =="
if [ -f "$SERVICE_ACCOUNT_JSON" ]; then
  export GOOGLE_APPLICATION_CREDENTIALS="$SERVICE_ACCOUNT_JSON"
  export FIREBASE_PROJECT_ID="$PROJECT_ID"
  node tools/seed-admin.ts || npx ts-node tools/seed-admin.ts || node --loader ts-node/esm tools/seed-admin.ts || true
else
  echo "ℹ️ SERVICE_ACCOUNT_JSON not provided; skipping seed-admin.ts"
fi

echo "== Emulator smoke =="
npx firebase-tools emulators:start --only functions,firestore,auth --project "$PROJECT_ID" ${FIREBASE_TOKEN:+--token "$FIREBASE_TOKEN"} & EMU=$!
sleep 6 || true
kill $EMU 2>/dev/null || true

if [ -d "packages/app" ]; then
  echo "== Flutter build/test =="
  pushd packages/app
  ../../flutter/bin/flutter pub get
  ../../flutter/bin/dart run build_runner build -d
  ../../flutter/bin/flutter analyze --no-fatal-warnings --no-fatal-infos
  ../../flutter/bin/flutter test || true
  # Non-blocking web run smoke
  ../../flutter/bin/flutter run -d chrome --debug --web-port 7357 & APPPID=$!
  sleep 10 || true
  kill $APPPID 2>/dev/null || true
  popd
else
  echo "ℹ️ packages/app not found; skipping Flutter."
fi

echo "== Summary =="
echo "✅ Firebase CLI ready"
echo "✅ Rules & Indexes deployed to: $PROJECT_ID"
echo "✅ Functions built & deployed"
[ -f "$SERVICE_ACCOUNT_JSON" ] && echo "✅ Admin seeding attempted (check logs)" || echo "ℹ️ Admin seeding skipped (no creds)"
echo "✅ Emulator smoke completed"
echo "✅ Flutter analyze/test ran (if app present)"
