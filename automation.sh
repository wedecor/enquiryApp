#!/usr/bin/env bash
set -euo pipefail

pushd functions >/dev/null
npm ci
npm run lint
npm test
popd >/dev/null

# Firestore rules tests would go here if using emulator test harness
# Placeholder: ensure files exist
ls -lah firestore.rules firestore.indexes.json

echo "Automation completed."
