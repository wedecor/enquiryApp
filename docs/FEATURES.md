# We Decor Enquiries — Feature Specification

Version: 1.0.0  
Date: 2025-09-22  
Owner: We Decor Product & Engineering

## Table of Contents
1. Executive Summary
2. Personas & Roles
3. Information Architecture
4. Feature Catalog
   4.1 Authentication & Session
   4.2 Users & Roles
   4.3 Enquiry Intake
   4.4 Enquiry Details
   4.5 Lifecycle & Workflows
   4.6 Search, Filters & Sorting
   4.7 Notifications
   4.8 Dashboard & Analytics
   4.9 Admin Console
   4.10 Export & Reporting
5. Data Model
6. Security & Compliance
7. Offline & Performance
8. Accessibility & UX
9. Testing Strategy
10. Environments & DevOps
11. Internationalization & Theming
12. Notifications & Automation
13. Roadmap & Phasing
14. Open Questions & Assumptions
15. Change Log / Revision History

---

## 1. Executive Summary
- Goal: Single source of truth spec for We Decor Enquiries (Flutter + Riverpod, Firebase Auth/Firestore). Mobile and Web with Material 3 and dark mode.
- Non-goals: Payments, complex CRM, vendor ops, advanced RBAC beyond Admin/Staff, external search engine in MVP.
- Guiding principles:
  - Least privilege: Staff may update only status fields when assignee == self. Admin has full edit.
  - Reliable workflows with optimistic UI + Undo for status updates.
  - Privacy-first handling of PII, with denormalized display fields for performance.

## 2. Personas & Roles

- Admin: Manages enquiries, users, dropdowns. Full CRUD on enquiries and dynamic options; can export CSV.
- Staff: Global read-only for enquiries; can update status only when `assignee == request.auth.uid`.

Permissions Matrix

| Capability | Admin | Staff |
| --- | --- | --- |
| Sign in | Yes | Yes |
| View enquiries | Yes | Yes (global read) |
| Create enquiry | Yes | No |
| Edit enquiry fields | Yes (all fields) | No |
| Update status | Yes | Yes (only if assignee == self) |
| Assign/unassign staff | Yes | No |
| Manage dropdowns | Yes | No |
| Manage users (activate/deactivate) | Yes | No |
| Export CSV | Yes (Admin-only) | No |

Notes:
- Staff read scope is global to support collaboration; write scope is limited (see rules).

## 3. Information Architecture

Entities:
- users/{uid}: name, phone, email, role, isActive
- enquiries/{id}: customer fields, event fields, status, assignee, denormalized names, audit, timestamps
- dropdowns/{group}/items/{id}: dynamic options

Relationships:
- enquiries.assignee → users.uid
- denormalized: enquiries.createdByName, enquiries.assigneeName for UI/export

## 4. Feature Catalog

### 4.1 Authentication & Session
Description: Email/password, session restoration, password reset; Firebase lockout defaults apply.

User Stories:
- Given a valid account, when I open the app, then my session restores.
- Given I forgot my password, when I request reset, then I receive an email.

Acceptance Criteria:
1) AC-Auth-1: Email/password sign-in shows clear errors on failure.
2) AC-Auth-2: Session persists until sign-out/expiry.
3) AC-Auth-3: Reset email sent to account email.
4) AC-Auth-4: Sign-out clears session and returns to login.

Schema/Permissions/UX/Test Notes: unchanged from prior; see Testing Strategy.

### 4.2 Users & Roles
Description: Maintain users with role (admin|staff) and activation.

User Stories:
- Admin sets user role and activation.
- Staff views profile.

Acceptance Criteria:
1) AC-User-1: Admin sets role (admin|staff).
2) AC-User-2: Deactivated users cannot sign in (checked via claims/rules).
3) AC-User-3: Profile shows name, email, phone, role.

### 4.3 Enquiry Intake (Admin)
Description: Create enquiries with validation, duplicates warning, optional attachments.

User Stories:
- Admin creates enquiry with mandatory fields.
- Admin warned for duplicates in last 90 days by phone/email.

