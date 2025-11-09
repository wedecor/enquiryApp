import { logger } from "firebase-functions/v2";
import { onSchedule } from "firebase-functions/v2/scheduler";
import { getFirestore, FieldValue } from "firebase-admin/firestore";

const BATCH_LIMIT = 300;

const AUTO_COMPLETE_STATUSES = new Set(["confirmed"]);

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
    let autoCompleted = 0;
    let scanned = 0;
    let lastDoc: FirebaseFirestore.QueryDocumentSnapshot | undefined;

    while (true) {
      let query = db
        .collection("enquiries")
        .where("eventDate", "<", now)
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

        if (!AUTO_COMPLETE_STATUSES.has(normalized)) {
          continue;
        }

        await doc.ref.update({
          status: "completed",
          eventStatus: "completed",
          statusValue: "completed",
          statusLabel: "Completed",
          statusUpdatedAt: FieldValue.serverTimestamp(),
          statusUpdatedBy: "system:auto-complete",
          updatedAt: FieldValue.serverTimestamp(),
        });

        autoCompleted += 1;
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

