#!/usr/bin/env bash
set -euo pipefail

# Apply Firebase API key restrictions in GCP (Browser + Android).
# Safe to re-run after adding domains or SHA-1 fingerprints.
#
# Usage:
#   ./scripts/secure_api_keys.sh
#
# Multiple Android signing certs (comma-separated SHA-1, colons optional):
#   ANDROID_SHA1_LIST='debug_sha1,release_sha1' ./scripts/secure_api_keys.sh
#
# Single cert (legacy):
#   ANDROID_SHA1='aa:bb:...' ./scripts/secure_api_keys.sh

PROJECT_ID="${FIREBASE_PROJECT_ID:-wedecorenquries}"
PROJECT_NUMBER="${FIREBASE_PROJECT_NUMBER:-747327664982}"

BROWSER_KEY_ID="${BROWSER_KEY_ID:-597e1c6c-4a6b-48f3-974b-c3ef0f37e002}"
ANDROID_KEY_ID="${ANDROID_KEY_ID:-149edf19-b0ab-4a1f-8f79-1ca570d50f6a}"

ANDROID_PACKAGE="${ANDROID_PACKAGE:-com.example.we_decor_enquiries}"
# Default: local debug keystore SHA-1 (matches current release signing in build.gradle.kts)
DEFAULT_DEBUG_SHA1="54ba5fe400ad1a3f057e09b032258ed214d4d05b"
ANDROID_SHA1_LIST="${ANDROID_SHA1_LIST:-${ANDROID_SHA1:-$DEFAULT_DEBUG_SHA1}}"

normalize_sha1() {
  echo "$1" | tr '[:upper:]' '[:lower:]' | tr -d ':'
}

key_name() {
  echo "projects/${PROJECT_NUMBER}/locations/global/keys/$1"
}

echo "Restricting Browser key (${BROWSER_KEY_ID})..."
gcloud services api-keys update "$(key_name "$BROWSER_KEY_ID")" \
  --project="$PROJECT_ID" \
  --allowed-referrers="https://wedecorenquries.web.app/*,https://wedecorenquries.firebaseapp.com/*,http://localhost:*,http://127.0.0.1:*"

android_args=()
IFS=',' read -r -a sha_list <<< "$ANDROID_SHA1_LIST"
for raw_sha in "${sha_list[@]}"; do
  sha="$(normalize_sha1 "$(echo "$raw_sha" | xargs)")"
  if [ -z "$sha" ]; then
    continue
  fi
  android_args+=(--allowed-application="sha1_fingerprint=${sha},package_name=${ANDROID_PACKAGE}")
done

if [ "${#android_args[@]}" -eq 0 ]; then
  echo "ERROR: No Android SHA-1 fingerprints provided." >&2
  exit 1
fi

echo "Restricting Android key (${ANDROID_KEY_ID}) for package ${ANDROID_PACKAGE}..."
echo "  SHA-1 fingerprints: ${sha_list[*]}"
gcloud services api-keys update "$(key_name "$ANDROID_KEY_ID")" \
  --project="$PROJECT_ID" \
  "${android_args[@]}"

echo ""
echo "Active key strings (for local scripts only — do not commit):"
gcloud services api-keys get-key-string "$(key_name "$BROWSER_KEY_ID")" --project="$PROJECT_ID"
gcloud services api-keys get-key-string "$(key_name "$ANDROID_KEY_ID")" --project="$PROJECT_ID"

echo ""
echo "Done."
echo "Release builds currently use debug signing (android/app/build.gradle.kts)."
echo "When you configure a release keystore, add its SHA-1:"
echo "  ANDROID_SHA1_LIST='${DEFAULT_DEBUG_SHA1},<release_sha1>' ./scripts/secure_api_keys.sh"
echo "Play App Signing cert: Play Console → App integrity → App signing key certificate"
