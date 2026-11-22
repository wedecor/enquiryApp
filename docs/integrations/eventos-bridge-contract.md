# Enquiries Bridge Contract (M5-01)

> **TEMPORARY.** ADR-019 phase 3 retires this bridge when EventOS becomes the system of
> record. Until then two integration points connect the We Decor **Enquiries** app (Firebase
> project `wedecorenquries`) to EventOS:
>
> 1. **Login bridge** — `POST /api/v1/auth/firebase/exchange` swaps a Firebase ID token for a
>    normal EventOS session.
> 2. **Booking feed** — `POST /api/v1/integrations/enquiries/sync` receives approved/changed/
>    cancelled enquiries as signed deliveries and mirrors them into EventOS bookings.

Base URLs: prod `https://api.wedecorevents.com`, staging `https://api-staging.wedecorevents.com`
(all paths below are under `/api/v1`). The tenant is always resolved server-side
(`ENQUIRIES_FEED_TENANT_ID` for the feed, the single Phase 1 tenant for login) — never from a
request body or header.

---

## 1. Login bridge

### `POST /api/v1/auth/firebase/exchange` (public)

```json
{ "idToken": "<Firebase ID token>", "client": "mobile" }
```

- `idToken` (required, ≤ 4096 chars). `client` is optional: `"mobile"` or `"web"`.
- Server checks: signature, expiry, **revocation**, audience/issuer for project
  `FIREBASE_PROJECT_ID` (default `wedecorenquries`), `iat` no older than 5 minutes.
  Verification uses Application Default Credentials (Cloud Run service account with
  `roles/firebaseauth.viewer`); there is no key file.
- The Firebase `uid` must be **linked** to an EventOS user (§3). Otherwise
  `403 IDENTITY_NOT_LINKED`. Disabled EventOS users get `403 FORBIDDEN`.
- Success is the same envelope as `POST /auth/login`: `{ "data": { "accessToken", "expiresIn" } }`.
  The refresh token is always set as the `HttpOnly` refresh cookie; with `client: "mobile"`
  it is **also** returned in the body (`refreshToken`) because a native client has no cookie jar.
- Refresh and logout use the existing `POST /auth/refresh` and `POST /auth/logout`.
- Rate limit: 10 requests/minute per client IP. Invalid/expired tokens return
  `401 UNAUTHENTICATED` with a generic message.
- Errors use the standard envelope `{ "error": { "code", "message", "details", "requestId", "path" } }`.

---

## 2. Booking feed

### Request

`POST /api/v1/integrations/enquiries/sync` with `Content-Type: application/json`.

| Header | Value |
| --- | --- |
| `X-EventOS-Timestamp` | Unix seconds when the delivery was signed. Rejected if more than **300 s** from server time. |
| `X-EventOS-Signature` | `v1=<lowercase hex HMAC-SHA256(secret, timestamp + "." + rawBody)>` |
| `X-EventOS-Delivery-Id` | UUID unique per delivery attempt *series* (reuse the same id when retrying the same payload). Replay-protected for 24 h. |

`rawBody` is the exact byte string sent on the wire — sign it after serialising, do not
re-serialise. Example (Node):

```ts
import { createHmac, randomUUID } from 'node:crypto';

const body = JSON.stringify(payload);
const timestamp = Math.floor(Date.now() / 1000).toString();
const signature = 'v1=' + createHmac('sha256', secret).update(`${timestamp}.${body}`).digest('hex');
await fetch(`${base}/api/v1/integrations/enquiries/sync`, {
  method: 'POST',
  headers: {
    'content-type': 'application/json',
    'x-eventos-timestamp': timestamp,
    'x-eventos-signature': signature,
    'x-eventos-delivery-id': randomUUID(),
  },
  body,
});
```

The secret is `ENQUIRIES_FEED_SECRET` (≥ 32 chars). **Staging and production use
separate Secret Manager secrets** — never share an HMAC key across environments:

