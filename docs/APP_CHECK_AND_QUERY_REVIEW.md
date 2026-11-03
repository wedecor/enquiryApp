# P2 review — App Check, open-pipeline listeners, CSV export (Nov 2026)

This is a review only. Nothing in this branch enforces App Check or changes these queries.

## App Check

**Current state**

- Every callable sets `enforceAppCheck: false` and `cors: true`: `inviteUser`,
  `adminUpdateUser`, `lookupCustomer`, `notifyEnquiryEvent`, `approvedOnDate`,
  `placesAutocomplete`, `placeDetails` and `runReengagementNow`.
- The Flutter app does **not** depend on `firebase_app_check`, so no client sends a
  token today.
- `websiteLead`, `websiteFormOptions` and `websitePlaces*` are server-to-server
  endpoints protected by the shared secret. App Check does not apply to them.

**Why not enforce it now**

- Enforcing App Check before both clients attest would reject every callable for every
  user. That breaks invites, customer lookup, notifications, booking-clash checks and
  Places.
- Android is distributed as a sideloaded APK (Hosting `/android`), not through Play.
  The Play Integrity provider needs a Play-distributed build or registered debug tokens.
  The rollout below therefore has to confirm attestation on the real APK.
- Web needs a reCAPTCHA Enterprise site key for `wedecorenquries.web.app` and any
  custom domain.

**Rollout (when approved)**

1. Add `firebase_app_check` to the app and activate it in `main.dart` before the first
   callable: Play Integrity on Android, reCAPTCHA Enterprise on web, and debug
   providers in debug builds.
2. Register the Android app's SHA-256 and the web site key in the Firebase console
   (App Check).
3. Ship the build and watch the App Check metrics ("verified" vs "unverified" requests
   per service) for at least a week while enforcement is **off**.
4. If the sideloaded APK cannot attest with Play Integrity, decide between Play
   distribution (internal track) and staying unenforced. A custom provider is not
   recommended.
5. Only once both Android and web show more than 99% verified, flip `enforceAppCheck`
   to `true` one callable at a time, starting with `placesAutocomplete` and
   `placeDetails`, which carry billing risk.
6. Keep `cors: true` only where the web client needs it. Callables invoked through the
   Firebase SDK work with the default CORS settings.

**Compatibility risk:** app builds released before step 1 never send a token. Enforcing
App Check locks them out, so pair step 5 with a minimum-version prompt.

## Open-pipeline listeners

- `watchEnquiriesForRoleScope(active)` (dashboard and kanban) listens to every New,
  In Talks and Approved enquiry with **no limit**. Completed and lost slices are capped
  at 200.
- This branch makes the active set larger over time: past-event New/In Talks enquiries
  are no longer auto-closed. They stay open until staff record an outcome.
- Mitigations already in place:
  - Each open enquiry has a due follow-up, and admins are told when its event passes,
    so the set should not grow silently.
  - Staff listeners are scoped by `assignedTo`.
- **Recommendation (not done here):** add a Firestore `count()` of the active scope and
  log or alert above about 1,500 open enquiries. If it is reached, page the Approved
  slice by `eventDate` (only upcoming bookings in the live listener) before capping
  New/In Talks. Capping the open pipeline would hide work, so it is not done blindly.

## CSV export

- `FirestoreService.fetchEnquiriesForRole` reads every enquiry the user can see in one
  `get()`. Staff are scoped by `assignedTo`, and money fields are redacted client-side
  for staff.
- Cost is one read per exported document, which is expected for an export.
- The risk is memory and latency on very large sets, not correctness.
- **Recommendation:** when exports exceed a few thousand rows, page through
  `createdAt DESC` in chunks of 500 with `startAfterDocument` and stream rows into the
  CSV builder. Do not add a hard cap: a truncated export is worse than a slow one.

## Analytics (done in this branch)

- `analyticsRawRowsProvider` now refreshes incrementally after the first full read in a
  session; see `analytics_row_cache.dart`.
- A server-side precomputed snapshot remains the next step once the collection reaches
  tens of thousands of documents.
