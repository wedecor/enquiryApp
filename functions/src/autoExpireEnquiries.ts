import { logger } from "firebase-functions/v2";
import { onSchedule } from "firebase-functions/v2/scheduler";
import { getFirestore, FieldValue } from "firebase-admin/firestore";

const BATCH_LIMIT = 300;

/** Canonical approved slugs (incl. legacy before migration). */
const AUTO_COMPLETE_STATUSES = new Set([
  "approved",
  "confirmed",
  "scheduled",
]);

/** Active pipeline — auto-close when event date has passed without booking. */
const MARK_NOT_INTERESTED_STATUSES = new Set([
  "new",
  "in_talks",
  "contacted",
  "quote_sent",
  "in_progress",
  "assigned",
  "quoted",
  "enquired",
]);

const TERMINAL_STATUSES = new Set([
  "completed",
  "cancelled",
  "not_interested",
  "closed_lost",
]);

export const autoExpireEnquiries = onSchedule(
  {
    schedule: "0 */4 * * *",
    timeZone: "Asia/Kolkata",
    retryCount: 0,
  },
  async () => {
    const db = getFirestore();
    const now = new Date();
    const todayStart = new Date(now.getFullYear(), now.getMonth(), now.getDate());
    let autoCompleted = 0;
    let scanned = 0;
    let lastDoc: FirebaseFirestore.QueryDocumentSnapshot | undefined;

    while (true) {
      let query = db
        .collection("enquiries")
        .where("eventDate", "<", todayStart)
        .orderBy("eventDate", "asc")
        .limit(BATCH_LIMIT);

      if (lastDoc) {
        query = query.startAfter(lastDoc);
      }

      const snapshot = await query.get();
      if (snapshot.empty) {
        break;
      }

      for (const doc of snapshot.docs) {
        scanned += 1;
        const statusRaw =
          (doc.get("statusValue") as string | undefined) ??
          (doc.get("eventStatus") as string | undefined) ??
          (doc.get("status") as string | undefined) ??
          "";
        const normalized = statusRaw.trim().toLowerCase();

        if (TERMINAL_STATUSES.has(normalized)) {
          continue;
        }

        const eventDateRaw = doc.get("eventDate");
        if (!eventDateRaw) continue;

        let eventDate: Date;
        if (eventDateRaw.toDate) {
          eventDate = eventDateRaw.toDate();
        } else if (eventDateRaw instanceof Date) {
          eventDate = eventDateRaw;
        } else {
          continue;
        }

        const eventDateStart = new Date(
          eventDate.getFullYear(),
          eventDate.getMonth(),
          eventDate.getDate()
        );

        if (eventDateStart >= todayStart) {
          continue;
        }

        // Approved bookings → completed once event day has passed
        if (AUTO_COMPLETE_STATUSES.has(normalized)) {
          await doc.ref.update({
            statusValue: "completed",
            statusLabel: "Completed",
            statusUpdatedAt: FieldValue.serverTimestamp(),
            statusUpdatedBy: "system:auto-complete",
            updatedAt: FieldValue.serverTimestamp(),
            status: FieldValue.delete(),
            eventStatus: FieldValue.delete(),
            status_slug: FieldValue.delete(),
          });

          autoCompleted += 1;
          continue;
        }

        // Unbooked pipeline → not interested when event date passed
        if (MARK_NOT_INTERESTED_STATUSES.has(normalized)) {
          await doc.ref.update({
            statusValue: "not_interested",
            statusLabel: "Not Interested",
            statusUpdatedAt: FieldValue.serverTimestamp(),
            statusUpdatedBy: "system:auto-expire",
            updatedAt: FieldValue.serverTimestamp(),
            status: FieldValue.delete(),
            eventStatus: FieldValue.delete(),
            status_slug: FieldValue.delete(),
          });

          autoCompleted += 1;
        }
      }

      lastDoc = snapshot.docs[snapshot.docs.length - 1];
    }

    logger.info("Auto-expire enquiries completed", {
      scanned,
      autoCompleted,
      asOf: now.toISOString(),
    });
  }
);
