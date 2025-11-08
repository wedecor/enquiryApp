import { logger } from "firebase-functions/v2";
import { onSchedule } from "firebase-functions/v2/scheduler";
import { getFirestore, FieldValue } from "firebase-admin/firestore";

const EXCLUDED_STATUSES = new Set([
  "confirmed",
  "completed",
  "cancelled",
  "not_interested",
  "closed_lost",
]);

const BATCH_LIMIT = 300;

export const autoExpireEnquiries = onSchedule(
  {
    schedule: "0 3 * * *",
    timeZone: "Asia/Kolkata",
    retryCount: 0,
  },
  async () => {
    const db = getFirestore();
    const now = new Date();
    let updated = 0;
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

      let hasWrites = false;
      const batch = db.batch();

      snapshot.docs.forEach((doc) => {
        scanned += 1;
        const statusRaw = (doc.get("status") as string | undefined) ?? "";
        const normalized = statusRaw.trim().toLowerCase();

        if (EXCLUDED_STATUSES.has(normalized)) {
          return;
        }

        batch.update(doc.ref, {
          status: "not_interested",
          eventStatus: "not_interested",
          statusUpdatedAt: FieldValue.serverTimestamp(),
          statusUpdatedBy: "system:auto-expire",
          updatedAt: FieldValue.serverTimestamp(),
        });

        updated += 1;
        hasWrites = true;
      });

      if (hasWrites) {
        await batch.commit();
      }

      lastDoc = snapshot.docs[snapshot.docs.length - 1];
    }

    logger.info("Auto-expire enquiries completed", {
      scanned,
      updated,
      asOf: now.toISOString(),
    });
  }
);


