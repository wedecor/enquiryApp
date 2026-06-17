#!/usr/bin/env bash
set -euo pipefail

# DANGER: Rewrites git history. Coordinate with your team before force-pushing.
# Removes known leaked secret literals from all commits (not just current files).
#
# Requires: brew install git-filter-repo  OR  pip install git-filter-repo
#
# Usage:
#   ./scripts/purge_secrets_from_history.sh
#   git remote add origin <url>   # only if filter-repo removed remotes
#   git push --force --all && git push --force --tags   # only after team agreement

if ! command -v git-filter-repo >/dev/null 2>&1; then
  echo "git-filter-repo not found. Install via brew or pip." >&2
  exit 1
fi

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_ROOT"

if ! git diff --quiet || ! git diff --cached --quiet; then
  echo "ERROR: Working tree has uncommitted changes." >&2
  echo "Stash or commit first, then re-run this script." >&2
  exit 1
fi

if [ -n "$(git status --porcelain)" ]; then
  echo "ERROR: Untracked files present. Stash with -u or commit first." >&2
  exit 1
fi

ORIGIN_URL="$(git remote get-url origin 2>/dev/null || true)"

REPLACE_FILE="$(mktemp)"
trap 'rm -f "$REPLACE_FILE"' EXIT

cat >"$REPLACE_FILE" <<'EOF'
REDACTED_LEAKED_FIREBASE_API_KEY==>REDACTED_LEAKED_FIREBASE_API_KEY
REDACTED_UNKNOWN_FIREBASE_API_KEY==>REDACTED_UNKNOWN_FIREBASE_API_KEY
REDACTED_LEAKED_GMAIL_APP_PASSWORD==>REDACTED_LEAKED_GMAIL_APP_PASSWORD
REDACTED_LEAKED_GMAIL_APP_PASSWORD==>REDACTED_LEAKED_GMAIL_APP_PASSWORD
EOF

BACKUP="backup/pre-secret-purge-$(date +%Y%m%d-%H%M%S)"
echo "Creating safety branch: $BACKUP"
git branch "$BACKUP"

echo "Rewriting history to redact known leaked literals..."
git filter-repo --replace-text "$REPLACE_FILE" --force

if [ -n "$ORIGIN_URL" ]; then
  git remote add origin "$ORIGIN_URL" 2>/dev/null || git remote set-url origin "$ORIGIN_URL"
  echo "Restored origin remote: $ORIGIN_URL"
fi

echo ""
echo "Verifying leaked literals are gone from reachable history..."
LEAKED=0
for needle in \
  'REDACTED_LEAKED_FIREBASE_API_KEY' \
  'REDACTED_UNKNOWN_FIREBASE_API_KEY' \
  'REDACTED_LEAKED_GMAIL_APP_PASSWORD' \
  'REDACTED_LEAKED_GMAIL_APP_PASSWORD'
do
  if git log --all -S "$needle" --oneline | grep -q .; then
    echo "  STILL FOUND: $needle" >&2
    LEAKED=1
  fi
done

if [ "$LEAKED" -ne 0 ]; then
  echo "Verification failed — some literals remain (check backup branch $BACKUP)." >&2
  exit 1
fi

echo "Verification passed."
echo ""
echo "History rewrite complete on branch $(git branch --show-current)."
echo "Backup branch '$BACKUP' still contains pre-rewrite history — delete locally before sharing:"
echo "  git branch -D '$BACKUP'"
echo ""
echo "Review: git log -p -- lib/firebase_options.dart functions/src/index.ts | head"
echo "Then (if acceptable): git push --force --all && git push --force --tags"
echo "All collaborators must re-clone or reset after force-push."
