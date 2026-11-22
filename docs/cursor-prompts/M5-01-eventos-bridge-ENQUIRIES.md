# Cursor Prompt — M5-01 (Enquiries repo): EventOS Bridge (feed sender + Flutter API client)

## Context (read first)

You are working in the **We Decor Enquiries** repo: a Flutter 3.35 app (Riverpod 2, Freezed) + Firebase (Auth, Firestore, FCM, Storage, App Check) + Cloud Functions (TypeScript, firebase-functions v2, Node 22, region `asia-south1`, project `wedecorenquries`). The app is **live and used daily**. Read first:
- `README.md`, `docs/AUTH_FLOW.md`, `docs/RBAC_QUICKREF.md`, `docs/CI_OVERVIEW.md`, `.cursor/rules/*` (**especially `no-deploy-without-confirm.mdc`**)
- `firestore.rules` (money lives in `enquiries/{id}/financial/summary`, admin-only)
- `functions/src/index.ts`, `functions/src/notifications.ts` (`onEnquiryWrittenNotify` pattern), `functions/src/eventFunctions.ts` (multi-function events), `functions/src/websiteLeads.ts` (secret + `timingSafeEqual` pattern), `functions/src/statusVocabulary.ts`, `functions/src/customers.ts` (`normalizePhone`)

**Architecture decision (ADR-019 in the EventOS repo):** EventOS (NestJS + Postgres) becomes the single backend, and this Flutter app becomes its phone-first client. Migration is step by step. **This task is step 1 (bridge), Enquiries side:**
1. A Cloud Function that pushes **Approved bookings** (and later changes to them) to EventOS: one-way and temporary.
2. A Flutter **EventOS API client** that logs in with the user's existing Firebase session (token exchange). It is not used by any screen yet, except a small admin "EventOS connection" status tile.

The server side is built separately in the EventOS repo (`docs/cursor-prompts/M5-01-deploy-and-enquiries-bridge-EVENTOS.md`). **The contract in section 3 must match exactly.**

**Hard rules:**
- **Zero behaviour change** for existing users and screens. Sales, quotes, follow-ups, notifications and rules stay exactly as they are.
- **No writes from EventOS into Firestore.** Never block or slow an enquiry save. The sync runs asynchronously in a trigger.
- **Do not deploy.** Follow `no-deploy-without-confirm.mdc`. Prepare the commands and stop.
- Don't loosen `firestore.rules`.

---

## 1. Cloud Function: `onEnquiryWrittenSyncEventOS`

