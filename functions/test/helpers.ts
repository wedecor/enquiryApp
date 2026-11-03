/**
 * Shared test setup. Integration tests need the Firestore emulator:
 *   npm run test:emulator        (starts it via firebase-tools and runs `npm test`)
 * Without FIRESTORE_EMULATOR_HOST those tests are skipped; pure unit tests always run.
 */
import { getApps, initializeApp } from "firebase-admin/app";
import { getFirestore } from "firebase-admin/firestore";

export const hasEmulator = !!process.env.FIRESTORE_EMULATOR_HOST;
export const PROJECT_ID = process.env.GCLOUD_PROJECT || "demo-functions-test";

export function testDb(): FirebaseFirestore.Firestore {
  if (getApps().length === 0) initializeApp({ projectId: PROJECT_ID });
  return getFirestore();
}

/** Deletes every document in the emulator database (REST endpoint, emulator only). */
export async function clearEmulator(): Promise<void> {
  const host = process.env.FIRESTORE_EMULATOR_HOST;
  if (!host) return;
  const res = await fetch(
    `http://${host}/emulator/v1/projects/${PROJECT_ID}/databases/(default)/documents`,
    { method: "DELETE" },
  );
  if (!res.ok) throw new Error(`clearEmulator failed: ${res.status}`);
}

export async function seedUsers(db: FirebaseFirestore.Firestore): Promise<void> {
  const users: Record<string, Record<string, unknown>> = {
    admin1: { name: "Admin One", role: "admin", isActive: true },
    admin2: { name: "Admin Two", role: "admin", isActive: true },
    adminOff: { name: "Old Admin", role: "admin", isActive: false },
    staff1: { name: "Staff One", role: "staff", isActive: true },
    staff2: { name: "Staff Two", role: "staff", isActive: true },
    staffOff: { name: "Gone Staff", role: "staff", isActive: false },
  };
  await Promise.all(Object.entries(users).map(([uid, data]) => db.collection("users").doc(uid).set(data)));
}

/** Notification docs in a user's inbox. */
export async function inbox(db: FirebaseFirestore.Firestore, uid: string) {
  const snap = await db.collection("users").doc(uid).collection("notifications").get();
  return snap.docs.map((d) => ({ id: d.id, ...d.data() })) as Array<Record<string, any>>;
}