| Environment | Secret Manager name |
| --- | --- |
| Staging | `eventos-staging-enquiries-feed-secret` |
| Production | `eventos-prod-enquiries-feed-secret` |

During rotation the server also accepts `ENQUIRIES_FEED_SECRET_NEXT` (Secret Manager
`eventos-<env>-enquiries-feed-secret-next`). The signature is checked in constant time
against every configured secret for that environment only.

### Payload (schema version 1, strict — unknown keys are rejected except inside `raw`)

```json
{
  "schemaVersion": 1,
  "source": "wedecor-enquiries",
  "enquiryId": "enq_8f2c…",
  "sourceUpdatedAt": "2026-11-23T10:15:30+05:30",
  "status": "approved",
  "customer": { "name": "Asha Rao", "phone": "+91 98765 43210", "email": "asha@example.com" },
  "event": {
    "eventType": "wedding",
    "eventTypeLabel": "Wedding",
    "startDate": "2026-12-12",
    "endDate": "2026-12-14",
    "guestCount": 350,
    "notes": "Prefers pastel palette",
    "assigneeName": "Ravi"
  },
  "functions": [
    {
      "functionId": "fn_1",
      "eventType": "haldi",
      "eventTypeLabel": "Haldi",
      "date": "2026-12-12",
      "time": "10:30",
      "location": "Lotus Gardens",
      "locationArea": "Banjara Hills",
      "locationAddress": "Road 12, Hyderabad",
      "locationPlaceId": "ChIJ…",
      "lat": 17.41,
      "lng": 78.44,
      "notes": "Outdoor"
    }
  ],
  "money": { "totalCost": 450000, "advancePaid": 150000, "currency": "INR" },
  "raw": {}
}
```

| Field | Rules |
| --- | --- |
| `schemaVersion` | literal `1` |
| `source` | literal `"wedecor-enquiries"` |
| `enquiryId` | 1–256 chars; stable identity of the enquiry |
| `sourceUpdatedAt` | ISO-8601 with offset; **ordering key** |
| `status` | 1–64 chars; see §Status mapping |
| `customer.name` | required; `phone` (≤ 40) and `email` (≤ 254) optional |
| `event.startDate` / `endDate` | `YYYY-MM-DD` IST calendar dates, `endDate ≥ startDate` |
| `functions[]` | ≤ 100, unique `functionId`; `date` `YYYY-MM-DD`, `time` `HH:mm` (IST), `lat` −90…90, `lng` −180…180 |
| `money` | optional (`totalCost` / `advancePaid` ≥ 0, ISO 4217 `currency`); later deliveries omitting it keep the previous value |
| `raw` | opaque; kept in the link record for debugging only |

### Response

| HTTP | Body | Meaning / sender action |
| --- | --- | --- |
| 200 | `{ "ok": true, "eventId": "<uuid>" }` | Applied (created or updated). |
| 200 | `{ "ok": true, "ignored": "stale" }` | `sourceUpdatedAt` is not newer than what EventOS holds. Done. |
| 200 | `{ "ok": true, "ignored": "not_approved_never_synced" }` | First sight of an enquiry that is not approved. Done. |
| 200 | `{ "ok": true, "duplicate": true }` | Same `X-EventOS-Delivery-Id` already processed. Done. |
| 400 | error envelope `VALIDATION_ERROR` | Payload/headers invalid. **Do not retry unchanged.** |
| 401 | error envelope `INVALID_SIGNATURE` | Missing/expired/incorrect signature (reason never disclosed). |
| 429 | `RATE_LIMITED` | Limit is 120/min; back off. |
| 5xx | error envelope | Transient. **Retry** with the same delivery id (processing is idempotent). |

### Semantics

- **Idempotency & ordering.** A delivery is stale when `sourceUpdatedAt` ≤ the last applied
  value for that `enquiryId`. Each delivery is applied in one transaction, serialised per
  tenant by a Postgres advisory lock, so concurrent bursts are safe. The delivery-id ledger
  (Redis) is an optimisation and fails open if Redis is down.
