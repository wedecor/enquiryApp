import { logger } from "firebase-functions/v2";
import { onSchedule } from "firebase-functions/v2/scheduler";
import { getFirestore, FieldValue } from "firebase-admin/firestore";
import {
  CanonicalStatus,
  canonicalStatus,
  rawStatusValuesFor,
  statusLabel,
} from "./statusVocabulary";
import { allEventDaysPassed } from "./followUpsLogic";
import { IST_TIME_ZONE, istDayStart } from "./istTime";
import { planOccasionStamps, stampFields } from "./occasionStamping";
import { OccasionStamp } from "./reengagementLogic";

const PAGE_SIZE = 300;
/**
 * Firestore allows 500 writes per batch. Each auto-change is 2 writes (enquiry + history)
 * plus one notification doc per recipient; a batch is committed before it would overflow.
 */
const MAX_BATCH_WRITES = 450;
const SYSTEM_USER = "system";

type Recipient = { uid: string };

function truncate(value: string, max: number): string {
  return value.length <= max ? value : `${value.slice(0, max - 1)}…`;
}

/** Users docs written before the isActive migration may still carry `active`. */
function isActiveUserData(data: FirebaseFirestore.DocumentData | undefined): boolean {
  const isActive = data?.isActive ?? data?.active ?? true;
  return isActive !== false;
}

async function loadActiveAdminIds(db: FirebaseFirestore.Firestore): Promise<string[]> {
  const snap = await db.collection("users").where("role", "==", "admin").get();
  return snap.docs.filter((d) => isActiveUserData(d.data())).map((d) => d.id);
}

type AutoCloseRule = {
  from: CanonicalStatus[];
  to: CanonicalStatus;
  updatedBy: string;
};

/**
 * Event day (IST) fully passed:
 * - approved bookings → completed (unchanged).
 * - unbooked pipeline (new / in talks) is NOT closed any more (Nov 2026 business
 *   rule: an undecided customer must not become Not Interested just because the
 *   date passed). See [flagPastEventOpenEnquiries].
 */
const AUTO_CLOSE_RULES: AutoCloseRule[] = [
  { from: ["approved"], to: "completed", updatedBy: "system:auto-complete" },
];

/** Open statuses that are flagged for review (not closed) once their event day passes. */
const REVIEW_STATUSES: CanonicalStatus[] = ["new", "in_talks"];
/**
 * Only enquiries whose (last) event day passed within this window are scanned, so
 * the job does not re-read every old open enquiry every 4 hours. Each one is flagged
 * once (`pastEventReviewAt`); after that the follow-up workflow keeps it visible.
 */
export const REVIEW_LOOKBACK_DAYS = 30;

function toDate(raw: unknown): Date | null {
  if (raw instanceof Date) return raw;
  if (raw && typeof (raw as { toDate?: unknown }).toDate === "function") {
    return (raw as { toDate: () => Date }).toDate();
  }
  return null;
}

/**
 * Open (New / In Talks) enquiries whose every event day has passed: no status change.
 * Each is flagged once with `pastEventReviewAt`, a history entry and one notification
 * to active admins (deterministic id `pastevent_{enquiryId}`). The follow-up trigger
 * (onEnquiryWrittenFollowUp) sees the past event and makes the follow-up due now, so
 * the assignee is reminded by followUpReminders and the enquiry stays in Follow Up.
 * Idempotent: a flagged enquiry is skipped inside a transaction.
 */
