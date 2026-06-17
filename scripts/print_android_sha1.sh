#!/usr/bin/env bash
set -euo pipefail

# Print SHA-1 fingerprints for Firebase API key restrictions.
# Usage:
#   ./scripts/print_android_sha1.sh              # debug keystore (default)
#   ./scripts/print_android_sha1.sh release.jks alias  # release keystore

if [ "${1:-}" != "" ]; then
  STORE_FILE="$1"
  KEY_ALIAS="${2:-upload}"
  echo "Release keystore SHA-1 (${STORE_FILE}, alias ${KEY_ALIAS}):"
  keytool -list -v -keystore "$STORE_FILE" -alias "$KEY_ALIAS" 2>/dev/null | awk '/SHA1:/{print $2; exit}'
  exit 0
fi

DEBUG_STORE="${HOME}/.android/debug.keystore"
echo "Debug keystore SHA-1 (${DEBUG_STORE}):"
keytool -list -v -keystore "$DEBUG_STORE" -alias androiddebugkey -storepass android -keypass android 2>/dev/null | awk '/SHA1:/{print $2; exit}'

echo ""
echo "Add to secure_api_keys.sh:"
echo "  ANDROID_SHA1_LIST='debug_sha1,release_sha1' ./scripts/secure_api_keys.sh"
