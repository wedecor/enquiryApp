import { logger } from "firebase-functions/v2";
import { onCall, HttpsError } from "firebase-functions/v2/https";
import { getFirestore, FieldValue } from "firebase-admin/firestore";
import { normalizePhone } from "./customers";

/**
 * "Don't remind again" (yearly re-engagement wishes) for one customer phone.
 *
 * Clients can no longer write customer_prefs/{phone} (firestore.rules): any staff
 * member could otherwise opt out any customer. The caller must be an active admin,
 * or an active staff member assigned to at least one enquiry with that
 * phoneNormalized. Only noReminders, updatedAt and updatedBy are written.
 */

export type SetReengagementPrefRequest = { phone?: unknown; noReminders?: unknown };

function isActiveUserData(data: FirebaseFirestore.DocumentData | undefined): boolean {
  return (data?.isActive ?? data?.active ?? true) !== false;
}

/** Callable core, exported for tests. */
export async function handleSetReengagementPref(
  db: FirebaseFirestore.Firestore,
  callerUid: string | undefined,
  input: SetReengagementPrefRequest,
): Promise<{ ok: true; phone: string; noReminders: boolean }> {
  if (!callerUid) throw new HttpsError("unauthenticated", "Must be signed in");
  if (typeof input.phone !== "string" || input.phone.length > 30) {
    throw new HttpsError("invalid-argument", "phone must be a string of at most 30 characters");
  }
  if (typeof input.noReminders !== "boolean") {
    throw new HttpsError("invalid-argument", "noReminders must be true or false");
  }
  const phone = normalizePhone(input.phone);
  if (phone.length < 7) throw new HttpsError("invalid-argument", "phone is too short");

  const caller = await db.collection("users").doc(callerUid).get();
  const role = caller.get("role");
  if (!caller.exists || !isActiveUserData(caller.data()) || (role !== "admin" && role !== "staff")) {
    throw new HttpsError("permission-denied", "Active account required");
  }
  if (role === "staff") {
    const assigned = await db
      .collection("enquiries")
      .where("phoneNormalized", "==", phone)
      .where("assignedTo", "==", callerUid)
      .limit(1)
      .get();
    if (assigned.empty) {
      throw new HttpsError("permission-denied", "Not assigned to an enquiry for this customer");
    }
  }

  await db.collection("customer_prefs").doc(phone).set(
    { noReminders: input.noReminders, updatedAt: FieldValue.serverTimestamp(), updatedBy: callerUid },
    { merge: true },
  );
  logger.info("setReengagementPref", { by: callerUid, noReminders: input.noReminders });
  return { ok: true, phone, noReminders: input.noReminders };
}

export const setReengagementPref = onCall<SetReengagementPrefRequest>(
  { cors: true, region: "asia-south1", enforceAppCheck: false },
  async (request) => handleSetReengagementPref(getFirestore(), request.auth?.uid, request.data ?? {}),
);
