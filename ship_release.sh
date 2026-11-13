#!/usr/bin/env bash
# One-shot ship script for We Decor Enquiries.
# Run from anywhere:  ./ship_release.sh
# Every step writes its output to build/ship-logs/. Deploys and migrations ask before they run.
set -euo pipefail
cd "$(dirname "$0")"

if [[ -n "$(git status --porcelain)" ]]; then
  echo "Error: working tree is dirty. Commit or stash your changes before releasing."
  git status --short
  exit 1
fi

LOG="build/ship-logs"
mkdir -p "$LOG"
: > "$LOG/summary.txt"

say()  { echo; echo "=== $1 ==="; echo "=== $1 ===" >> "$LOG/summary.txt"; }
ask()  { read -r -p "$1 [y/N] " a; [[ "${a:-}" == y* || "${a:-}" == Y* ]]; }
run()  { # run <logname> <command...>
  local name="$1"; shift
  echo "\$ $*" > "$LOG/$name.txt"
  "$@" >> "$LOG/$name.txt" 2>&1
  local code=$?
  echo "$name: exit $code" | tee -a "$LOG/summary.txt"
  return $code
}
stop() { echo; echo "Stopped. Tell Claude: \"ship script failed\" — logs are in $LOG/"; exit 1; }

if [[ -f serviceAccountKey.json && -z "${GOOGLE_APPLICATION_CREDENTIALS:-}" ]]; then
  export GOOGLE_APPLICATION_CREDENTIALS="$PWD/serviceAccountKey.json"
fi

say "1/5 Check: analyze, tests, functions build & test"
run pub_get flutter pub get || stop
# Only real errors stop the script; style notes and warnings are logged.
run analyze flutter analyze --no-fatal-infos --no-fatal-warnings || stop
run test flutter test || stop
run functions_build bash -c "cd functions && npm ci && npm run build && npm test" || stop

say "2/5 Release build & version metadata"
BUILD_HOSTING=false
if ask "Build the release APK and update public/android/version.json?"; then
  run build_apk flutter build apk --release || stop
  APK="build/app/outputs/flutter-apk/app-release.apk"
  SHA="$(shasum -a 256 "$APK" | awk '{print $1}')"
  VERSION="$(grep -E '^version:' pubspec.yaml | awk '{print $2}')"
  NAME="${VERSION%%+*}"; BUILD="${VERSION##*+}"
  node -e '
    const fs=require("fs"); const p="public/android/version.json";
    const j=JSON.parse(fs.readFileSync(p,"utf8"));
    const [name,build,sha]=process.argv.slice(1);
    j.version=name; j.buildNumber=Number(build); j.minSupportedBuildNumber=Number(build);
    j.forceUpdate=true; j.sha256=sha; j.releaseDate=new Date().toISOString().slice(0,10);
    fs.writeFileSync(p, JSON.stringify(j,null,2)+"\n");
  ' "$NAME" "$BUILD" "$SHA"
  echo "version.json -> $NAME+$BUILD (forced), sha256 $SHA" | tee -a "$LOG/summary.txt"
  BUILD_HOSTING=true
else
  echo "Skipped release build." | tee -a "$LOG/summary.txt"
fi

say "3/5 Commit and push before deploy"
if [[ -n "$(git status --porcelain)" ]]; then
  if ask "Commit release metadata and push to remote before deploying?"; then
    VERSION="$(grep -E '^version:' pubspec.yaml | awk '{print $2}')"
    run commit git commit -am "chore(release): $VERSION" || stop
    run push git push || stop
  else
    echo "Refusing to deploy with uncommitted release changes." | tee -a "$LOG/summary.txt"
    stop
  fi
elif ask "Push current branch to remote before deploying?"; then
  run push git push || stop
fi

say "4/5 Deploy rules, indexes, storage, functions and hosting"
if ask "Deploy rules + indexes + storage + functions to production now?"; then
  run deploy_rules firebase deploy --only firestore:rules,firestore:indexes,storage || stop
  run deploy_functions firebase deploy --only functions --force || stop
  if [[ "$BUILD_HOSTING" == true ]] && ask "Deploy hosting now?"; then
    run deploy_hosting firebase deploy --only hosting || stop
  fi
else
  echo "Skipped deploy." | tee -a "$LOG/summary.txt"
fi

say "5/5 Data migrations (dry run first)"
MIGRATIONS=(
  scripts/migrations/2026_10_normalize_status_labels.ts
  scripts/migrations/2026_10_backfill_phone_normalized.ts
  scripts/migrations/2026_10_backfill_occasions.ts
)
for m in "${MIGRATIONS[@]}"; do
  n="$(basename "$m" .ts)"
  run "dry_$n" npx tsx "$m" || stop
  echo "--- dry run: $n (last lines) ---"; tail -n 8 "$LOG/dry_$n.txt"
  if ask "Apply $n?"; then run "apply_$n" npx tsx "$m" --apply || stop; fi
done

echo; echo "Done. Summary: $LOG/summary.txt — tell Claude \"ship script done\" and it will check the logs."
