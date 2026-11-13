import { HttpsError } from "firebase-functions/v2/https";

export type ActiveUserRole = "admin" | "staff";

export interface ActiveCaller {
  uid: string;
  role: ActiveUserRole;
  data: FirebaseFirestore.DocumentData;
}

/** Users docs written before the isActive migration may still carry `active`. */
export function isActiveUserData(data: FirebaseFirestore.DocumentData | undefined): boolean {
  const isActive = data?.isActive ?? data?.active ?? true;
  return isActive !== false;
}

/**
 * Verifies the caller is signed in, has an existing active `users/{uid}` doc,
 * and holds one of `allowedRoles` (default: admin or staff).
 */
export async function requireActiveCaller(
  db: FirebaseFirestore.Firestore,
  callerUid: string | undefined,
  options?: {
    unauthenticatedMessage?: string;
    deniedMessage?: string;
    allowedRoles?: readonly ActiveUserRole[];
  },
): Promise<ActiveCaller> {
  if (!callerUid) {
    throw new HttpsError("unauthenticated", options?.unauthenticatedMessage ?? "Must be signed in");
  }
  const allowed = options?.allowedRoles ?? ["admin", "staff"];
  const snap = await db.collection("users").doc(callerUid).get();
  const data = snap.data();
  const role = data?.role;
  if (
    !snap.exists ||
    !data ||
    !isActiveUserData(data) ||
    (role !== "admin" && role !== "staff") ||
    !allowed.includes(role)
  ) {
    throw new HttpsError("permission-denied", options?.deniedMessage ?? "Active account required");
  }
  return { uid: callerUid, role, data };
}

/** Convenience wrapper requiring an active admin caller. */
export async function requireActiveAdmin(
  db: FirebaseFirestore.Firestore,
  callerUid: string | undefined,
  options?: { unauthenticatedMessage?: string; deniedMessage?: string },
): Promise<ActiveCaller & { role: "admin" }> {
  const caller = await requireActiveCaller(db, callerUid, {
    ...options,
    deniedMessage: options?.deniedMessage ?? "Admin access required",
    allowedRoles: ["admin"],
  });
  return caller as ActiveCaller & { role: "admin" };
}
