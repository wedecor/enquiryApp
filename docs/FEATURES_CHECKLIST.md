## We Decor Enquiries — Delivery Checklist

Done Definition: A row is Done when:
- All referenced ACs are implemented and verified.
- Unit, widget, E2E tests pass in CI; analyzer clean.
- Firestore rules verified in Emulator Suite where applicable.
- Performance budgets met (cold start ≤2.5s; list ≥55 FPS; fetch p95 ≤800ms).
- Accessibility checklist passed (focus, contrast, semantics, touch targets).
- Product sign-off obtained.

|  | Feature | AC IDs | Owner | Unit | Widget | E2E | Rules Test | Notes |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| [ ] | Authentication & Session | AC-Auth-1, AC-Auth-2, AC-Auth-3, AC-Auth-4 |  |  |  |  |  |  |
| [ ] | Users & Roles — Role assignment | AC-User-1 |  |  |  |  |  |  |
| [ ] | Users & Roles — Deactivate users | AC-User-2 |  |  |  |  |  |  |
| [ ] | Users & Roles — Profile view | AC-User-3 |  |  |  |  |  |  |
| [ ] | Enquiry Intake — Validation | AC-Intake-1 |  |  |  |  |  |  |
| [ ] | Enquiry Intake — Duplicate detection | AC-Intake-2 |  |  |  |  |  |  |
| [ ] | Enquiry Intake — Attachments | AC-Intake-3 |  |  |  |  |  |  |
| [ ] | Enquiry Intake — Source tagging | AC-Intake-4 |  |  |  |  |  |  |
| [ ] | Enquiry Details — Display all fields | AC-Details-1 |  |  |  |  |  |  |
| [ ] | Enquiry Details — Inline status optimistic + Undo | AC-Details-2, AC-Lifecycle-3 |  |  |  |  |  |  |
| [ ] | Enquiry Details — Admin edit mode | AC-Details-4 |  |  |  |  |  |  |
| [ ] | Enquiry Details — Activity log | AC-Details-5 |  |  |  |  |  |  |
| [ ] | Lifecycle — Staff transition limits | AC-Lifecycle-1 |  |  |  |  |  |  |
| [ ] | Lifecycle — Admin transitions | AC-Lifecycle-2 |  |  |  |  |  |  |
| [ ] | Lifecycle — Server timestamps + by | AC-Lifecycle-3 |  |  |  |  |  |  |
| [ ] | Lifecycle — Follow-up suggestion | AC-Lifecycle-4 |  |  |  |  |  |  |
| [ ] | Lifecycle — Staff only if assignee==self | AC-Lifecycle-5 |  |  |  |  |  |  |
| [ ] | Search/Filters — Combine filters | AC-Search-1 |  |  |  |  |  |  |
| [ ] | Search/Filters — Sorting | AC-Search-2 |  |  |  |  |  |  |
| [ ] | Search/Filters — Text search | AC-Search-3 |  |  |  |  |  |  |
| [ ] | Search/Filters — textIndex + name sort | AC-Search-4 |  |  |  |  |  |  |
| [ ] | Notifications — Assignment push | AC-Notif-1 |  |  |  |  |  |  |
| [ ] | Notifications — WhatsApp deep link | AC-Notif-2 |  |  |  |  |  |  |
| [ ] | Notifications — Web graceful no-op | AC-Notif-3 |  |  |  |  |  |  |
| [ ] | Notifications — Throttling | AC-Notif-4 |  |  |  |  |  |  |
| [ ] | Dashboard — KPI cards | AC-Dash-1 |  |  |  |  |  |  |
| [ ] | Dashboard — Admin filters | AC-Dash-2 |  |  |  |  |  |  |
| [ ] | Admin Console — Dropdowns CRUD | AC-Admin-1 |  |  |  |  |  |  |
| [ ] | Admin Console — Users manage + denorm rebuild | AC-Admin-2 |  |  |  |  |  |  |
| [ ] | Export — Filter-respecting CSV | AC-Export-1 |  |  |  |  |  |  |
| [ ] | Export — ISO 8601 timestamps | AC-Export-2 |  |  |  |  |  |  |
| [ ] | Export — Admin-only | AC-Export-3 |  |  |  |  |  |  |

Rules Scenarios (must test in Emulator):
- Staff update when assignee != self → DENY.
- Staff update fields beyond status, statusUpdatedAt, statusUpdatedBy → DENY.
- Staff update status when assignee == self → ALLOW.
- Admin create/update/delete enquiries → ALLOW.
- Admin-only CSV export endpoint/guard → ENFORCED.
