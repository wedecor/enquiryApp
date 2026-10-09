# We Decor Enquiries

Flutter app for managing customer enquiries for We Decor Events (event decoration).
Firebase backend (Auth, Firestore, Storage, Cloud Messaging, Cloud Functions) with
admin/staff role-based access.

**Shipped targets:** Android (APK sideloaded from Firebase Hosting at `/android`) and the
Flutter web app on Firebase Hosting (`build/web`). There is no iOS or desktop build.

## Tech stack

- Flutter **3.35** (Dart 3.9) — see `pubspec.lock` (`sdks:`); CI pins `3.35.x`
- Riverpod 2, Freezed / json_serializable (generated `*.g.dart` / `*.freezed.dart` are committed)
- Cloud Functions: TypeScript, firebase-functions v2, region `asia-south1`, Node 22 (`functions/`)
- Firestore rules tests: Jest + emulator (`rules-tests/`)

## Layout

```
lib/              app code (core/, features/, shared/, ui/)
test/             unit + widget tests
android/          Android project
functions/        Cloud Functions (TypeScript)
rules-tests/      Firestore security-rules tests
public/           Firebase Hosting site (public/android = APK download page + version.json)
firestore.rules, firestore.indexes.json, storage.rules, firebase.json
scripts/          helper scripts (scripts/migrations = one-off Firestore data migrations)
docs/             docs; docs/archive = old reports/notes kept for history
```

## Development

```bash
flutter pub get
flutter run                 # debug build, no release keystore needed
flutter analyze
flutter test
```

Requirements: Flutter 3.35.x, Java 17+ (Android build), Node 22 (`.nvmrc`), Firebase CLI.
`android/app/google-services.json` is not committed — download it from the Firebase
console (project `wedecorenquries`).

Code generation (only after changing Freezed/json/Riverpod-annotated files):

```bash
dart run build_runner build --delete-conflicting-outputs
```

## Functions env

Non-secret function config lives in `functions/.env` (not committed):

```bash
cp functions/.env.example functions/.env   # then edit values
firebase functions:secrets:set SMTP_PASS   # SMTP password is a Secret Manager secret
```

The `env` block in `firebase.json` is not read by the Firebase CLI — don't put config there.

Build / deploy functions:

```bash
cd functions && npm ci && npm run build && cd ..
firebase deploy --only functions
```

## Google Maps search

The enquiry **Event Location** field suggests venues from Google Maps as you type
(Bangalore-biased, India only). It's optional: free text such as "Bangalore" still
saves as typed. The API key lives only in Secret Manager — the app calls the
`placesAutocomplete` / `placeDetails` callables (asia-south1), never Google directly.
Until the key is set, the field silently behaves as plain text.

One-time setup (Google Cloud console, same project as Firebase):

1. **APIs & Services → Library**: enable **Places API (New)**. A billing account must be
   linked to the project.
2. **APIs & Services → Credentials → Create credentials → API key**. Under *API
   restrictions* choose **Restrict key → Places API (New)** only. No application
   restriction is needed — the key is only used server-side by Cloud Functions.
3. Store it as a secret:

   ```bash
   firebase functions:secrets:set GOOGLE_MAPS_API_KEY
   ```

4. **Billing → Budgets & alerts**: add a budget alert (e.g. ₹500/month).
   **APIs & Services → Places API (New) → Quotas**: set a per-day cap on requests
   (e.g. 1,000/day for Autocomplete and for Place Details).
5. Deploy the two functions:

   ```bash
   cd functions && npm ci && npm run build && cd ..
   firebase deploy --only functions:placesAutocomplete,functions:placeDetails
   ```

Cost per search: keystrokes are debounced (350 ms, from 3 characters) and grouped into
one session token. Picking a venue ends the session with one **Place Details
Essentials** call (field mask `id,formattedAddress,location,addressComponents` — no
`displayName`, which is a Pro field), and the session's Autocomplete requests are then
not billed separately. Searches abandoned without a pick are billed per Autocomplete
request. India pricing includes **70,000 free Autocomplete requests** and **70,000 free
Place Details Essentials** calls per month — far above this app's volume.

"Open in Maps" on the enquiry page is a plain `google.com/maps/search` link and is free.

## Firestore rules tests

```bash
cd rules-tests && npm ci && npm run test:emulator   # needs Java 11+
```

## Release (Android APK via Hosting)

1. Bump `version:` in `pubspec.yaml` (`x.y.z+build`; the build number must increase).
2. Make sure the release keystore is configured in `android/local.properties`
   (`RELEASE_STORE_FILE`, `RELEASE_STORE_PASSWORD`, `RELEASE_KEY_ALIAS`, `RELEASE_KEY_PASSWORD`).
   Release builds fail if these are missing — they never fall back to the debug key.
   Always sign with the **same** key as the APK users already have installed, otherwise
   Android refuses the update.
3. Build: `flutter build apk --release`
4. Update `public/android/version.json`: `version`, `buildNumber`, `releaseDate`,
   `releaseNotes`, and `sha256` of `build/app/outputs/flutter-apk/app-release.apk`
   (`sha256sum` / `shasum -a 256`). Set `minSupportedBuildNumber` / `forceUpdate` only
   when old builds must stop working.
5. Deploy: `firebase deploy --only hosting`
   The hosting predeploy runs `flutter build web --release`, then
   `scripts/copy-apk-to-web.sh` copies the built APK and `public/android/*` into
   `build/web/android/`. The script fails if the APK hasn't been built; it never builds
   the APK itself.

Rules / indexes: `firebase deploy --only firestore:rules,firestore:indexes,storage`.

## CI

`.github/workflows/ci.yml` runs on push to `main` and on PRs: Flutter analyze + test
(format check is advisory), functions build, and Firestore rules tests on the emulator.
Optional secret `GOOGLE_SERVICES_JSON` (raw or base64) is written to
`android/app/google-services.json` if set.

## Docs

- [Feature matrix](docs/FEATURE_MATRIX.md), [RBAC quick reference](docs/RBAC_QUICKREF.md)
- [Android signing](docs/ANDROID_SIGNING.md)
- Older reports and notes: `docs/archive/`
