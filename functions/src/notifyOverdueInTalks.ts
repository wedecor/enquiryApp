import { logger } from "firebase-functions/v2";
import { onSchedule } from "firebase-functions/v2/scheduler";
import { getFirestore, FieldValue } from "firebase-admin/firestore";
import { getMessaging } from "firebase-admin/messaging";

const BATCH_LIMIT = 200;

export const notifyOverdueInTalks = onSchedule(
  {
    schedule: "0 4 * * *",
    timeZone: "Asia/Kolkata",
    retryCount: 0,
  },
  async () => {
    const db = getFirestore();
    const messaging = getMessaging();
    const today = new Date();
    const startOfToday = new Date(today.getFullYear(), today.getMonth(), today.getDate());

    let lastDoc: FirebaseFirestore.QueryDocumentSnapshot | undefined;
    let scanned = 0;
    let notified = 0;

    while (true) {
      let query = db
        .collection("enquiries")
        .where("statusValue", "==", "in_talks")
        .where("eventDate", "<", startOfToday)
        .orderBy("statusValue")
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
        const data = doc.data();
        const assignedTo = data["assignedTo"] as string | undefined;
        if (!assignedTo) {
          logger.debug("Skipping overdue enquiry without assignee", { id: doc.id });
          continue;
        }

        const tokensSnap = await db
          .collection("users")
          .doc(assignedTo)
          .collection("private")
          .doc("notifications")
          .collection("tokens")
          .limit(300)
          .get();

        const tokens = Array.from(
          new Set(
            tokensSnap.docs
              .map((t) => (t.get("token") as string | undefined) || t.id)
              .filter(Boolean) as string[],
          ),
        );

        if (tokens.length === 0) {
          logger.debug("No tokens for overdue enquiry assignee", { enquiryId: doc.id, assignedTo });
          continue;
        }

        const eventDate = data["eventDate"] as FirebaseFirestore.Timestamp | undefined;
        const eventDateStr = eventDate ? eventDate.toDate().toLocaleDateString("en-IN") : "Unknown date";

        await messaging.sendEachForMulticast({
          tokens,
          notification: {
            title: "Event date passed – update status",
            body: `${data["customerName"] ?? "Customer"} | Event on ${eventDateStr}`,
          },
          data: {
            type: "enquiry_update_required",
            enquiryId: doc.id,
            statusValue: "in_talks",
            eventDate: eventDate ? eventDate.toDate().toISOString() : "",
          },
        });

        await db
          .collection("notifications")
          .doc(assignedTo)
          .collection("items")
          .add({
            type: "enquiry_update_required",
            enquiryId: doc.id,
            title: "Event date passed – update status",
            body: `${data["customerName"] ?? "Customer"} | Event on ${eventDateStr}`,
            statusValue: "in_talks",
            eventDate: eventDate ? eventDate.toDate() : null,
            createdAt: FieldValue.serverTimestamp(),
            read: false,
            archived: false,
          });

        notified += 1;
      }

      lastDoc = snapshot.docs[snapshot.docs.length - 1];
    }

    logger.info("Overdue in_talks notification sweep completed", {
      scanned,
      notified,
      cutoff: startOfToday.toISOString(),
    });
  },
);

