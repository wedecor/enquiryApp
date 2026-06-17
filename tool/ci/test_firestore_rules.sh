#!/usr/bin/env bash

set -euo pipefail

if ! command -v firebase >/dev/null 2>&1; then
  curl -sL https://firebase.tools | bash >/tmp/firebase-install.log 2>&1
fi

if [[ ! -f "firestore.rules" ]]; then
  echo "Firestore rules tests: firestore.rules missing." >&2
  exit 1
fi

if [[ ! -d "rules-tests" ]]; then
  echo "Firestore rules tests: rules-tests/ directory missing." >&2
  exit 1
fi

# CI should not rely on a real Firebase project. The emulator does not need it.
PROJECT_ID="${FIREBASE_PROJECT_ID:-demo-project}"

firebase emulators:exec \
  --project "$PROJECT_ID" \
  --only firestore \
  "npm -C rules-tests install --silent --no-audit --no-fund && npm -C rules-tests test"

