#!/usr/bin/env bash
set -euo pipefail

# Configure SMTP for Cloud Functions (Firebase Secret Manager + env params).
# Never commit passwords — pass SMTP_PASS at runtime only.
#
# Usage:
#   SMTP_PASS='your-new-app-password' SMTP_USER='you@example.com' ./scripts/setup_smtp.sh

PROJECT_ID="${FIREBASE_PROJECT_ID:-wedecorenquries}"
SMTP_USER="${SMTP_USER:-connect2wedecor@gmail.com}"
SMTP_HOST="${SMTP_HOST:-smtp.gmail.com}"
SMTP_PORT="${SMTP_PORT:-587}"
SMTP_FROM="${SMTP_FROM_EMAIL:-WeDecor Events <${SMTP_USER}>}"

if [[ -z "${SMTP_PASS:-}" ]]; then
  echo "ERROR: SMTP_PASS is required." >&2
  echo "  1. Revoke the old Gmail app password at https://myaccount.google.com/apppasswords" >&2
  echo "  2. Create a new app password" >&2
  echo "  3. Re-run: SMTP_PASS='...' ./scripts/setup_smtp.sh" >&2
  exit 1
fi

echo "Setting SMTP_PASS in Firebase Secret Manager (project: ${PROJECT_ID})..."
printf '%s' "$SMTP_PASS" | firebase functions:secrets:set SMTP_PASS \
  --project "$PROJECT_ID" \
  --data-file=- \
  --force

echo "Setting SMTP_USER / SMTP_HOST / SMTP_PORT / SMTP_FROM_EMAIL function params..."
firebase functions:config:unset smtp 2>/dev/null || true

# Functions v2 params — stored as environment config on deploy
firebase functions:secrets:access SMTP_PASS --project "$PROJECT_ID" >/dev/null \
  && echo "SMTP_PASS secret verified."

cat <<EOF

Next steps:
  1. Ensure functions/src/index.ts inviteUser lists secrets: [SMTP_PASS] (already wired).
  2. Set runtime env for SMTP_USER (firebase console or .env.${PROJECT_ID}):
       SMTP_USER=${SMTP_USER}
       SMTP_HOST=${SMTP_HOST}
       SMTP_PORT=${SMTP_PORT}
       SMTP_FROM_EMAIL=${SMTP_FROM}
  3. Deploy: cd functions && npm run build && npm run deploy
  4. Test the admin invite-user flow.

EOF
