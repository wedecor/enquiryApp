#!/usr/bin/env tsx
/**
 * Migration (Nov 2026): set `pastCustomer` on existing pending yearly reminders.
 *
 * The daily `scheduleReengagements` job now writes `pastCustomer` (true = we
 * decorated their event, false = they only enquired). Reminders created before
 * that have no flag; the app treats a missing flag as a past customer, which is
 * wrong for lost enquiries that became eligible in 2.0.25. This reads each
 * pending reminder's enquiry and sets the flag from its status.
 *
 * Idempotent; only touches pending reminders without the flag.
 *
 * Usage:
 *   export GOOGLE_APPLICATION_CREDENTIALS="$PWD/serviceAccountKey.json"
 *   npx tsx scripts/migrations/2026_11_backfill_reminder_customer_type.ts           # dry-run
 *   npx tsx scripts/migrations/2026_11_backfill_reminder_customer_type.ts --apply
 */
import "dotenv/config";
import { createRequire } from "node:module";
import { db } from "../../src/lib/firebaseAdmin.js";

type Status = typeof import("../../functions/src/statusVocabulary.js");
const require = createRequire(import.meta.url);
const status: Status = require("../../functions/src/statusVocabulary.ts");

const firestore = db();
const apply = process.argv.includes("--apply");

async function main() {
  console.log(apply ? "=== APPLY MODE ===" : "=== DRY RUN (pass --apply to write) ===");
  const snap = await firestore.collection("reminders").where("status", "==", "pending").get();
  const updates: Array<{ id: string; pastCustomer: boolean }> = [];
  let alreadyFlagged = 0;
  let missingEnquiry = 0;

  for (const doc of snap.docs) {
    if (typeof doc.get("pastCustomer") === "boolean") {
      alreadyFlagged++;
      continue;
    }
    const enquiryId = doc.get("enquiryId");
    if (typeof enquiryId !== "string" || !enquiryId) {
      missingEnquiry++;
      continue;
    }
    const enquiry = await firestore.collection("enquiries").doc(enquiryId).get();
    if (!enquiry.exists) {
      missingEnquiry++;
      continue;
    }
    const pastCustomer = status.canonicalStatus(enquiry.get("statusValue")) === "completed";
    updates.push({ id: doc.id, pastCustomer });
  }

  console.log(`Pending reminders: ${snap.size}`);
  console.log(`  already flagged: ${alreadyFlagged}`);
  console.log(`  enquiry missing (left as past customer): ${missingEnquiry}`);
  console.log(`  to flag: ${updates.length} (past customer ${updates.filter((u) => u.pastCustomer).length}, enquired ${updates.filter((u) => !u.pastCustomer).length})`);

  if (apply && updates.length > 0) {
    for (let i = 0; i < updates.length; i += 400) {
      const batch = firestore.batch();
      for (const u of updates.slice(i, i + 400)) {
        batch.update(firestore.collection("reminders").doc(u.id), { pastCustomer: u.pastCustomer });
      }
      await batch.commit();
    }
    console.log(`  Applied ${updates.length} update(s).`);
  }
}

main().catch((error) => {
  console.error("Reminder customer-type backfill failed:", error);
  process.exit(1);
});