Acceptance Criteria:
1) AC-Intake-1: Required: customerName, (customerPhone or customerEmail), eventType, eventDate.
2) AC-Intake-2: Duplicate window 90 days using `phoneNormalized` OR `customerEmail` (lowercased) + createdAt range.
3) AC-Intake-3: Attachments ≤ 5MB, type `image/*` or `application/pdf`, max 10.
4) AC-Intake-4: Source from dropdowns; createdAt/updatedAt server timestamps.

UX/Edge: Duplicate warning non-blocking; image compression suggested client-side before upload.

### 4.4 Enquiry Details
Description: Read-only fields; inline status (Staff/Admin) with optimistic update + Undo; Admin full edit mode (Save/Cancel) on same screen; activity log.

User Stories:
- Staff quickly updates status if assigned.
- Admin edits all fields inline.

Acceptance Criteria:
1) AC-Details-1: All fields rendered, including denormalized names.
2) AC-Details-2: Inline status optimistic write; show Undo 5s.
3) AC-Details-3: Persist `status`, `statusUpdatedAt` (server), `statusUpdatedBy` (uid).
4) AC-Details-4: Admin edit mode toggles inputs; Save/Cancel.
5) AC-Details-5: Activity log records status changes (who, when, from→to).

Permissions:
- Staff: status only, and only if assignee == self; control disabled otherwise.
- Admin: full edit.

UX Notes:
- If not assignee (Staff), show disabled status control with tooltip: “Only the assigned user can change status.”
- Undo performs a second write (revert) and appends an audit entry.
- Call/WhatsApp buttons shown when phone exists.

Analytics:
- enquiry_status_changed { from,to,enquiryId }
- enquiry_edit_saved { enquiryId, fieldsChanged[] }

### 4.5 Lifecycle & Workflows
Status values (exact): `new`, `contacted`, `quoted`, `confirmed`, `in_progress`, `completed`, `cancelled`.

Allowed transitions (Staff UI; Admin may set any):
- new → contacted, cancelled
- contacted → quoted, cancelled
- quoted → confirmed, cancelled
- confirmed → in_progress, cancelled
- in_progress → completed, cancelled
- completed, cancelled → terminal

Acceptance Criteria:
1) AC-Lifecycle-1: Staff sees only allowed next statuses.
2) AC-Lifecycle-2: Admin can set any valid status.
3) AC-Lifecycle-3: Each change writes status + statusUpdatedAt (server) + statusUpdatedBy + audit.
4) AC-Lifecycle-4: When status becomes contacted/quoted and followUpDate empty, suggest +3 days.
5) AC-Lifecycle-5: Staff may change status only when assignee == current user (UI disabled and rule blocks otherwise).

### 4.6 Search, Filters & Sorting
Description: Hybrid approach: server-side filters on indexed fields; client substring via denormalized `textIndex`.

Filters:
- status (multi), date range (eventDate/createdAt), eventType, assignee, location (contains), budgetRange (exact), text (name/phone/email/notes).

Sorting:
- createdAt desc (default), eventDate, customerName (via `customerNameLower`).

Acceptance Criteria:
1) AC-Search-1: Combining filters narrows results.
2) AC-Search-2: Sorting persists across pagination.
3) AC-Search-3: Text search matches case-insensitive substrings.
4) AC-Search-4: Case-insensitive search uses `textIndex`; name sort uses `customerNameLower`.

Server vs Client:
- Server filters: status, eventType, assignee, date ranges, plus textIndex prefix if later indexed.
- Client substring: `textIndex` (lowercased concatenation) for basic search in MVP.

### 4.7 Notifications
Description: FCM for mobile; WhatsApp deep link for manual follow-ups; operational subscriptions.

Operations:
- Subscribe to `user_{uid}` on login; unsubscribe on logout.
- Daily digest via Cloud Scheduler (cron 09:00 Asia/Kolkata) → Cloud Function sends counts by status to Admins.

Acceptance Criteria:
1) AC-Notif-1: On assignment, push to `user_{uid}` with enquiryId, customerName, eventType.
2) AC-Notif-2: WhatsApp deep link `wa.me/<phone>?text=<tmpl>` opens correctly.
3) AC-Notif-3: Web gracefully no-op unsupported topic APIs.
4) AC-Notif-4: Throttle: ≤1 FCM per enquiry per 10 minutes per channel.