export async function flagPastEventOpenEnquiries(
  db: FirebaseFirestore.Firestore,
  now: Date,
  activeAdminIds: readonly string[],
): Promise<number> {
  const todayStart = istDayStart(now);
  const windowStart = new Date(todayStart.getTime() - REVIEW_LOOKBACK_DAYS * 24 * 60 * 60 * 1000);
  const rawValues = REVIEW_STATUSES.flatMap(rawStatusValuesFor);
  let flagged = 0;
  let lastDoc: FirebaseFirestore.QueryDocumentSnapshot | undefined;

  while (true) {
    let query = db
      .collection("enquiries")
      .where("statusValue", "in", rawValues)
      .where("eventDate", "<", todayStart)
      .where("eventDate", ">=", windowStart)
      .orderBy("eventDate", "asc")
      .limit(PAGE_SIZE);
    if (lastDoc) query = query.startAfter(lastDoc);
    const snapshot = await query.get();
    if (snapshot.empty) break;

    for (const doc of snapshot.docs) {
      if (doc.get("pastEventReviewAt") || doc.get("mergedInto")) continue;
      const done = await db.runTransaction(async (tx) => {
        const fresh = await tx.get(doc.ref);
        const data = fresh.data() ?? {};
        const status = canonicalStatus(data.statusValue);
        if (!status || !REVIEW_STATUSES.includes(status) || data.pastEventReviewAt || data.mergedInto) return false;
        if (!allEventDaysPassed(data, now)) return false;

        const assignedTo = typeof data.assignedTo === "string" && data.assignedTo ? data.assignedTo : null;
        // The assignee hears about it through the follow-up reminder; admins get one notice.
        const recipients = activeAdminIds.filter((uid) => uid !== assignedTo);
        const recipientRefs = recipients.map((uid) =>
          db.collection("users").doc(uid).collection("notifications").doc(`pastevent_${doc.id}`)
        );
        const existing = recipientRefs.length > 0 ? await tx.getAll(...recipientRefs) : [];

        tx.update(doc.ref, { pastEventReviewAt: FieldValue.serverTimestamp() });
        tx.set(doc.ref.collection("history").doc(), {
          field_changed: "pastEventReview",
          old_value: statusLabel(status),
          new_value: `Event date passed — kept ${statusLabel(status)} for follow-up / review (not auto-closed)`,
          user_id: SYSTEM_USER,
          timestamp: FieldValue.serverTimestamp(),
          user_email: SYSTEM_USER,
        });
        const customerName = (data.customerName as string | undefined) || "Unknown Customer";
        recipientRefs.forEach((ref, i) => {
          if (existing[i]?.exists) return;
          tx.create(ref, {
            title: "Event date passed — needs review",
            body: truncate(`${customerName} is still ${statusLabel(status)}. Follow up or record the outcome.`, 500),
            type: "past_event_review",
            enquiryId: doc.id,
            data: { type: "past_event_review", enquiryId: doc.id, customerName, status: statusLabel(status) },
            read: false,
            createdBy: "system:auto-expire",
            createdAt: FieldValue.serverTimestamp(),
          });
        });
        return true;
      });
      if (done) flagged += 1;
    }

    if (snapshot.size < PAGE_SIZE) break;
    lastDoc = snapshot.docs[snapshot.docs.length - 1];
  }
  return flagged;
}

