#!/usr/bin/env bash
set -euo pipefail

# Apply Firebase API key restrictions in GCP (Browser + Android).
# Safe to re-run after adding domains or release keystore SHA-1 fingerprints.
#
# Usage:
#   ./scripts/secure_api_keys.sh
#   ANDROID_SHA1='aa:bb:...' ANDROID_PACKAGE='com.example.we_decor_enquiries' ./scripts/secure_api_keys.sh

PROJECT_ID="${FIREBASE_PROJECT_ID:-wedecorenquries}"
PROJECT_NUMBER="${FIREBASE_PROJECT_NUMBER:-747327664982}"

BROWSER_KEY_ID="${BROWSER_KEY_ID:-597e1c6c-4a6b-48f3-974b-c3ef0f37e002}"
ANDROID_KEY_ID="${ANDROID_KEY_ID:-149edf19-b0ab-4a1f-8f79-1ca570d50f6a}"

ANDROID_PACKAGE="${ANDROID_PACKAGE:-com.example.we_decor_enquiries}"
ANDROID_SHA1="${ANDROID_SHA1:-54ba5fe400ad1a3f057e09b032258ed214d4d05b}"
ANDROID_SHA1="${ANDROID_SHA1//:/}"

key_name() {
  echo "projects/${PROJECT_NUMBER}/locations/global/keys/$1"
}

echo "Restricting Browser key (${BROWSER_KEY_ID})..."
gcloud services api-keys update "$(key_name "$BROWSER_KEY_ID")" \
  --project="$PROJECT_ID" \
  --allowed-referrers="https://wedecorenquries.web.app/*,https://wedecorenquries.firebaseapp.com/*,http://localhost:*,http://127.0.0.1:*"

echo "Restricting Android key (${ANDROID_KEY_ID})..."
gcloud services api-keys update "$(key_name "$ANDROID_KEY_ID")" \
  --project="$PROJECT_ID" \
  --allowed-application="sha1_fingerprint=${ANDROID_SHA1},package_name=${ANDROID_PACKAGE}"

echo ""
echo "Active key strings (for local scripts only — do not commit):"
gcloud services api-keys get-key-string "$(key_name "$BROWSER_KEY_ID")" --project="$PROJECT_ID"
gcloud services api-keys get-key-string "$(key_name "$ANDROID_KEY_ID")" --project="$PROJECT_ID"

echo ""
echo "Done. If you ship Play Store builds, add the release keystore SHA-1:"
echo "  keytool -list -v -keystore your-release.jks -alias your-alias"
