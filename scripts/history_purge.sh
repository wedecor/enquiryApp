#!/usr/bin/env bash
set -euo pipefail
# DANGER: This rewrites git history. Coordinate with your team and force-push.
# Requires: pip install git-filter-repo OR brew install git-filter-repo

if ! command -v git-filter-repo >/dev/null 2>&1; then
  echo "git-filter-repo not found. Install via 'pip install git-filter-repo' or package manager." >&2
  exit 1
fi

# Edit patterns below to remove secret files from history
PATTERNS=(
  "*.pem" "*.p12" "id_rsa*" "serviceAccount*.json" "**/keys/**" ".env*" "*_secrets.*"
)

echo "Creating backup branch backup/pre-purge-$(date +%Y%m%d-%H%M%S)"
BACKUP=backup/pre-purge-$(date +%Y%m%d-%H%M%S)
git checkout -b "$BACKUP"

echo "Rewriting history to remove patterns: ${PATTERNS[*]}"
FILTER_ARGS=()
for p in "${PATTERNS[@]}"; do FILTER_ARGS+=("--path-glob" "$p" "--invert-paths"); done

git filter-repo "${FILTER_ARGS[@]}"

echo "Done. Review the repo, then force-push protected branches if private:"
echo "  git push --force --all"
echo "  git push --force --tags"
echo "Rotate any exposed credentials immediately after purge."
