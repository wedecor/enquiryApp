#!/usr/bin/env bash

set -euo pipefail

if ! command -v firebase >/dev/null 2>&1; then
  curl -sL https://firebase.tools | bash >/tmp/firebase-install.log 2>&1
fi

if [[ -z "${FIREBASE_PROJECT_ID:-}" ]]; then
  echo "Skipping Firestore rules tests: FIREBASE_PROJECT_ID missing."
  exit 0
fi

if [[ ! -f "firestore.rules" ]] || [[ ! -d "test/firestore" ]]; then
  echo "Skipping Firestore rules tests: rules or tests missing."
  exit 0
fi

firebase emulators:exec \
  --project "$FIREBASE_PROJECT_ID" \
  --only firestore \
  "npm -C test/firestore ci && npm -C test/firestore test"

