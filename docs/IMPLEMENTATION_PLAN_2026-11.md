# Implementation plan — notifications, repeat enquiries, automatic follow-ups (Nov 2026)

Base: `feat/analytics-phase1` @ 2.0.27+58 (the code the 4 Nov 2026 assessment describes).
Work branch: `claude/ecstatic-mayer-e99cvh`, stacked on that branch.
Source of truth: the live `Enquiry` model, `firestore.rules` and `functions/src`. Not
`firestore_schema.dart` or `docs/FEATURE_MATRIX.md` (both describe an older model).

## 1. Current architecture (as implemented)

- **Client:** Flutter (Android + web), Riverpod 2 and Freezed. Feature folders live under
  `lib/features`. `FirestoreService` is the shared data path.
- **Data:** a single `enquiries` collection holds the whole booking: customer, status,
  money, `functions[]`, source and occasion stamps. `enquiries/{id}/history` is the
  append-only audit trail (`user_id` = actor). `enquiries/{id}/contacts` is the
  append-only call and WhatsApp log.
- **Customer identity:** `phoneNormalized` (last 10 digits). There is no customers
  collection. The `lookupCustomer` callable returns the customer's other enquiries,
  because staff can only read enquiries assigned to them.
- **Website intake:** `websiteLead` (POST, `X-Lead-Secret`, timing-safe compare).
  - The document id is `web_{externalId}`, written with `batch.create()`, so a retried
    delivery returns `200 {duplicate: true}` instead of creating a second enquiry.
  - A phone number that already exists still creates a new enquiry. Only the
    notification title changes, to "repeat customer".
- **Notifications:** writing `users/{uid}/notifications/{id}` triggers
  `sendNotificationToUser`, which sends FCM to the recipient's private tokens.
  - Server jobs (website, auto-expire, re-engagement) write these with the Admin SDK.
  - The app's `NotificationService` writes them **as the signed-in user** for create,
    assign, status change and edit.
- **Scheduled jobs:**
  - `autoExpireEnquiries` (every 4 h, IST): past event day moves New/In Talks to
    Not Interested and Approved to Completed.
  - `scheduleReengagements` (daily): yearly wishes.
- **Settings:** `app_config/{general|notifications|security|reengagement}`. Admins write
  them from Settings → Admin. `app_config/notifications.reminderDaysDefault` (default 3)
  is editable in the UI but nothing reads it yet.
- **Follow Up tab (dashboard, `reminders`):** shows In Talks enquiries whose event is
  0–20 days away and that have no `lastReminderSentAt`. Sending WhatsApp from the tab
  sets `lastReminderSentAt`. There is no due date, owner, push or overdue handling.

## 2. Files to modify

| Area | Files |
|---|---|
| P0 notifications | `firestore.rules`, `functions/src/notifications.ts` (new callable), `functions/src/index.ts`, `lib/core/services/notification_service.dart`, `rules-tests/spec/rbac_stable.spec.js` |
| Repeat enquiries | `functions/src/websiteLeads.ts` (extract a testable core, ignore self and merged docs in repeat detection), functions tests |
| Follow-ups | `functions/src/followUpsLogic.ts` (pure), `functions/src/followUps.ts` (trigger + scheduler), `firestore.rules`, `firestore.indexes.json`, `lib/features/enquiries/domain/follow_up.dart`, `lib/features/enquiries/data/follow_up_service.dart`, a follow-up card on the details screen, the dashboard Follow Up tab filter and action, `app_config` (`followUpsEnabled`) and the admin notification settings section |
| Auto-expire | `functions/src/autoExpireEnquiries.ts` |
| Analytics | `lib/features/admin/analytics/data/analytics_repository.dart` (incremental refresh) |
| Tests | `functions/test/**` (new, `node:test`, no new dependencies), `rules-tests/spec/rbac_stable.spec.js`, `test/features/**` |

## 3. Follow-up data model

### Options considered

- **A. Current state on the enquiry document (chosen).**
  - The dashboard and kanban already listen to the open pipeline, so due and overdue
    state costs no extra reads or listeners.
  - Staff scope is inherited from the enquiry rules for free.
  - Assignment changes need no syncing, because the reminder always goes to the
    enquiry's *current* `assignedTo`.
  - Status changes and terminal statuses are visible in the same document the
    scheduler reads, inside one transaction.
  - Cost: a few more fields on a busy document, and the scheduler writes to the
    enquiry (the Admin SDK does not bump `updatedAt`).
