# M5-01 — EventOS Bridge (Enquiries side)

## What changed

### Cloud Functions
- `onEnquiryWrittenSyncEventOS` and `onEnquiryFinancialWrittenSyncEventOS` push
  eligible enquiries to EventOS (`POST …/integrations/enquiries/sync`) with
  HMAC-SHA256 headers (`X-EventOS-Timestamp`, `X-EventOS-Signature`,
  `X-EventOS-Delivery-Id`).
- Pure payload builder + hash + send decision in `functions/src/eventosPayload.ts`.
- Bookkeeping in `enquiries/{id}/private/eventosSync` (Admin SDK only).
- Backfill script: `scripts/eventos/backfillApproved.ts` (dry-run default).

### Flutter
- `lib/core/eventos/*` — lazy Firebase → EventOS exchange, refresh, secure
  storage for refresh token, authenticated client with 401 recovery.
- Admin **Settings → Data → EventOS connection** tile (status + Test connection).
- Sign-out clears EventOS tokens (auth gate).

### Rules / docs
- `firestore.rules`: deny all client access to `enquiries/{id}/private/{docId}`.
- Contract copy: `docs/integrations/eventos-bridge-contract.md`.
- `functions/.env.example` + README secret/URL setup.

## Security review
- **HMAC:** sign exact raw body bytes; secret via Secret Manager only; never logged.
- **Private bookkeeping:** clients cannot read/write sync state; writing the enquiry
  doc itself is avoided so notify/follow-up triggers are not re-fired by sync.
- **PII in logs:** sync logs use enquiry id only (no phone/email/money).
- **Tokens:** access token in memory; refresh in `flutter_secure_storage`
  (`encryptedSharedPreferences: true`). Existing log redaction covers token keys
  and bearer strings. Certificate validation left default.
- **Release:** non-https `EVENTOS_API_URL` disables the client in release mode.
- **Off switch:** empty `EVENTOS_FEED_URL` → no HTTP calls.

## Behaviour impact
Zero change to existing enquiry UX, notifications, website leads, or staff flows
unless an enquiry is approved/completed (or previously synced) **and**
`EVENTOS_FEED_URL` is set.

## Test summary
See the final agent report in the PR / chat for exact command output
(`flutter analyze`, `flutter test`, `functions` build/test, rules tests).

## Deploy order (do not run until confirmed)
1. EventOS API already live for the target env.
2. Set `EVENTOS_FEED_SECRET` + `EVENTOS_FEED_URL` for functions; deploy functions
   (and rules if not already).
3. Ship app builds with `--dart-define=EVENTOS_API_URL=…` when the client is needed.
4. Link Firebase uids → EventOS users before expecting `Test connection` to succeed.
5. Optional: dry-run then `--apply` backfill.

Rollback: unset `EVENTOS_FEED_URL` and redeploy functions.
