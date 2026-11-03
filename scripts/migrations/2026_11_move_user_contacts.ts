#!/usr/bin/env tsx
/**
 * Migration: move colleague phone / email from users/{uid} to users/{uid}/private/profile.
 *
 * Every active user may read users/{uid} (assignment labels need name, role and
 * isActive). Contact details move to the private profile, readable only by the
 * user and admins (firestore.rules). Values already in the profile win. The
 * adminUpdateUser function also moves them on a user's next edit.
 *
 * DEFAULT IS DRY-RUN. It prints what would change and writes nothing.
 *
 *   export GOOGLE_APPLICATION_CREDENTIALS="$PWD/serviceAccountKey.json"
 *   npx tsx scripts/migrations/2026_11_move_user_contacts.ts           # dry-run (default)
 *   npx tsx scripts/migrations/2026_11_move_user_contacts.ts --apply   # only after review
 */

import "dotenv/config";
import { db } from "../../src/lib/firebaseAdmin.js";
import { FieldValue } from "firebase-admin/firestore";

const apply = process.argv.includes("--apply");
const CONTACT_FIELDS = ["phone", "email"] as const;

async function main() {
  const firestore = db();
  const users = await firestore.collection("users").get();
  const plans: { uid: string; copy: Record<string, unknown>; remove: string[] }[] = [];
  for (const doc of users.docs) {
    const data = doc.data();
    const remove = CONTACT_FIELDS.filter((f) => f in data);
    if (remove.length === 0) continue;
    const profile = await doc.ref.collection("private").doc("profile").get();
    const copy: Record<string, unknown> = {};
    for (const f of remove) {
      if (profile.exists && profile.get(f)) continue;
      if (typeof data[f] === "string") copy[f] = data[f];
    }
    plans.push({ uid: doc.id, copy, remove });
  }

  console.log(`User contacts migration: ${plans.length} user doc(s) carry phone/email`);
  console.log(`Mode: ${apply ? "APPLY" : "DRY-RUN (nothing is written)"}`);
  for (const p of plans.slice(0, 5)) {
    console.log(JSON.stringify({ uid: p.uid, copy: Object.keys(p.copy), remove: p.remove }));
  }
  if (!apply) return;
  for (const p of plans) {
    const ref = firestore.collection("users").doc(p.uid);
    const batch = firestore.batch();
    if (Object.keys(p.copy).length > 0) {
      batch.set(ref.collection("private").doc("profile"), { ...p.copy, updatedAt: FieldValue.serverTimestamp() }, { merge: true });
    }
    batch.update(ref, Object.fromEntries(p.remove.map((f) => [f, FieldValue.delete()])));
    await batch.commit();
  }
  console.log(`Moved contact details for ${plans.length} user(s).`);
}

main().catch((error) => {
  console.error("User contacts migration failed:", error);
  process.exit(1);
});
