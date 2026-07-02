#!/usr/bin/env tsx
/**
 * Migration: simplify status vocabulary — drop Contacted / Quote Sent / Confirmed.
 *
 * Enquiries: contacted, quote_sent → in_talks; confirmed → approved
 * Dropdowns: deactivate legacy status items (active: false)
 *
 * Usage:
 *   export GOOGLE_APPLICATION_CREDENTIALS="$PWD/serviceAccountKey.json"
 *   npx tsx scripts/migrations/2026_07_simplify_statuses.ts           # dry-run
 *   npx tsx scripts/migrations/2026_07_simplify_statuses.ts --apply
 */

import "dotenv/config";
import { db } from "../../src/lib/firebaseAdmin.js";
import { FieldValue } from "firebase-admin/firestore";

const firestore = db();
const BATCH_SIZE = 400;
const apply = process.argv.includes("--apply");

const ENQUIRY_STATUS_MAP: Record<string, string> = {
  contacted: "in_talks",
  quote_sent: "in_talks",
  quoted: "in_talks",
  in_progress: "in_talks",
  assigned: "in_talks",
  confirmed: "approved",
  scheduled: "approved",
  enquired: "new",
};

const LABELS: Record<string, string> = {
  new: "New",
  in_talks: "In Talks",
  approved: "Approved",
  completed: "Completed",
  not_interested: "Not Interested",
  closed_lost: "Closed Lost",
  cancelled: "Cancelled",
};

const LEGACY_DROPDOWN_IDS = [
  "contacted",
  "quote_sent",
  "confirmed",
  "scheduled",
  "in_progress",
  "enquired",
  "assigned",
  "quoted",
];

async function migrateEnquiries() {
  const snap = await firestore.collection("enquiries").get();
  let toUpdate = 0;
  const samples: string[] = [];

  for (const doc of snap.docs) {
    const data = doc.data();
    const raw = ((data.statusValue ?? data.status ?? "") as string).toLowerCase().trim();
    const canonical = ENQUIRY_STATUS_MAP[raw] ?? raw;
    if (canonical === raw || !LABELS[canonical]) continue;
    toUpdate++;
    if (samples.length < 5) {
      samples.push(`${doc.id}: ${raw} → ${canonical}`);
    }
  }

  console.log(`\nEnquiries to normalize: ${toUpdate}`);
  samples.forEach((s) => console.log(`  ${s}`));

  if (!apply || toUpdate === 0) return;

  let batch = firestore.batch();
  let ops = 0;
  for (const doc of snap.docs) {
    const data = doc.data();
    const raw = ((data.statusValue ?? data.status ?? "") as string).toLowerCase().trim();
    const canonical = ENQUIRY_STATUS_MAP[raw] ?? raw;
    if (canonical === raw || !LABELS[canonical]) continue;
    batch.update(doc.ref, {
      statusValue: canonical,
      statusLabel: LABELS[canonical],
      updatedAt: FieldValue.serverTimestamp(),
    });
    ops++;
    if (ops >= BATCH_SIZE) {
      await batch.commit();
      batch = firestore.batch();
      ops = 0;
    }
  }
  if (ops > 0) await batch.commit();
  console.log(`Applied ${toUpdate} enquiry status updates.`);
}

async function deactivateLegacyDropdowns() {
  console.log("\nLegacy dropdown status items to deactivate:");
  for (const id of LEGACY_DROPDOWN_IDS) {
    const ref = firestore.doc(`dropdowns/statuses/items/${id}`);
    const doc = await ref.get();
    if (!doc.exists) continue;
    console.log(`  ${id} (exists, active=${doc.data()?.active ?? true})`);
    if (apply) {
      await ref.set({ active: false, updatedAt: FieldValue.serverTimestamp() }, { merge: true });
    }
  }
}

async function main() {
  console.log(apply ? "=== APPLY MODE ===" : "=== DRY RUN (pass --apply to write) ===");
  await migrateEnquiries();
  await deactivateLegacyDropdowns();
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