### 4.8 Dashboard & Analytics
KPIs:
- New enquiries, In Progress, Completed, Conversion rate (quoted→confirmed→completed), Time-to-first-contact, by eventType/source/assignee.
Charts:
- Time series by status; breakdown by eventType/source/assignee.

Acceptance Criteria:
1) AC-Dash-1: Cards reflect selected range filters.
2) AC-Dash-2: Admin can filter by assignee.

### 4.9 Admin Console
Features:
- Dropdowns CRUD (event types, statuses, payment statuses).
- User management: role and activation.
- Bulk assign/unassign.
- Rebuild denormalized names (background job) when a user’s display name changes.

Acceptance Criteria:
1) AC-Admin-1: CRUD for dropdowns.
2) AC-Admin-2: Set role, toggle isActive; trigger denorm rebuild when needed.

### 4.10 Export & Reporting
- Admin-only CSV export for date range with active filters.
- Include denormalized fields: assigneeName, createdByName; ISO 8601 timestamps.

Acceptance Criteria:
1) AC-Export-1: Export respects active filters.
2) AC-Export-2: Timestamps in ISO 8601.
3) AC-Export-3: Export available to Admin only (hidden in UI and blocked by rules).

## 5. Data Model

Enquiries Collection (enquiries/{id})

| Field | Type | Required | Notes |
| --- | --- | --- | --- |
| customerName | string | Y |  |
| customerNameLower | string | Y | lowercased for sorting/search |
| customerPhone | string | N | E.164 |
| phoneNormalized | string | N | digits-only for dedupe/index |
| customerEmail | string | N | lowercased for dedupe/search |
| eventType | string | Y | dropdown |
| eventDate | timestamp | Y |  |
| location | string | N |  |
| guestCount | number | N |  |
| budgetRange | string | N | e.g., 50k–1L |
| status | string | Y | exact set defined |
| assignee | string | N | users.uid |
| assigneeName | string | N | denormalized for UI/export |
| notes | string | N |  |
| source | string | N | dropdown |
| tags | array<string> | N |  |
| followUpDate | timestamp | N |  |
| attachments | array<object> | N | {name,url,size,type} |
| createdBy | string | Y | uid |
| createdByName | string | Y | denormalized |
| createdAt | timestamp | Y | serverTimestamp |
| updatedAt | timestamp | Y | serverTimestamp |
| statusUpdatedAt | timestamp | N | serverTimestamp on change |
| statusUpdatedBy | string | N | uid |
| textIndex | string | N | join: name/phone/email/notes lowercased |

Users Collection (users/{uid})

| Field | Type | Required | Notes |
| --- | --- | --- | --- |
| name | string | Y |  |
| email | string | Y |  |
| phone | string | N |  |
| role | string | Y | admin|staff |
| isActive | bool | Y | default true |

Dropdowns (dropdowns/{group}/items/{id})

| Field | Type | Required | Notes |
| --- | --- | --- | --- |
| value | string | Y | key |
| label | string | Y | display label |
| order | number | N | sort order |
| active | bool | Y | default true |

Audit (activity subcollection): type, from, to, by, at, notes

Indexes (composite examples):
- [status asc, createdAt desc]
- [assignee asc, status asc, createdAt desc]
- [eventType asc, createdAt desc]
- [eventDate desc]
- [phoneNormalized asc, createdAt desc]
- [customerNameLower asc]

## 6. Security & Compliance

Firestore Rules (policy excerpts):
- Staff can update only status fields and only when assignee == self; Admin full control; global read for authed users.