- **Status mapping.** `approved` / `completed` create or update the EventOS booking and event.
  `cancelled` cancels the EventOS booking through the normal cancel flow with reason
  "Cancelled in Enquiries app". Other statuses never create anything; on an already-synced
  enquiry they leave the EventOS status untouched. A cancelled booking is never revived.
- **Customer.** Matched by E.164-normalised phone, then case-insensitive email; otherwise a
  new customer is created and flagged feed-managed. Feed-managed customers follow the source;
  pre-existing customers only get blank fields filled in.
- **Functions.** Matched by `functionId`. A function removed at the source is deleted, or marked
  `cancelled` if EventOS already uses it. The booking's venue name is the earliest function
  (date, then time) that has a location.
- **Notes.** EventOS stores `"[From Enquiries] " + event.notes` in the requirements notes.
- **Source ownership.** Synced bookings are **owned by Enquiries**: editing event type, dates,
  venue, guest count or requirements notes in EventOS through `PATCH /bookings/:id` returns
  `409 SOURCE_OWNED`. Other EventOS-side work (tasks, payments, vendors, status progression
  allowed by the booking workflow) is unaffected.
- **Money.** `money` is stored only on the external link record and is **not** part of any
  booking DTO. `GET /api/v1/integrations/enquiries/bookings/{bookingId}/financials` returns
  `{ bookingId, totalCost, advancePaid, currency, syncedAt }` to roles holding
  `integrations:financials:read` (finance, owner, admin).
- **PII.** Phone numbers are masked to the last four digits in logs; the signature header and
  Firebase ID tokens are fully redacted.

### Operator endpoints (JWT, permission `integrations:enquiries:manage` — owner/admin)

| Endpoint | Purpose |
| --- | --- |
| `GET /integrations/enquiries/status` | `lastDeliveryAt`, 24 h counts (`processed`/`stale`/`ignored`/`failed`), last 20 errors. Redis-backed: resets if Redis is flushed. |
| `POST /integrations/enquiries/backfill-check` | Body `{ "items": [{ "enquiryId", "sourceUpdatedAt" }] }` (≤ 1000). Returns `{ missing: string[], stale: string[], upToDate: number }`. The sender re-delivers the `missing` and `stale` ids. |

### Backfill procedure

1. In Enquiries, list all approved/completed/cancelled enquiries with their `updatedAt`.
2. Call `backfill-check` in batches of ≤ 1000.
3. Re-send each `missing` / `stale` enquiry through the normal signed feed (at most 120/min).
4. Re-run `backfill-check` until `missing` and `stale` are empty.

---

## 3. Identity linking (administrators)

A Firebase `uid` becomes an EventOS user through `ExternalIdentity` rows.

- `POST /api/v1/admin/external-identities` — `{ "userId", "provider": "firebase", "subject": "<uid>", "email"? }`
  (permission `users:write`, owner/admin). A uid already linked returns `409 DUPLICATE_IDENTITY`.
- `DELETE /api/v1/admin/external-identities/{id}` — unlink.
- Bulk: `apps/api/scripts/link-firebase-users.ts --file users.csv` (CSV header `uid,email,eventosRole,name`),
  **dry run by default**, `--apply` to write. Existing EventOS users are matched by email;
  unknown emails get a passwordless user with the CSV role. Conflicts are listed and skipped.

---

## 4. Versioning and retirement

- `schemaVersion` is part of the payload; an incompatible change adds `schemaVersion: 2`
  support first and keeps v1 until the sender has switched.
- The OpenAPI export (`apps/api/openapi/openapi.v1.json`) lists these endpoints under the
  *Integrations* and *Auth* tags.
- Retirement (ADR-019 phase 3): stop the sender, remove the `ENQUIRIES_FEED_*` secrets, drop
  the routes and (later) the `ExternalIdentity` / `ExternalRecordLink` tables with a dedicated,
  reviewed migration. Bookings keep their `source` value as history.
