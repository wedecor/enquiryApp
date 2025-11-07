## We Decor Enquiries — Feature List

Terminology: enquiry (not inquiry). Exact status values: new, contacted, quoted, confirmed, in_progress, completed, cancelled. Staff may update only status when assignee == self; Admin full edit.

### 4.1 Authentication & Session
- Email/password sign-in (Firebase Auth)
- Session restoration on app start
- Forgot password (reset email)
- Sign-out (clears session)
- Lockout per Firebase defaults

### 4.2 Users & Roles
- Users: name, email, phone, role, isActive
- Admin sets role (admin|staff) and activates/deactivates users
- Staff profile view (Settings > Account)
- Permissions via Firestore rules and/or custom claims

### 4.3 Enquiry Intake (Admin)
- Create enquiry with validation
- Required: customerName, phone OR email, eventType, eventDate
- Optional: location, guestCount, budgetRange, notes, source, tags, followUpDate
- Attachments: images/PDF ≤5MB each, max 10; client compress images
- Duplicate detection: 90 days by phoneNormalized OR customerEmail + createdAt
- Denormalize: createdBy, createdByName, assigneeName (optional assigneePhone)
- Server timestamps: createdAt, updatedAt

### 4.4 Enquiry Details
- Read-only view of all fields
- Show Assigned To / Created By as name · phone (denormalized fields)
- Inline status change (Staff/Admin)
  - Optimistic write + 5s Undo; second write for revert; audit entry
  - Writes status, statusUpdatedAt (server), statusUpdatedBy (uid)
  - Staff control disabled unless assignee == self (tooltip explains)
- Admin full edit mode on same screen (Save/Cancel)
- Activity log: status changes (who, when, from→to)
- Call/WhatsApp buttons when phone exists

### 4.5 Lifecycle & Workflows
- Staff transitions (admin may bypass):
  - new → contacted, cancelled
  - contacted → quoted, cancelled
  - quoted → confirmed, cancelled
  - confirmed → in_progress, cancelled
  - in_progress → completed, cancelled
  - completed/cancelled → terminal
- Auto write statusUpdatedAt/by; suggest followUpDate +3d for contacted/quoted
- Assignment (admin): assign/unassign staff + notify

### 4.6 Search, Filters & Sorting
- Server filters: status, eventType, assignee, date ranges
- Client substring search using textIndex (lowercased concat of name/phone/email/notes)
- Sorting: createdAt (default), eventDate, customerName (via customerNameLower)
- Pagination: infinite scroll (≈25/page)

### 4.7 Notifications
- Subscribe to user_{uid} on login; unsubscribe on logout
- Assignment push to assignee topic
- WhatsApp deep links with prefilled template
- Daily digest via Cloud Scheduler (09:00 IST) → Cloud Function to admins
- Throttle: ≤1 per enquiry per 10 minutes
- Web gracefully no-op unsupported topic APIs

### 4.8 Dashboard & Analytics
- KPIs: New, In Progress, Completed, Conversion rate, Time-to-first-contact
- Charts: time series by status; breakdown by eventType/source/assignee
- Admin filters by assignee/status/date; drill to filtered list

### 4.9 Admin Console
- Dropdowns CRUD (event types, statuses, payment statuses)
- User management (role, isActive)
- Bulk assign/unassign
- Rebuild denormalized names on user name change (background job)

### 4.10 Export & Reporting
- Admin-only CSV export (date range + active filters)
- Include denormalized: assigneeName, createdByName
- ISO 8601 timestamps

---

### Data Denormalization & Search Aids
- Enquiries include: createdBy, createdByName, assigneeName, customerNameLower, phoneNormalized, textIndex

### Compact Permissions Matrix

| Area | Action | Admin | Staff |
| --- | --- | --- | --- |
| Auth | Sign in/out | Yes | Yes |
| Users | View profile | Yes | Yes (self) |
| Users | Set role, activate/deactivate | Yes | No |
| Enquiries | Create | Yes | No |
| Enquiries | Read | Yes | Yes (global read) |
| Enquiries | Edit fields | Yes | No |
| Enquiries | Update status | Yes | Yes (only if assignee == self; fields: status, statusUpdatedAt, statusUpdatedBy) |
| Dropdowns | Manage | Yes | No |
| Export | CSV | Yes (Admin-only) | No |

### Filters & Sorting Matrix

| Field | Operators | Notes |
| --- | --- | --- |
| status | equals/in | Multi-select |
| createdAt | range | ISO 8601; server timestamp |
| eventDate | range | Date picker |
| eventType | equals | Dropdown |
| assignee | equals | User picker |
| location | contains | Client-side contains |
| budgetRange | equals | Discrete strings |
| textIndex | contains | Lowercased composite for client search |
| sort | orderBy | createdAt desc (default), eventDate, customerNameLower |

### Notifications Matrix

| Trigger | Channel | Payload | Notes |
| --- | --- | --- | --- |
| Assignment | FCM topic user_{uid} | enquiryId, customerName, eventType | Subscribe on login; unsubscribe on logout |
| Status change (optional) | FCM | enquiryId, from, to | Throttle ≤1/10m |
| Daily digest | Cloud Scheduler → Cloud Function → FCM/email | counts by status (previous day) | 09:00 IST, admins only |
| Follow-up message | WhatsApp deep link | wa.me/phone?text=tmpl | Manual action from UI |

### Constraints, Budgets, Accessibility
- Attachments ≤5MB; image/* or PDF; client compression before upload
- Performance budgets: cold start ≤2.5s (mid-range Android); list scroll ≥55 FPS; Firestore list fetch p95 ≤800ms on Wi‑Fi
- Accessibility: focus order, visible focus rings, semantics for chips/dropdowns, snackbar announced, touch targets ≥44×44
