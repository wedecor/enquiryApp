import { logger } from "firebase-functions/v2";
import { onSchedule } from "firebase-functions/v2/scheduler";
import { getFirestore, FieldValue } from "firebase-admin/firestore";
import {
  CanonicalStatus,
  canonicalStatus,
  rawStatusValuesFor,
  statusLabel,
} from "./statusVocabulary";

const PAGE_SIZE = 300;
/** Firestore allows 500 writes per batch; each auto-change is 2 writes (enquiry + history). */
const MAX_BATCH_WRITES = 400;

const IST_TIME_ZONE = "Asia/Kolkata";
/** India has no DST, so the offset is fixed at UTC+05:30. */
const IST_OFFSET_MS = (5 * 60 + 30) * 60 * 1000;

const istDateFormatter = new Intl.DateTimeFormat("en-CA", {
  timeZone: IST_TIME_ZONE,
  year: "numeric",
  month: "2-digit",
  day: "2-digit",
});

/** UTC instant of 00:00 IST on the IST calendar day that contains [date]. */
function istDayStart(date: Date): Date {
  const parts = istDateFormatter.formatToParts(date);
  const part = (type: Intl.DateTimeFormatPartTypes) =>
    Number(parts.find((p) => p.type === type)?.value);
  return new Date(Date.UTC(part("year"), part("month") - 1, part("day")) - IST_OFFSET_MS);
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

          batch.update(doc.ref, {
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
            user_id: "system",
            timestamp: FieldValue.serverTimestamp(),
            user_email: "system",
          });

          pendingWrites += 2;
          changed += 1;
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
      counts,
      todayStartIst: todayStart.toISOString(),
      asOf: now.toISOString(),
    });
  }
);