- **B. A `followUps/{id}` collection.**
  - Gives a clean queue and could hold several open follow-ups per enquiry.
  - But it duplicates the assignee and status, needs `get()` calls in the rules for staff
    scope, and needs a second listener on the dashboard.
  - Nothing in the business rules asks for more than one open follow-up per enquiry,
    so B is not justified.

History goes into the existing `enquiries/{id}/history` (`field_changed: "followUp"`), so
the details screen's history list shows it with no new collection.

### Fields on `enquiries/{id}`

All fields are optional. Absent means a legacy document.

| Field | Type | Written by | Meaning |
|---|---|---|---|
| `followUpDueAt` | Timestamp \| null | server, client | When the open follow-up is due. `null` means no open follow-up. |
| `followUpSeq` | int | server, client | Increments on every schedule, reschedule, complete or cancel. Part of the notification id, so a reminder for an old schedule can never fire. |
| `followUpReason` | `auto` \| `callback` \| `manual` \| `past_event` | server, client | Why it is due. |
| `followUpNotifiedStage` | null \| `due` \| `overdue` | server (clients may only reset it to `null`) | Which reminder has been sent for the current `followUpSeq`. |
| `followUpScheduledBy` | uid \| `system:followups` | server, client | Who set the due time. |
| `followUpNote` | string ≤ 300 | client | Callback note, e.g. "Call after 6 pm". |
| `followUpLastCompletedAt` / `followUpLastCompletedBy` | Timestamp / uid | client | Last completion. |
| `pastEventReviewAt` | Timestamp | server only | Set once when an open enquiry's last event day passes. |

### States (derived, never stored as a status)

- **Scheduled:** `followUpDueAt > now`.
- **Due:** `now ≥ followUpDueAt`.
- **Overdue:** `now ≥ followUpDueAt + overdueAfterHours`.
- **Completed:** `followUpLastCompletedAt` is set. A new follow-up is then scheduled
  automatically while the enquiry is still open.
- **Rescheduled:** a history entry with reason `callback` or `manual`.

### Notification idempotency

- Reminder documents use deterministic ids:
  `users/{uid}/notifications/fu_{enquiryId}_{seq}_{due|overdue}`.
- They are created with `create()` in the same transaction that sets
  `followUpNotifiedStage`. A retried job run either sees the stage already set, or fails
  with ALREADY_EXISTS, so each reminder is sent at most once per schedule.
- Rescheduling bumps `followUpSeq` and resets the stage, so the old reminder can never
  fire.

## 4. Reminder cadence (approved: every 3 days)

Server defaults below are overridable from `app_config/notifications` without a deploy:

| Setting | Default | Where admins change it |
|---|---|---|
| `followUpsEnabled` | `true` | Settings → Admin → Notifications (new toggle) |
| `reminderDaysDefault` | `3` | Settings → Admin → Notifications (existing field, now used) |
| `followUpDueHourIst` | `10` | Firestore console (`app_config/notifications`) |
| `followUpOverdueHours` | `24` | Firestore console |
| `followUpEligibleStatuses` | `["new","in_talks"]` | Firestore console |

Rules:

- **First follow-up:** `createdAt + reminderDaysDefault` days, at 10:00 IST.
- **Next follow-up:** `followUpLastCompletedAt + reminderDaysDefault` days, at 10:00 IST.
- **Multi-function enquiries:** the due time is capped at 10:00 IST on the day *before*
  the earliest **upcoming** function (Haldi before the Wedding), not the top-level
  `eventDate`, which is the *last* function. If that time has already passed, the
  follow-up is due now.
- **No upcoming function left:** due now, reason `past_event`.
- **Eligible statuses:** New and In Talks. Approved (already booked) and every terminal
  status get no follow-ups, and an open follow-up is cancelled, with history, when the
  enquiry leaves these statuses.
- **Recipients:** the current assignee. If the enquiry is unassigned, all active admins.
  Admins see every team member's due and overdue items in the app; staff see their own.
- **Overdue:** one overdue reminder 24 h after the due time. Nothing more until the
  follow-up is completed or rescheduled.
- **Flood guard:** at most 5 individual pushes per recipient per run. The rest are
  marked as notified and summarised in one "N more follow-ups due" notification, so the
  first run after deploy cannot flood a phone.
- **Scheduler:** every 15 minutes (`followUpReminders`), so a callback set for 15:30 is
  reminded by 15:45.
- **No WhatsApp.** Reminders are in-app and FCM only.

## 5. Migration and backwards compatibility

