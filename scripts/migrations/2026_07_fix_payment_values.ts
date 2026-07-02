#!/usr/bin/env tsx
/**
 * Migration: normalize enquiry payment status values to canonical vocabulary (D4).
 *
 * Maps legacy values:
 *   unpaid → pending, no_payment → pending, advance_paid → partial, full_payment → paid
 *
 * Usage:
 *   export GOOGLE_APPLICATION_CREDENTIALS="$PWD/serviceAccountKey.json"
 *   npx tsx scripts/migrations/2026_07_fix_payment_values.ts           # dry-run (default)
 *   npx tsx scripts/migrations/2026_07_fix_payment_values.ts --apply
 */

import "dotenv/config";
import { db } from "../../src/lib/firebaseAdmin.js";
import { FieldValue } from "firebase-admin/firestore";

const firestore = db();
const BATCH_SIZE = 400;

const LEGACY_MAP: Record<string, string> = {
  unpaid: "pending",
  no_payment: "pending",
  advance_paid: "partial",
  full_payment: "paid",
};

const LABELS: Record<string, string> = {
  pending: "Pending",
  partial: "Partial",
  paid: "Paid",
  overdue: "Overdue",
};

const apply = process.argv.includes("--apply");

function normalizePayment(raw: unknown): string | null {
  if (typeof raw !== "string" || !raw.trim()) return null;
  const key = raw.trim().toLowerCase().replace(/\s+/g, "_");
  if (LEGACY_MAP[key]) return LEGACY_MAP[key];
  if (key in LABELS) return key;
  return null;
}

interface Change {
  id: string;
  before: Record<string, unknown>;
  after: Record<string, unknown>;
}

async function collectChanges(): Promise<Change[]> {
  const changes: Change[] = [];
  const snapshot = await firestore.collection("enquiries").get();

  for (const doc of snapshot.docs) {
    const data = doc.data();
    const paymentFields = [data.paymentStatusValue, data.paymentStatus] as unknown[];

    let canonical: string | null = null;
    for (const field of paymentFields) {
      const normalized = normalizePayment(field);
      if (normalized) {
        canonical = normalized;
        break;
      }
    }

    if (!canonical) continue;

    const currentValue = (data.paymentStatusValue ?? data.paymentStatus) as string | undefined;
    const currentNorm = currentValue ? normalizePayment(currentValue) : null;
    const needsValueUpdate = currentNorm !== canonical;
    const needsLabelUpdate = data.paymentStatusLabel !== LABELS[canonical];

    if (!needsValueUpdate && !needsLabelUpdate) continue;

    const after: Record<string, unknown> = {
      paymentStatusValue: canonical,
      paymentStatus: canonical,
      paymentStatusLabel: LABELS[canonical],
      updatedAt: FieldValue.serverTimestamp(),
    };

    changes.push({
      id: doc.id,
      before: {
        paymentStatus: data.paymentStatus,
        paymentStatusValue: data.paymentStatusValue,
        paymentStatusLabel: data.paymentStatusLabel,
      },
      after,
    });
  }

  return changes;
}

async function applyChanges(changes: Change[]): Promise<void> {
  for (let i = 0; i < changes.length; i += BATCH_SIZE) {
    const batch = firestore.batch();
    const slice = changes.slice(i, i + BATCH_SIZE);
    for (const change of slice) {
      batch.update(firestore.collection("enquiries").doc(change.id), change.after);
    }
    await batch.commit();
  }
}

async function main() {
  const changes = await collectChanges();
  console.log(`Payment migration: ${changes.length} document(s) would change`);
  console.log(`Mode: ${apply ? "APPLY" : "DRY-RUN"}`);

  for (const sample of changes.slice(0, 5)) {
    console.log(JSON.stringify({ id: sample.id, before: sample.before, after: sample.after }, null, 2));
  }

  if (apply && changes.length > 0) {
    await applyChanges(changes);
    console.log(`Applied ${changes.length} update(s).`);
  }
}

main().catch((error) => {
  console.error("Payment migration failed:", error);
  process.exit(1);
});
