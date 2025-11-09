import { logger } from "firebase-functions/v2";
import { onSchedule } from "firebase-functions/v2/scheduler";
import { getFirestore, FieldValue } from "firebase-admin/firestore";
import { getMessaging } from "firebase-admin/messaging";

const BATCH_LIMIT = 200;

const AUTO_COMPLETE_STATUS = "confirmed";

const TERMINAL_STATUSES = new Set([
  "completed",
  "cancelled",
  "not_interested",
  "closed_lost",
]);

type AdminProfile = {
  uid: string;
  name: string;
  tokens: string[];
};

export const notifyOverdueInTalks = onSchedule(
  {
    schedule: "0 */4 * * *",
    timeZone: "Asia/Kolkata",
    retryCount: 0,
  },
  async () => {
    const db = getFirestore();
    const messaging = getMessaging();
    const now = new Date();

    let lastDoc: FirebaseFirestore.QueryDocumentSnapshot | undefined;
    let scanned = 0;
    let autoCompleted = 0;
    let remindersSent = 0;

    const adminProfiles = await fetchAdminProfiles(db);

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
        const data = doc.data();
        const statusRaw =
          (data["statusValue"] as string | undefined) ??
          (data["eventStatus"] as string | undefined) ??
          (data["status"] as string | undefined) ??
          "";
        const statusValue = statusRaw.trim().toLowerCase();

        if (statusValue === AUTO_COMPLETE_STATUS) {
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
          continue;
        }

        if (TERMINAL_STATUSES.has(statusValue)) {
          continue;
        }

        const assignedTo = (data["assignedTo"] as string | undefined)?.trim() || null;
        const customerName = (data["customerName"] as string | undefined) ?? "Customer";
        const statusLabel = (data["statusLabel"] as string | undefined) ?? titleCase(statusValue || "unknown");
        const eventDate = data["eventDate"] as FirebaseFirestore.Timestamp | undefined;
        const eventDateValue = eventDate ? eventDate.toDate() : null;
        const eventDateStr = eventDateValue
          ? `${eventDateValue.toLocaleDateString("en-IN")} ${eventDateValue.toLocaleTimeString("en-IN", {
              hour: "2-digit",
              minute: "2-digit",
            })}`
          : "Unknown date";

        const notificationTitle = "Event date passed – update status";
        const notificationBody = `${customerName} • ${statusLabel} • Event on ${eventDateStr}`;
        const dataPayload = {
          type: "enquiry_update_required",
          enquiryId: doc.id,
          statusValue,
          eventDate: eventDateValue ? eventDateValue.toISOString() : "",
        };

        if (assignedTo) {
          const assigneeTokens = await fetchUserTokens(db, assignedTo);
          if (assigneeTokens.length > 0) {
            await messaging.sendEachForMulticast({
              tokens: assigneeTokens,
              notification: {
                title: notificationTitle,
                body: notificationBody,
              },
              data: dataPayload,
            });

            await db
              .collection("users")
              .doc(assignedTo)
              .collection("notifications")
              .add({
                title: notificationTitle,
                body: notificationBody,
                data: dataPayload,
                read: false,
                createdAt: FieldValue.serverTimestamp(),
              });
          } else {
            logger.debug("No push registrations for assigned user on overdue enquiry", {
              enquiryId: doc.id,
              assignedTo,
            });
          }
        } else {
          logger.debug("Overdue enquiry has no assignee; notifying admins only", { enquiryId: doc.id });
        }

        for (const admin of adminProfiles) {
          if (admin.tokens.length === 0) {
            continue;
          }

          await messaging.sendEachForMulticast({
            tokens: admin.tokens,
            notification: {
              title: notificationTitle,
              body: `${notificationBody} • Assigned to ${assignedTo ?? "Unassigned"}`,
            },
            data: {
              ...dataPayload,
              audience: "admin",
            },
          });

          await db
            .collection("users")
            .doc(admin.uid)
            .collection("notifications")
            .add({
              title: notificationTitle,
              body: `${notificationBody} • Assigned to ${assignedTo ?? "Unassigned"}`,
              data: {
                ...dataPayload,
                audience: "admin",
              },
              read: false,
              createdAt: FieldValue.serverTimestamp(),
            });
        }

        remindersSent += 1;
      }

      lastDoc = snapshot.docs[snapshot.docs.length - 1];
    }

    logger.info("Overdue enquiry sweep completed", {
      scanned,
      autoCompleted,
      remindersSent,
      cutoff: now.toISOString(),
    });
  },
);

async function fetchUserTokens(db: FirebaseFirestore.Firestore, userId: string): Promise<string[]> {
  const tokensSnap = await db
    .collection("users")
    .doc(userId)
    .collection("private")
    .doc("notifications")
    .collection("tokens")
    .limit(300)
    .get();

  return Array.from(
    new Set(tokensSnap.docs.map((tokenDoc) => (tokenDoc.get("token") as string | undefined) || tokenDoc.id).filter(Boolean) as string[]),
  );
}

async function fetchAdminProfiles(db: FirebaseFirestore.Firestore): Promise<AdminProfile[]> {
  const adminSnap = await db
    .collection("users")
    .where("role", "==", "admin")
    .where("isActive", "==", true)
    .get();

  const admins: AdminProfile[] = [];

  for (const doc of adminSnap.docs) {
    const tokens = await fetchUserTokens(db, doc.id);
    admins.push({
      uid: doc.id,
      name: (doc.get("name") as string | undefined) ?? "Admin",
      tokens,
    });
  }

  return admins;
}

function titleCase(value: string): string {
  const normalized = value.replace(/[_-]+/g, " ").trim();
  if (!normalized) {
    return value;
  }
  return normalized
    .split(/\s+/)
    .map((word) => (word ? word[0].toUpperCase() + word.slice(1).toLowerCase() : word))
    .join(" ");
}

