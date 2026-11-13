#!/usr/bin/env tsx
/**
 * Migration: remove quoted amounts from enquiry change history.
 *
 * Until 2.0.28+59, marking a quotation as sent wrote a history entry like
 *   field_changed: "quotation", new_value: "sent WD-Q-1234 ₹45000"
 * into enquiries/{id}/history, which the assigned staff member can read. Money is
 * admin-only (enquiries/{id}/financial/summary), so the amount must not be there.
 *
 * Rewrites new_value / old_value of `quotation` history entries to drop the
 * trailing " ₹<amount>". Nothing else is touched; re-running is a no-op.
 * Only enquiries that have a quotations subcollection are scanned.
 *
 * Usage:
 *   export GOOGLE_APPLICATION_CREDENTIALS="$PWD/serviceAccountKey.json"
 *   npx tsx scripts/migrations/2026_11_scrub_quote_amount_history.ts           # dry-run (default)
 *   npx tsx scripts/migrations/2026_11_scrub_quote_amount_history.ts --apply
 */

import "dotenv/config";
import { db } from "../../src/lib/firebaseAdmin.js";
import { type DocumentReference } from "firebase-admin/firestore";

const firestore = db();
const BATCH_SIZE = 400;
const apply = process.argv.includes("--apply");

/** "sent WD-Q-1 ₹45000" → "sent WD-Q-1". Returns null when there is nothing to remove. */
export function scrubAmount(raw: unknown): string | null {
  if (typeof raw !== "string" || !raw.includes("₹")) return null;
  const cleaned = raw.replace(/\s*₹\s*[\d,]+(\.\d+)?/g, "").trim();
  return cleaned === raw ? null : cleaned;
}

async function main() {
  console.log(apply ? "=== APPLY MODE ===" : "=== DRY RUN (pass --apply to write) ===");

  // Unfiltered collection-group read: needs no extra index.
  const quotes = await firestore.collectionGroup("quotations").select().get();
  const enquiryIds = Array.from(
    new Set(quotes.docs.map((d) => d.ref.parent.parent?.id).filter((id): id is string => !!id)),
  );
  console.log(`Enquiries with quotations: ${enquiryIds.length}`);

  const ops: Array<{ ref: DocumentReference; data: Record<string, unknown> }> = [];
  let scanned = 0;
  for (const id of enquiryIds) {
    const history = await firestore
      .collection("enquiries").doc(id).collection("history")
      .where("field_changed", "==", "quotation")
      .get();
    for (const doc of history.docs) {
      scanned++;
      const data: Record<string, unknown> = {};
      const newValue = scrubAmount(doc.get("new_value"));
      const oldValue = scrubAmount(doc.get("old_value"));
      if (newValue !== null) data.new_value = newValue;
      if (oldValue !== null) data.old_value = oldValue;
      if (Object.keys(data).length === 0) continue;
      ops.push({ ref: doc.ref, data });
      // The enquiry id only: the amount itself is not printed.
      if (ops.length <= 10) console.log(`  would scrub enquiries/${id}/history/${doc.id}`);
    }
  }

  console.log(`Quotation history entries scanned: ${scanned}`);
  console.log(`Entries carrying an amount: ${ops.length}`);
  if (!apply) {
    console.log("Dry run only — nothing written.");
    return;
  }

  for (let i = 0; i < ops.length; i += BATCH_SIZE) {
    const batch = firestore.batch();
    for (const op of ops.slice(i, i + BATCH_SIZE)) batch.update(op.ref, op.data);
    await batch.commit();
    console.log(`  committed ${Math.min(i + BATCH_SIZE, ops.length)}/${ops.length}`);
  }
  console.log("Done.");
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
