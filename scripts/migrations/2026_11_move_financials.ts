#!/usr/bin/env tsx
/**
 * Migration: move booking money off the enquiry into enquiries/{id}/financial/summary.
 *
 * Staff may read the enquiries assigned to them, and Firestore cannot hide fields,
 * so money moves to an admin-only doc (firestore.rules; EnquiryFinancials in the
 * app). For every enquiry that still carries any of the fields below:
 *   1. copy them into financial/summary (values already in the summary win — they
 *      are newer, written by the current app);
 *   2. delete them from the enquiry.
 * Both writes go in the same batch per enquiry. Idempotent: a second run finds
 * nothing to move.
 *
 * DEFAULT IS DRY-RUN. It prints what would change and writes nothing.
 *
 * Usage:
 *   export GOOGLE_APPLICATION_CREDENTIALS="$PWD/serviceAccountKey.json"
 *   npx tsx scripts/migrations/2026_11_move_financials.ts           # dry-run (default)
 *   npx tsx scripts/migrations/2026_11_move_financials.ts --apply   # only after review
 *
 * Run --apply only after the app build that reads the summary is live for admins
 * (older admin builds would show no amounts once the parent fields are gone).
 */

import "dotenv/config";
import { db } from "../../src/lib/firebaseAdmin.js";
import { FieldValue } from "firebase-admin/firestore";

export const MONEY_FIELDS = [
  "totalCost",
  "advancePaid",
  "paymentStatus",
  "paymentStatusValue",
  "paymentStatusLabel",
  "quotedAmount",
  "quotedAt",
] as const;

const apply = process.argv.includes("--apply");
/** Enquiries per batch: each uses 2 writes (summary set + parent update). */
const PER_BATCH = 200;

export type MoveFinancialsPlan = {
  id: string;
  /** Fields to merge into financial/summary (only keys the summary lacks). */
  summary: Record<string, unknown>;
  /** Parent keys to delete. */
  remove: string[];
};

/** Pure planning step: what moving one enquiry's money would write. */
export function planMove(
  id: string,
  parent: Record<string, unknown>,
  existingSummary: Record<string, unknown> | undefined,
): MoveFinancialsPlan | null {
  const remove = MONEY_FIELDS.filter((f) => f in parent);
  if (remove.length === 0) return null;
  const summary: Record<string, unknown> = {};
  for (const field of remove) {
    if (existingSummary && field in existingSummary) continue;
    summary[field] = parent[field] ?? null;
  }
  return { id, summary, remove };
}

async function main() {
  const firestore = db();
  const snapshot = await firestore.collection("enquiries").get();
  const plans: MoveFinancialsPlan[] = [];
  for (const doc of snapshot.docs) {
    const data = doc.data();
    if (!MONEY_FIELDS.some((f) => f in data)) continue;
    const summarySnap = await doc.ref.collection("financial").doc("summary").get();
    const plan = planMove(doc.id, data, summarySnap.exists ? summarySnap.data() : undefined);
    if (plan) plans.push(plan);
  }

  console.log(`Financials migration: ${plans.length} enquiry(ies) carry money on the parent`);
  console.log(`Mode: ${apply ? "APPLY" : "DRY-RUN (nothing is written)"}`);
  for (const sample of plans.slice(0, 5)) {
    // Field names only — no amounts in the log.
    console.log(JSON.stringify({ id: sample.id, copy: Object.keys(sample.summary), remove: sample.remove }));
  }

  if (!apply || plans.length === 0) return;
  for (let i = 0; i < plans.length; i += PER_BATCH) {
    const batch = firestore.batch();
    for (const plan of plans.slice(i, i + PER_BATCH)) {
      const ref = firestore.collection("enquiries").doc(plan.id);
      batch.set(
        ref.collection("financial").doc("summary"),
        { ...plan.summary, updatedAt: FieldValue.serverTimestamp() },
        { merge: true },
      );
      batch.update(ref, Object.fromEntries(plan.remove.map((f) => [f, FieldValue.delete()])));
    }
    await batch.commit();
  }
  console.log(`Moved money for ${plans.length} enquiry(ies).`);
}

main().catch((error) => {
  console.error("Financials migration failed:", error);
  process.exit(1);
});