/** Scheduler core, exported for tests. Idempotent: safe to re-run at any time. */
export async function runAutoExpire(
  db: FirebaseFirestore.Firestore,
  now: Date = new Date(),
): Promise<{ changed: number; flagged: number }> {
  const todayStart = istDayStart(now);
  const counts: Record<string, number> = {};
  let scanned = 0;
  let changed = 0;
  let notificationsQueued = 0;

  // Admins are notified of every auto-change; loaded once per run.
  let activeAdminIds: string[] = [];
  try {
    activeAdminIds = await loadActiveAdminIds(db);
  } catch (error: any) {
    logger.error("Auto-expire: failed to load admins for notifications", { error: error?.message });
  }

  for (const rule of AUTO_CLOSE_RULES) {
    // Canonical values + legacy aliases (≤ 10 values for the `in` filter).
    const rawValues = rule.from.flatMap(rawStatusValuesFor);
    let lastDoc: FirebaseFirestore.QueryDocumentSnapshot | undefined;

    while (true) {
      let query = db
        .collection("enquiries")
        .where("statusValue", "in", rawValues)
        .where("eventDate", "<", todayStart)
        .orderBy("eventDate", "asc")
        .limit(PAGE_SIZE);

      if (lastDoc) {
        query = query.startAfter(lastDoc);
      }

      const snapshot = await query.get();
      if (snapshot.empty) {
        break;
      }

      let batch = db.batch();
      let pendingWrites = 0;

      for (const doc of snapshot.docs) {
        scanned += 1;
        const oldRaw = doc.get("statusValue") as string | undefined;
        const oldStatus = canonicalStatus(oldRaw);
        if (!oldStatus || !rule.from.includes(oldStatus)) continue;

        const eventDate = toDate(doc.get("eventDate"));
        if (!eventDate) continue;
        if (istDayStart(eventDate).getTime() >= todayStart.getTime()) continue;

        // First time this stage is reached (analytics stage timestamps).
        const stageField = rule.to === "completed" ? "completedAt" : "lostAt";
        const stageFields: Record<string, unknown> = doc.get(stageField)
          ? {}
          : { [stageField]: FieldValue.serverTimestamp() };

        // Assignee + all active admins (deduped). sendNotificationToUser skips inactive users.
        const assignedTo = doc.get("assignedTo");
        const recipientIds = new Set<string>(activeAdminIds);
        if (typeof assignedTo === "string" && assignedTo) recipientIds.add(assignedTo);
        const recipients: Recipient[] = Array.from(recipientIds).map((uid) => ({ uid }));

        // Yearly re-engagement stamp in the same write (the stamping trigger then
        // sees the fields and does nothing). Wedding-family siblings of the same
        // customer may be re-stamped to the wedding date as extra writes.
        let occasionStamps = new Map<string, OccasionStamp>();
        if (rule.to === "completed" && !doc.get("occasionManual")) {
          try {
            occasionStamps = await planOccasionStamps(db, doc.id, doc.data(), "completed");
          } catch (error: any) {
            logger.warn("Auto-complete: occasion stamping failed", { enquiryId: doc.id, error: error?.message });
          }
        }
        const ownStamp = occasionStamps.get(doc.id);
        const occasionFields: Record<string, unknown> = ownStamp ? stampFields(ownStamp) : {};
        const siblingStamps = Array.from(occasionStamps.entries()).filter(([id]) => id !== doc.id);

        const opsForDoc = 2 + recipients.length + siblingStamps.length;
        if (pendingWrites > 0 && pendingWrites + opsForDoc > MAX_BATCH_WRITES) {
          await batch.commit();
          batch = db.batch();
          pendingWrites = 0;
        }

        batch.update(doc.ref, {
          ...stageFields,
          ...occasionFields,
          statusValue: rule.to,
          statusLabel: statusLabel(rule.to),
          statusUpdatedAt: FieldValue.serverTimestamp(),
          statusUpdatedBy: rule.updatedBy,
          updatedAt: FieldValue.serverTimestamp(),
          status: FieldValue.delete(),
          eventStatus: FieldValue.delete(),
          status_slug: FieldValue.delete(),
        });

        for (const [siblingId, stamp] of siblingStamps) {
          batch.update(db.collection("enquiries").doc(siblingId), stampFields(stamp));
        }

        // Same shape as AuditService.recordChange (lib/core/services/audit_service.dart).
        batch.set(doc.ref.collection("history").doc(), {
          field_changed: "statusValue",
          old_value: oldStatus,
          new_value: rule.to,
          user_id: SYSTEM_USER,
          timestamp: FieldValue.serverTimestamp(),
          user_email: SYSTEM_USER,
        });

        // Same doc shape as NotificationService (users/{uid}/notifications); the
        // sendNotificationToUser trigger turns each one into a push.
        const customerName = (doc.get("customerName") as string | undefined) || "Unknown Customer";
        const oldLabel = statusLabel(oldStatus);
        const newLabel = statusLabel(rule.to);
        const title = rule.to === "completed" ? "Enquiry Auto-Completed" : "Enquiry Auto-Closed";
        const body = truncate(
          `Status changed from ${oldLabel} to ${newLabel} for ${customerName} (event date passed)`,
          500
        );
        for (const recipient of recipients) {
          batch.set(
            db.collection("users").doc(recipient.uid).collection("notifications").doc(),
            {
              title: truncate(title, 120),
              body,
              type: "status_update",
              enquiryId: doc.id,
              data: {
                type: "status_update",
                enquiryId: doc.id,
                customerName,
                oldStatus: oldLabel,
                newStatus: newLabel,
                updatedBy: rule.updatedBy,
              },
              read: false,
              createdAt: FieldValue.serverTimestamp(),
            }
          );
        }

        pendingWrites += opsForDoc;
        changed += 1;
        notificationsQueued += recipients.length;
        const key = `${oldRaw}->${rule.to}`;
        counts[key] = (counts[key] ?? 0) + 1;

        if (pendingWrites >= MAX_BATCH_WRITES) {
          await batch.commit();
          batch = db.batch();
          pendingWrites = 0;
        }
      }

      if (pendingWrites > 0) {
        await batch.commit();
      }

      if (snapshot.size < PAGE_SIZE) {
        break;
      }
      lastDoc = snapshot.docs[snapshot.docs.length - 1];
    }
  }

  let flagged = 0;
  try {
    flagged = await flagPastEventOpenEnquiries(db, now, activeAdminIds);
  } catch (error: any) {
    logger.error("Auto-expire: past-event review flagging failed", { error: error?.message });
  }

  logger.info("Auto-expire enquiries completed", {
    scanned,
    changed,
    flaggedForReview: flagged,
    notificationsQueued,
    counts,
    todayStartIst: todayStart.toISOString(),
    asOf: now.toISOString(),
  });
  return { changed, flagged };
}

export const autoExpireEnquiries = onSchedule(
  {
    schedule: "0 */4 * * *",
    timeZone: IST_TIME_ZONE,
    retryCount: 0,
  },
  async () => {
    await runAutoExpire(getFirestore());
  }
);
