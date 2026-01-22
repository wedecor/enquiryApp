import { logger } from "firebase-functions/v2";
import { onSchedule } from "firebase-functions/v2/scheduler";
import { getFirestore, FieldValue } from "firebase-admin/firestore";

const BATCH_LIMIT = 300;

const AUTO_COMPLETE_STATUSES = new Set(["confirmed"]);

// Statuses that should be marked as "not_interested" when event date passes
const MARK_NOT_INTERESTED_STATUSES = new Set([
  "new",
  "in_talks",
  "quote_sent",
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
    // Use start of today for date comparison (so events on today are not marked until tomorrow)
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

        // Get event date and normalize to start of day for accurate comparison
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

        // Normalize event date to start of day (ignore time)
        const eventDateStart = new Date(
          eventDate.getFullYear(),
          eventDate.getMonth(),
          eventDate.getDate()
        );

        // Only process if event date day has passed (event date < today)
        // This ensures events on the 23rd are marked completed on the 24th
        if (eventDateStart >= todayStart) {
          continue;
        }

        // Mark "confirmed" events as "completed" (once the event date day has passed)
        if (AUTO_COMPLETE_STATUSES.has(normalized)) {
          await doc.ref.update({
            statusValue: "completed",
            statusLabel: "Completed",
            statusUpdatedAt: FieldValue.serverTimestamp(),
            statusUpdatedBy: "system:auto-complete",
            updatedAt: FieldValue.serverTimestamp(),
            // Remove old fields
            status: FieldValue.delete(),
            eventStatus: FieldValue.delete(),
            status_slug: FieldValue.delete(),
          });

          autoCompleted += 1;
          continue;
        }

        // Mark "new", "in_talks", "quote_sent" as "not_interested"
        if (MARK_NOT_INTERESTED_STATUSES.has(normalized)) {
          await doc.ref.update({
            statusValue: "not_interested",
            statusLabel: "Not Interested",
            statusUpdatedAt: FieldValue.serverTimestamp(),
            statusUpdatedBy: "system:auto-expire",
            updatedAt: FieldValue.serverTimestamp(),
            // Remove old fields
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

