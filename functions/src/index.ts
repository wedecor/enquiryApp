import { setGlobalOptions, logger } from "firebase-functions/v2";
import { onDocumentWritten } from "firebase-functions/v2/firestore";
import { initializeApp } from "firebase-admin/app";
import { getFirestore, FieldValue } from "firebase-admin/firestore";
import { getMessaging } from "firebase-admin/messaging";

setGlobalOptions({
  region: "asia-south1",
  memory: "128MiB",
  timeoutSeconds: 30,
  maxInstances: 5
});

initializeApp();

type Enquiry = {
  assignedTo?: string | null;
  eventStatus?: string | null;
  paymentStatus?: string | null;
  customerName?: string | null;
};

export const notifyOnEnquiryChange = onDocumentWritten(
  "enquiries/{id}",
  async (event) => {
    const before = (event.data?.before?.data() || null) as Enquiry | null;
    const after = (event.data?.after?.data() || null) as Enquiry | null;

    if (!after) {
      // Deleted doc: no-op
      return;
    }

    const changedAssigned = (before?.assignedTo ?? null) !== (after.assignedTo ?? null);
    const changedStatus   = (before?.eventStatus ?? null) !== (after.eventStatus ?? null);
    const changedPayment  = (before?.paymentStatus ?? null) !== (after.paymentStatus ?? null);

    if (!(changedAssigned || changedStatus || changedPayment)) {
      logger.debug("No meaningful change; skipping push", { id: event.params.id });
      return;
    }

    const uid = after.assignedTo;
    if (!uid) {
      logger.debug("No assignedTo on enquiry; skipping", { id: event.params.id });
      return;
    }

    const db = getFirestore();
    const userSnap = await db.doc(`users/${uid}`).get();
    if (!userSnap.exists) {
      logger.info("Missing users doc; skipping notification", { uid });
      return;
    }

    const fcmToken = userSnap.get("fcmToken") as string | undefined;
    const webTokens = (userSnap.get("webTokens") as string[] | undefined) ?? [];
    const tokens = Array.from(new Set([fcmToken, ...webTokens].filter((t): t is string => !!t && t.length > 0)));

    if (tokens.length === 0) {
      logger.info("No tokens present; skipping", { uid });
      return;
    }

    const titleParts: string[] = [];
    if (changedAssigned) titleParts.push("Assigned");
    if (changedStatus)   titleParts.push(`Status: ${after.eventStatus ?? ""}`);
    if (changedPayment)  titleParts.push(`Payment: ${after.paymentStatus ?? ""}`);
    const title = titleParts.join(" • ") || "Enquiry Updated";

    const body  = after.customerName ? `Customer: ${after.customerName}` : "Open the app for details";
    const data  = {
      type: "enquiry_update",
      enquiryId: event.params.id,
      eventStatus: after.eventStatus ?? "",
      paymentStatus: after.paymentStatus ?? ""
    };

    const res = await getMessaging().sendEachForMulticast({
      tokens,
      notification: { title, body },
      data
    });

    logger.info("Push summary", {
      id: event.params.id,
      uid,
      tokens: tokens.length,
      success: res.successCount,
      failure: res.failureCount
    });

    // Optional in-app inbox doc
    await db.collection("notifications").doc(uid).collection("items").add({
      type: "enquiry_update",
      enquiryId: event.params.id,
      title,
      body,
      eventStatus: after.eventStatus ?? null,
      paymentStatus: after.paymentStatus ?? null,
      createdAt: FieldValue.serverTimestamp(),
      read: false,
      archived: false
    });
  }
);