#!/usr/bin/env bash
set -euo pipefail

echo "=== Pass 0: clean & get ==="
flutter clean
flutter pub get

echo "=== Pass 1: built-in fixes ==="
flutter fix --apply || true
dart fix --apply || true

echo "=== Pass 2: codemods (safe patterns) ==="
# Requires ripgrep (rg) and sd (https://github.com/chmln/sd). If missing, fall back to sed.
HAS_RG=$(command -v rg || true)
HAS_SD=$(command -v sd || true)

# A) showDialog<T>: only add <void> when no generic is present
if [[ -n "$HAS_RG" && -n "$HAS_SD" ]]; then
  FILES=$(rg -l --hidden --glob 'lib/**/*.dart' 'showDialog\(' || true)
  for f in $FILES; do
    if rg -q 'showDialog\s*<' "$f"; then
      continue
    fi
    sd -s 'showDialog(' 'showDialog<void>(' "$f"
  done
else
  find lib -name '*.dart' -print0 | xargs -0 sed -i.bak 's/showDialog(/showDialog<void>(/g'
  find lib -name '*.bak' -delete
fi

# B) withOpacity(x) -> withValues(alpha: x)
if [[ -n "$HAS_RG" && -n "$HAS_SD" ]]; then
  FILES=$(rg -l --hidden --glob 'lib/**/*.dart' 'withOpacity\(' || true)
  for f in $FILES; do
    sd -r 'withOpacity\(\s*([0-9]*\.?[0-9]+)\s*\)' 'withValues(alpha: $1)' "$f"
  done
else
  find lib -name '*.dart' -print0 | xargs -0 sed -i.bak -E 's/withOpacity\(([0-9]*\.?[0-9]+)\)/withValues(alpha: \1)/g'
  find lib -name '*.bak' -delete
fi

echo "=== Pass 3: regenerate code (freezed/json) ==="
flutter pub run build_runner build --delete-conflicting-outputs

echo "=== Pass 4: analyze & export TODO ==="
flutter analyze || true

mkdir -p tool
flutter analyze --machine \
  | grep '^analysis\.issue' \
  | awk -F'|' '{print $3" • "$8":"$9" • "$13}' \
  | sed 's/^warning/⚠️ warning/; s/^error/❌ error/' \
  | sort \
  > tool/analyzer_todo.txt || true

COUNT=$(wc -l < tool/analyzer_todo.txt | tr -d ' ')
echo "=== Analyzer TODO items: $COUNT (see tool/analyzer_todo.txt) ==="

echo "=== Done. Next steps ==="
echo "1) Review git diff (git status; git diff)."
echo "2) Run: flutter analyze; flutter test."
echo "3) Commit when green."

