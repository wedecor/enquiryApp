#!/usr/bin/env tsx
/**
 * Migration: move money/payment history entries out of staff-readable
 * `enquiries/{id}/history` into admin-only `enquiries/{id}/financial_history`.
 *
 * Scans `enquiries/{id}/history` for docs whose `field_changed` is in the money
 * history field set (case-insensitive), copies each to
 * `enquiries/{id}/financial_history/{hid}` with the same doc id and data, and
 * deletes the original from `history`. `enquiries_trash` is not touched.
 *
 * Usage:
 *   export GOOGLE_APPLICATION_CREDENTIALS="$PWD/serviceAccountKey.json"
 *   npx tsx scripts/migrations/2026_11_move_money_history.ts           # dry-run (default)
 *   npx tsx scripts/migrations/2026_11_move_money_history.ts --apply
 */

import "dotenv/config";
import { db } from "../../src/lib/firebaseAdmin.js";
import { type DocumentReference } from "firebase-admin/firestore";

const firestore = db();
const BATCH_SIZE = 200; // 2 ops per entry (set + delete) = 400 writes <= 500 limit
const apply = process.argv.includes("--apply");

const MONEY_HISTORY_FIELDS_LOWER = new Set([
  "totalcost",
  "advancepaid",
  "quotedamount",
  "quotedat",
  "paymentstatus",
  "paymentstatusvalue",
  "paymentstatuslabel",
]);

export function isMoneyHistoryField(fieldChanged: unknown): boolean {
  if (typeof fieldChanged !== "string") return false;
  return MONEY_HISTORY_FIELDS_LOWER.has(fieldChanged.trim().toLowerCase());
}

async function main() {
  console.log(apply ? "=== APPLY MODE ===" : "=== DRY RUN (pass --apply to write) ===");

  const enquiriesSnap = await firestore.collection("enquiries").select().get();
  console.log(`Enquiries scanned: ${enquiriesSnap.size} (enquiries_trash untouched)`);

  interface MoveOp {
    sourceRef: DocumentReference;
    targetRef: DocumentReference;
    data: Record<string, unknown>;
  }

  const ops: MoveOp[] = [];
  let historyScanned = 0;

  for (const enqDoc of enquiriesSnap.docs) {
    const historySnap = await enqDoc.ref.collection("history").get();
    for (const hDoc of historySnap.docs) {
      historyScanned++;
      const fieldChanged = hDoc.get("field_changed");
      if (!isMoneyHistoryField(fieldChanged)) continue;

      const targetRef = enqDoc.ref.collection("financial_history").doc(hDoc.id);
      ops.push({
        sourceRef: hDoc.ref,
        targetRef,
        data: hDoc.data(),
      });
      if (ops.length <= 10) {
        console.log(
          `  would move enquiries/${enqDoc.id}/history/${hDoc.id} (${String(fieldChanged)}) -> financial_history/${hDoc.id}`,
        );
      }
    }
  }

  console.log(`History entries scanned: ${historyScanned}`);
  console.log(`Money history entries to move: ${ops.length}`);
  if (!apply) {
    console.log("Dry run only — nothing written.");
    return;
  }

  for (let i = 0; i < ops.length; i += BATCH_SIZE) {
    const batch = firestore.batch();
    for (const op of ops.slice(i, i + BATCH_SIZE)) {
      batch.set(op.targetRef, op.data);
      batch.delete(op.sourceRef);
    }
    await batch.commit();
    console.log(`  committed ${Math.min(i + BATCH_SIZE, ops.length)}/${ops.length}`);
  }
  console.log("Done.");
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
