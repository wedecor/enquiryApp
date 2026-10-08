import { logger } from "firebase-functions/v2";
import { onSchedule } from "firebase-functions/v2/scheduler";
import { getFirestore, FieldValue } from "firebase-admin/firestore";
import {
  CanonicalStatus,
  canonicalStatus,
  rawStatusValuesFor,
  statusLabel,
} from "./statusVocabulary";
import { IST_TIME_ZONE, istDayStart } from "./istTime";

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
 * - unbooked pipeline (new / in talks) → not interested
 * - approved bookings → completed
 */
const AUTO_CLOSE_RULES: AutoCloseRule[] = [
  { from: ["new", "in_talks"], to: "not_interested", updatedBy: "system:auto-expire" },
  { from: ["approved"], to: "completed", updatedBy: "system:auto-complete" },
];

function toDate(raw: unknown): Date | null {
  if (raw instanceof Date) return raw;
  if (raw && typeof (raw as { toDate?: unknown }).toDate === "function") {
    return (raw as { toDate: () => Date }).toDate();
  }
  return null;
}

export const autoExpireEnquiries = onSchedule(
  {
    schedule: "0 */4 * * *",
    timeZone: IST_TIME_ZONE,
    retryCount: 0,
  },
  async () => {
    const db = getFirestore();
    const now = new Date();
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
          const lostFields: Record<string, unknown> =
            rule.to === "not_interested"
              ? { lostReason: "no_response", lostReasonNote: "Auto-closed after event date" }
              : {};

          // Assignee + all active admins (deduped). sendNotificationToUser skips inactive users.
          const assignedTo = doc.get("assignedTo");
          const recipientIds = new Set<string>(activeAdminIds);
          if (typeof assignedTo === "string" && assignedTo) recipientIds.add(assignedTo);
          const recipients: Recipient[] = Array.from(recipientIds).map((uid) => ({ uid }));

          const opsForDoc = 2 + recipients.length;
          if (pendingWrites > 0 && pendingWrites + opsForDoc > MAX_BATCH_WRITES) {
            await batch.commit();
            batch = db.batch();
            pendingWrites = 0;
          }

          batch.update(doc.ref, {
            ...stageFields,
            ...lostFields,
            statusValue: rule.to,
            statusLabel: statusLabel(rule.to),
            statusUpdatedAt: FieldValue.serverTimestamp(),
            statusUpdatedBy: rule.updatedBy,
            updatedAt: FieldValue.serverTimestamp(),
            status: FieldValue.delete(),
            eventStatus: FieldValue.delete(),
            status_slug: FieldValue.delete(),
          });

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

    logger.info("Auto-expire enquiries completed", {
      scanned,
      changed,
      notificationsQueued,
      counts,
      todayStartIst: todayStart.toISOString(),
      asOf: now.toISOString(),
    });
  }
);
