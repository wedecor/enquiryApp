#!/usr/bin/env bash
set -euo pipefail
TARGET="${1:-apk}"   # apk | appbundle | web
DEFINES=(
  --dart-define=APP_ENV=prod
  --dart-define=ENABLE_CRASHLYTICS=true
  --dart-define=ENABLE_ANALYTICS=true
  --dart-define=ENABLE_PERFORMANCE=true
)
flutter build "$TARGET" --release "${DEFINES[@]}"
