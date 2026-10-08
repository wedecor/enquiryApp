#!/usr/bin/env tsx
/**
 * Migration: backfill `phoneNormalized` on enquiries (customer identity for the
 * lookupCustomer callable — repeat customers and duplicate warnings).
 *
 * Rule (must match lib/core/utils/phone_normalizer.dart and functions/src/customers.ts):
 *   1. keep digits only;
 *   2. if more than 10 digits remain, keep the last 10 (+91 / 0091 / leading 0 dropped).
 *
 * Source: `customerPhone`, falling back to `whatsappNumber` when the phone is empty.
 * Updates only enquiries whose stored value is missing or differs (old digits-only
 * format such as "919876543210"), so re-running is a no-op. `updatedAt` is not touched.
 *
 * Usage:
 *   export GOOGLE_APPLICATION_CREDENTIALS="$PWD/serviceAccountKey.json"
 *   npx tsx scripts/migrations/2026_10_backfill_phone_normalized.ts           # dry-run (default)
 *   npx tsx scripts/migrations/2026_10_backfill_phone_normalized.ts --apply
 */

import "dotenv/config";
import { db } from "../../src/lib/firebaseAdmin.js";
import { type DocumentReference } from "firebase-admin/firestore";

const firestore = db();
const BATCH_SIZE = 400;
const apply = process.argv.includes("--apply");

function normalizePhone(raw: unknown): string {
  if (typeof raw !== "string") return "";
  const digits = raw.replace(/\D/g, "");
  return digits.length > 10 ? digits.slice(-10) : digits;
}

async function main() {
  console.log(apply ? "=== APPLY MODE ===" : "=== DRY RUN (pass --apply to write) ===");
  const snap = await firestore.collection("enquiries").get();
  const ops: Array<{ ref: DocumentReference; data: Record<string, unknown> }> = [];
  let alreadyCorrect = 0;
  let missing = 0;
  let reformatted = 0;
  let noPhone = 0;
  const samples: string[] = [];

  for (const doc of snap.docs) {
    const data = doc.data();
    let normalized = normalizePhone(data.customerPhone);
    if (!normalized) normalized = normalizePhone(data.whatsappNumber);
    if (!normalized) noPhone++;

    const current = data.phoneNormalized;
    if (current === normalized) {
      alreadyCorrect++;
      continue;
    }
    if (current == null || current === "") {
      missing++;
    } else {
      reformatted++;
    }
    if (samples.length < 10) {
      samples.push(`    ${doc.id}: ${JSON.stringify(current ?? null)} → ${JSON.stringify(normalized)}`);
    }
    ops.push({ ref: doc.ref, data: { phoneNormalized: normalized } });
  }

  console.log(`Enquiries scanned: ${snap.size}`);
  console.log(`  already correct: ${alreadyCorrect}`);
  console.log(`  missing phoneNormalized: ${missing}`);
  console.log(`  old format (re-normalized): ${reformatted}`);
  console.log(`  without any phone number: ${noPhone}`);
  console.log(`  to update: ${ops.length}`);
  if (samples.length > 0) {
    console.log("  sample changes:");
    for (const line of samples) console.log(line);
  }

  if (apply && ops.length > 0) {
    for (let i = 0; i < ops.length; i += BATCH_SIZE) {
      const batch = firestore.batch();
      for (const op of ops.slice(i, i + BATCH_SIZE)) batch.update(op.ref, op.data);
      await batch.commit();
    }
    console.log(`  Applied ${ops.length} enquiry update(s).`);
  }
}

main().catch((error) => {
  console.error("phoneNormalized backfill failed:", error);
  process.exit(1);
});
