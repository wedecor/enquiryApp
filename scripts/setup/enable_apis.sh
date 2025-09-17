#!/usr/bin/env bash
set -euo pipefail

PROJECT_ID="${PROJECT_ID:-wedecorenquries}"

echo "Enabling APIs for project: ${PROJECT_ID}"
gcloud services enable \
  firestore.googleapis.com \
  identitytoolkit.googleapis.com \
  --project "${PROJECT_ID}"

echo "✅ APIs enabled (firestore, identitytoolkit)."


