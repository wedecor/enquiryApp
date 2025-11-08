#!/usr/bin/env bash

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

missing=false
while IFS= read -r f; do
  parts=$(grep -E "^[[:space:]]*part[[:space:]]+'[^']+\.(freezed|g)\.dart';" "$f" || true)
  if [[ -n "$parts" ]]; then
    while IFS= read -r line; do
      rel=$(echo "$line" | sed -E "s/.*part[[:space:]]+'([^']+)'.*/\1/")
      target="$ROOT/$(dirname "$f")/$rel"
      if [[ ! -f "$target" ]]; then
        echo "Missing generated file for: $f -> $rel"
        missing=true
      fi
    done <<< "$parts"
  fi
done < <(git ls-files 'lib/**/*.dart')

if [[ "$missing" == "true" ]]; then
  echo "==> Missing generated files detected. Running build_runner…"
  flutter pub run build_runner build --delete-conflicting-outputs
else
  echo "All generated files present."
fi