- **Legacy enquiries** have no follow-up fields.
  - The trigger schedules one on the enquiry's next write.
  - The scheduler also runs a one-time backfill over open enquiries. It is guarded by
    `app_config/followups_state.backfilledAt` and is idempotent per document.
  - Backfilled due times are never in the past: they are at least the next 10:00 IST
    slot. Combined with the flood guard, there is no burst of notifications.
- **Follow Up tab:** documents carrying `followUpSeq` use the new due/overdue rule.
  Documents without it keep the old rule until they are backfilled.
- **Notifications:** the app moves from client-written notifications to the
  `notifyEnquiryEvent` callable.
  - Old app builds keep writing directly. Once the new rules are deployed, those writes
    are rejected; the app catches and logs the error, and the enquiry save still succeeds.
  - **Deploy order:** functions first, then release the app and wait for staff to update,
    then deploy the rules. Between the two steps, both paths work.
- **Auto-expire:** no data migration. Enquiries already auto-closed stay closed;
  reopening them is a manual admin decision.
- **Website:** the payload, endpoint, secret, ids and responses are unchanged.

## 6. Phases and risks

| Phase | Change | Main risk | Mitigation |
|---|---|---|---|
| 0 | Functions test harness (`node:test` + Firestore emulator) | none | Uses existing firebase-tools and Java. |
| 1 (P0) | Server-built notifications; client create denied in rules | Old builds lose cross-user pushes after the rules deploy | Deploy order above. Server notifications are unaffected. |
| 2 | Repeat-enquiry tests and a small fix (repeat check ignores the lead itself and merged docs) | none | Behaviour already matches the business rule. |
| 3 | Follow-up trigger, scheduler, rules, UI | Trigger fires on every enquiry write | The plan function is pure and returns no-op unless state changes; config is cached per instance. |
| 4 | Auto-expire: flag open past events instead of closing them | Past-event open enquiries pile up in In Talks | They are due for follow-up, admins are notified once, and the dashboard shows them. |
| 5 | Analytics incremental refresh | Server writes that don't bump `updatedAt` (occasion stamps) | Manual refresh and a 6 h maximum age do a full reload. Deletes are detected with a `count()`. |
| 6 (P2) | Review only: open-pipeline listeners, CSV export, App Check | — | Documented in `docs/APP_CHECK_AND_QUERY_REVIEW.md`. Nothing is enforced. |

## 7. Manual deployment steps (nothing in this branch has been deployed)

Run these from a machine with `firebase login` for project `wedecorenquries`, in this
order:

1. **Indexes first.** Deploy them and wait until the new
   `enquiries (followUpNotifiedStage, followUpDueAt)` index shows *Enabled*:
   `firebase deploy --only firestore:indexes`
2. **Functions:** `npm --prefix functions run deploy`. The script lists every function,
   including the new `notifyEnquiryEvent`, `onEnquiryWrittenFollowUp` and
   `followUpReminders`. The changed functions are `autoExpireEnquiries`, `websiteLead`
   and `lookupCustomer`.
   - From this point `autoExpireEnquiries` stops closing open past-event enquiries.
   - On its first 15-minute run, `followUpReminders` backfills open enquiries once (see
     `app_config/followups_state`). Backfilled due times are at least the next
     10:00 IST slot.
   - To stage the rollout, set `app_config/notifications.followUpsEnabled = false`
     before deploying, then switch it on from Settings → Admin → Notifications.
3. **App release:** build and publish the new Android APK and web build. This build
   sends notifications through `notifyEnquiryEvent` and shows the Follow-up section.
4. **Rules, last:** `firebase deploy --only firestore:rules`, once staff are on the new
   build.
   - From then on, clients cannot create `users/{uid}/notifications` (P0 fix), and
     follow-up fields are validated.
   - Older builds keep working, but their cross-user pushes are dropped. Those writes
     were caught and logged, so the save still succeeds.
5. **Verify:**
   - Create a test enquiry and check that admins get "New Enquiry Created".
   - Check that the Follow-up section shows "Due in 3 days".
   - Check the function logs for `Follow-up reminders run` and
     `Auto-expire enquiries completed` (`flaggedForReview`).

**Rollback:**
- Re-deploy the previous functions. The new fields on the enquiries are ignored by old
  code.
- Rules can be rolled back on their own. Old clients then write notifications again,
  which re-opens the P0 hole.
- No data migration needs undoing. To stop reminders without a deploy, set
  `followUpsEnabled` to `false`.

**No production data was modified.** Enquiries that the old job auto-closed to
Not Interested stay closed. Reopening any of them is an admin decision. They carry
`lostReason: no_response` and the note `Auto-closed after event date`, so they can be
found with a query.