```rules
rules_version = '2';
service cloud.firestore {
  match /databases/{db}/documents {
    function isAdmin() { return request.auth.token.role == 'admin'; }
    function isStaff() { return request.auth.token.role == 'staff'; }
    function isAssignee(resource) { return resource.data.assignee == request.auth.uid; }

    match /enquiries/{id} {
      allow read: if request.auth != null; // global read for authed users
      // Staff: only status fields AND only if assignee==self
      allow update: if isStaff()
        && isAssignee(resource)
        && request.resource.data.diff(resource.data).affectedKeys()
             .hasOnly(['status','statusUpdatedAt','statusUpdatedBy']);
      // Admin: full control
      allow create, update, delete: if isAdmin();
    }

    match /users/{uid} {
      allow read: if request.auth != null && (isAdmin() || request.auth.uid == uid);
      allow update: if isAdmin();
    }
  }
}
```

Storage Rules (attachments):

```rules
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /attachments/{enquiryId}/{fileName} {
      allow read: if request.auth != null;
      allow write: if request.auth != null
        && request.resource.size < 5 * 1024 * 1024
        && (request.resource.contentType.matches('image/.*')
            || request.resource.contentType == 'application/pdf');
    }
  }
}
```

PII Handling: collect minimal PII; limit exports to Admin; backups encrypted; access least-privileged.

Retention: keep enquiries & audit 24 months; archive via scheduled job.

## 7. Offline & Performance
- Firestore cache enabled; optimistic writes with retry for status; conflict resolution favors latest write.
- Use `withConverter` for type-safety; batch admin edits where applicable.
- Performance budgets: cold start ≤ 2.5s (mid-range Android), list scroll ≥ 55 FPS, Firestore list fetch p95 ≤ 800ms on Wi‑Fi.
- Attachments: ≤ 5MB; compress images client-side before upload.

## 8. Accessibility & UX
- Touch targets ≥ 44×44.
- Visible focus rings; logical focus order; keyboard navigation on web.
- Proper semantics for chips/dropdowns; screen reader labels on actions.
- Snackbar is announced to assistive tech; high contrast in light/dark.

Accessibility Checklist:
- Contrast meets WCAG AA.
- Focus order logical; focus ring visible.
- Semantics on interactive controls.
- Motion respects OS reduced motion.

## 9. Testing Strategy
- Unit: repositories, mappers, `statusTransitionValidator`.
- Widget: role-gated UI, inline status optimistic update + Undo, disabled control when not assignee.
- Integration/E2E: admin edit flow; rules enforcement (assigned vs not assigned); CSV export; emulator-based rules tests.
- Performance: cold start timing; list scroll FPS; Firestore fetch p95.

## 10. Environments & DevOps
- Envs: dev/stage/prod (separate Firebase projects).
- CI: analyze, test, coverage; deploy on tag.
- Firebase Emulator Suite for local dev and rules tests.
- Feature flags via Remote Config for optional digests/notifications.

## 11. Internationalization & Theming
- Material 3; light/dark themes validated for contrast.
- Strings organized for future i18n.

## 12. Notifications & Automation
- FCM topics: `user_{uid}`; subscribe on login, unsubscribe on logout.
- Daily digest at 09:00 IST via Cloud Scheduler → Cloud Function to admins; includes counts by status for previous day.
- Throttling: ≤1 notification per enquiry per 10 minutes per channel.
- WhatsApp deep links for manual follow-up: `https://wa.me/<digits>?text=<encoded>`.

## 13. Roadmap & Phasing
- P0: Auth, Enquiry intake (admin), Details with inline status, Search/filters, Dashboard cards, Admin dropdowns, CSV export, Rules, Audit.
- P1: Attachments upload, Advanced analytics, Daily digest, i18n groundwork, denorm rebuild job.
- P2: Bulk actions, Advanced reporting, Archival automation, SLA metrics, search engine evaluation (Algolia/Meilisearch).

## 14. Open Questions & Assumptions
Assumptions:
- Staff read is global; write only when assigned.
- Follow-up suggestion (+3 days) is non-blocking and can be dismissed.
- Duplicate detection 90 days window.
- Denormalized names kept in sync via background job.

Open Questions:
- Do we need redaction options for CSV exports shared outside the org?
- Is per-field edit history required beyond activity log?

## 15. Change Log / Revision History
- 2025-09-22: Initial comprehensive spec updated with denormalized fields, search/indexes, rules, storage policy, performance budgets, accessibility checklist, and operational notifications.