### 1a. Trigger
- New file `functions/src/eventosSync.ts`. Export from `index.ts`.
- `onDocumentWritten({ document: "enquiries/{id}", region: "asia-south1", retry: true, secrets: [EVENTOS_FEED_SECRET], timeoutSeconds: 30, memory: "256MiB" })`.
- Also trigger on `enquiries/{id}/financial/summary` writes (a separate function `onEnquiryFinancialWrittenSyncEventOS`) so money changes sync too. Both call the same `syncEnquiryToEventOS(enquiryId)` handler, which **re-reads the current enquiry, its functions and its financial summary** (never trust the trigger's before/after snapshot for the payload). That keeps both triggers consistent and ordering-safe.

### 1b. When to send
Send if **any** of these is true:
- the current canonical status (`statusVocabulary`) is `approved` or `completed`, or
- the enquiry was previously synced (a field `eventosSync.syncedAt` exists on a **private** doc, see 1d) and anything relevant changed, including the status moving to `cancelled` or any other status.

Otherwise do nothing. Never send `new`/`contacted`/`quoted` enquiries that were never approved.

"Relevant change" = customer name/phone/email, event type, dates, functions, locations, guest count, notes, assignee, status, or money. Compute a **stable hash** of the payload, excluding `sourceUpdatedAt`. If it equals the last sent hash, skip (prevents loops and noise).

### 1c. Payload (exact contract, `schemaVersion: 1`)
```json
{
  "schemaVersion": 1,
  "source": "wedecor-enquiries",
  "enquiryId": "<doc id>",
  "sourceUpdatedAt": "<enquiry.updatedAt ISO, fallback statusUpdatedAt, fallback createdAt>",
  "status": "<canonical status value>",
  "customer": { "name": "...", "phone": "<normalizePhone → +91XXXXXXXXXX or null>", "email": "... | null" },
  "event": {
    "eventType": "...", "eventTypeLabel": "...",
    "startDate": "YYYY-MM-DD", "endDate": "YYYY-MM-DD",
    "guestCount": 0, "notes": "... | null", "assigneeName": "... | null"
  },
  "functions": [
    { "functionId": "...", "eventType": "...", "eventTypeLabel": "...",
      "date": "YYYY-MM-DD", "time": "HH:mm | null",
      "location": "... | null", "locationArea": "... | null",
      "locationAddress": "... | null", "locationPlaceId": "... | null",
      "lat": 0, "lng": 0, "notes": "... | null" }
  ],
  "money": { "totalCost": 0, "advancePaid": 0, "currency": "INR" }
}
```
- Build `functions` from the existing `eventFunctions.ts` normaliser (it already synthesises a single function from top-level fields for old enquiries). `startDate`/`endDate` = min/max function date.
- **Dates are IST calendar dates.** Use `istTime.ts` helpers (`istDayStart` / `istShortDate`) to turn Timestamps into `YYYY-MM-DD`. Never use the UTC date of a local-midnight timestamp.
- Include `lat`/`lng` only if the location data has them (the website places payload and the Maps picker store them). Otherwise send `null`.
- `money` comes from `financial/summary` (admin SDK can read it). Omit the key if the doc is missing.
- Put the payload builder in a pure function `buildEventOSPayload(enquiry, functions, financial)` with unit tests.

### 1d. Sending
- Secrets: `defineSecret("EVENTOS_FEED_SECRET")`. Non-secret config in `functions/.env`: `EVENTOS_FEED_URL` (staging/prod). If the URL is empty → log `eventos_sync_disabled` once and return (a safe default).
- Headers: `Content-Type: application/json`, `X-EventOS-Timestamp: <unix seconds>`, `X-EventOS-Delivery-Id: <event.id from the trigger, so retries reuse the same ID>`, `X-EventOS-Signature: v1=<hex HMAC-SHA256(secret, timestamp + "." + rawBody)>`. Sign the **exact bytes** you send.
- 10 s timeout. On a 5xx or network error → **throw** so Cloud Functions retries (`retry: true`). On 2xx → record success. On 4xx → **don't retry**: log `eventos_sync_rejected` with the status and response code, and record the failure.
- Retry guard: if the event is older than 24 h, drop it with an error log (avoid infinite retries).
- Sync bookkeeping in **`enquiries/{id}/private/eventosSync`** (a new private subdoc; add rules: **no client read/write**, admin SDK only): `{ syncedAt, lastHash, lastStatus, lastHttpStatus, lastError, eventosEventId }`. Never write to the enquiry document itself (that would retrigger `onEnquiryWrittenNotify` and this function).
- Logs: no phone, email or money in logs. Use the enquiry ID only. Use the existing logger conventions.

### 1e. Backfill + reconciliation script
`scripts/eventos/backfillApproved.ts` (tsx, admin SDK, run locally by the owner):
- Finds all enquiries with status `approved` or `completed` (plus `cancelled` ones that have an `eventosSync` doc), builds payloads with the same builder, and sends them through the same signer.
- Throttled to 5/s. Dry-run by default (prints counts plus 3 sample payloads with PII masked). `--apply` sends.
- Then calls EventOS `POST /api/v1/integrations/enquiries/backfill-check` (with an owner EventOS token passed by env var) and prints a reconciliation table: in Firebase, in EventOS, missing, stale.

### 1f. Tests
- Unit: payload builder (single and multi-function, missing location, IST dates around midnight, money present/absent), hash stability, the "should send" decision table (never-approved → skip; approved → send; previously synced → cancelled sends; unchanged hash → skip).
- Signature: matches a known test vector (share it with the EventOS repo: secret `test_secret`, timestamp `1700000000`, body `{"a":1}` → document the expected hex in both repos' tests).
- Firestore rules test (`rules-tests/`): clients can't read or write `enquiries/{id}/private/eventosSync` (admin, staff, unauthenticated all denied).
- An emulator test where the trigger fires and the HTTP call is mocked: success writes bookkeeping; 500 throws; 400 doesn't throw.

---

## 2. Flutter: EventOS API client (no user-facing changes)

### 2a. Package and structure
- New folder `lib/core/eventos/` containing `eventos_config.dart` (base URL per flavour/env, from `--dart-define=EVENTOS_API_URL=...`, empty = disabled), `eventos_auth.dart`, `eventos_client.dart`, `eventos_providers.dart` (Riverpod).
- HTTP: use the existing `http` package. Don't add a new HTTP stack unless needed. Add `flutter_secure_storage` for the refresh token.

### 2b. Auth flow
1. When the user is signed into Firebase and EventOS is enabled: get `FirebaseAuth.instance.currentUser!.getIdToken(true)` → `POST /api/v1/auth/firebase/exchange` `{ idToken, client: "mobile" }`.
2. Response `{ accessToken, expiresIn, refreshToken, user: { id, name, role, permissions } }`. Keep the **access token in memory only**, and the **refresh token in `flutter_secure_storage`** (Android Keystore, `encryptedSharedPreferences: true`).
3. The client attaches `Authorization: Bearer`. On a 401 → refresh once via `POST /api/v1/auth/refresh { refreshToken }` (store the rotated token) → retry once. If the refresh fails → redo the Firebase exchange once. If that fails → mark EventOS as `disconnected`, with no retry storm.
4. On Firebase sign-out → clear EventOS tokens and secure storage, and call EventOS logout (best effort).
5. A `403 IDENTITY_NOT_LINKED` result → status `not_linked`. Show this only on the admin tile. Never block the app.
6. **Lazy:** don't exchange at app start for everyone. Exchange the first time an EventOS feature or the status tile is used, so there's no startup delay or network cost.

### 2c. Admin status tile
In the existing admin/settings area (admin role only): an "EventOS connection" tile showing environment, connection state (`disabled`/`connected`/`not_linked`/`disconnected`), the linked EventOS user and role, and a **"Test connection"** button (calls `GET /api/v1/auth/me` or the existing profile endpoint). Match the existing design system. **No new colours or styles** (follow `.cursor/rules/flutter-design-protocol.mdc`).

### 2d. Security
- Never log tokens. Add them to the existing log redaction.
- Certificate validation stays default (no `badCertificateCallback`).
- `EVENTOS_API_URL` must be `https://` in release builds. Assert this at startup in release mode, and if it isn't → disable EventOS.

### 2e. Tests
Unit tests with a mocked HTTP client: exchange success; 401 → refresh → retry; refresh fail → re-exchange; not linked; sign-out clears storage; tokens never appear in logs (logger spy). Widget test for the status tile states.

---

## 3. Contract (must match the EventOS repo)
- `POST {EVENTOS_FEED_URL}` = `https://api.wedecorevents.com/api/v1/integrations/enquiries/sync` (staging: `https://api-staging.wedecorevents.com/...`)
- Headers `X-EventOS-Timestamp`, `X-EventOS-Signature: v1=<hex>`, `X-EventOS-Delivery-Id`; HMAC over `${timestamp}.${rawBody}`
- Payload: section 1c
- Login exchange: `POST /api/v1/auth/firebase/exchange`; refresh: `POST /api/v1/auth/refresh`
- Copy the final contract into `docs/integrations/eventos-bridge-contract.md` (keep it identical to the EventOS repo copy)

## 4. Out of scope
Moving any screen's data from Firestore to EventOS, gig/worker features, FCM changes, any change to the existing website lead flow.

## 5. Deliverables
1. `functions/src/eventosSync.ts` (+ export), the private subdoc rule + rules tests, the backfill script, function tests
2. `lib/core/eventos/*`, the admin status tile, Flutter tests
3. `functions/.env.example` and README updates (secret setup: `firebase functions:secrets:set EVENTOS_FEED_SECRET`)
4. `flutter analyze`, `flutter test`, functions build/tests and rules tests all green
5. **Deployment plan only (don't execute):** exact commands for staging then prod, the order (EventOS API first → functions → app release), and rollback (unset `EVENTOS_FEED_URL` = instant off switch)
6. Report `docs/reports/M5-01-EventOS-Bridge-Report.md`: what changed, a security review (HMAC, private bookkeeping, token storage), and a test summary
