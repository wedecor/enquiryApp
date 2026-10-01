#!/usr/bin/env tsx
/**
 * Migration: normalize enquiry status values + labels, purge inactive legacy status dropdowns.
 *
 * 1. Enquiries: statusValue → canonical slug (legacy aliases resolved), statusLabel → canonical
 *    label. Unknown values are logged and left untouched.
 * 2. dropdowns/statuses/items: hard-delete items that are inactive (active == false) AND whose
 *    value is not canonical.
 *
 * Vocabulary mirrors lib/core/constants/status_vocabulary.dart.
 *
 * Usage:
 *   export GOOGLE_APPLICATION_CREDENTIALS="$PWD/serviceAccountKey.json"
 *   npx tsx scripts/migrations/2026_10_normalize_status_labels.ts           # dry-run (default)
 *   npx tsx scripts/migrations/2026_10_normalize_status_labels.ts --apply
 */

import "dotenv/config";
import { db } from "../../src/lib/firebaseAdmin.js";
import { FieldValue, type DocumentReference } from "firebase-admin/firestore";

const firestore = db();
const BATCH_SIZE = 400;
const apply = process.argv.includes("--apply");

const LABELS: Record<string, string> = {
  new: "New",
  in_talks: "In Talks",
  approved: "Approved",
  completed: "Completed",
  not_interested: "Not Interested",
  closed_lost: "Closed Lost",
  cancelled: "Cancelled",
};

const LEGACY_ALIASES: Record<string, string> = {
  contacted: "in_talks",
  quote_sent: "in_talks",
  quoted: "in_talks",
  in_progress: "in_talks",
  assigned: "in_talks",
  confirmed: "approved",
  scheduled: "approved",
  enquired: "new",
};

function normalizeKey(raw: string): string {
  return raw.trim().toLowerCase().replace(/ /g, "_");
}

function isCanonical(value: string): boolean {
  return Object.hasOwn(LABELS, value);
}

function canonicalStatus(raw: unknown): string | null {
  if (typeof raw !== "string" || !raw.trim()) return null;
  const normalized = normalizeKey(raw);
  const canonical = Object.hasOwn(LEGACY_ALIASES, normalized)
    ? LEGACY_ALIASES[normalized]
    : normalized;
  return isCanonical(canonical) ? canonical : null;
}

async function commitInBatches(
  ops: Array<{ ref: DocumentReference; data?: Record<string, unknown>; delete?: boolean }>,
): Promise<void> {
  for (let i = 0; i < ops.length; i += BATCH_SIZE) {
    const batch = firestore.batch();
    for (const op of ops.slice(i, i + BATCH_SIZE)) {
      if (op.delete) {
        batch.delete(op.ref);
      } else {
        batch.update(op.ref, op.data!);
      }
    }
    await batch.commit();
  }
}

async function normalizeEnquiries(): Promise<void> {
  const snap = await firestore.collection("enquiries").get();
  const transitions = new Map<string, number>();
  const unknown: Array<{ id: string; statusValue: unknown }> = [];
  const ops: Array<{ ref: DocumentReference; data: Record<string, unknown> }> = [];
  let alreadyCanonical = 0;

  for (const doc of snap.docs) {
    const data = doc.data();
    const raw = data.statusValue;
    const canonical = canonicalStatus(raw);

    if (!canonical) {
      unknown.push({ id: doc.id, statusValue: raw ?? null });
      continue;
    }

    const label = LABELS[canonical];
    const valueChanged = raw !== canonical;
    const labelChanged = data.statusLabel !== label;
    if (!valueChanged && !labelChanged) {
      alreadyCanonical++;
      continue;
    }

    const key = `${String(raw)} (${String(data.statusLabel ?? "—")}) → ${canonical} (${label})`;
    transitions.set(key, (transitions.get(key) ?? 0) + 1);

    const update: Record<string, unknown> = { statusValue: canonical, statusLabel: label };
    if (valueChanged) update.updatedAt = FieldValue.serverTimestamp();
    ops.push({ ref: doc.ref, data: update });
  }

  console.log(`\nEnquiries scanned: ${snap.size}`);
  console.log(`  already canonical: ${alreadyCanonical}`);
  console.log(`  to update: ${ops.length}`);
  for (const [key, count] of [...transitions.entries()].sort((a, b) => b[1] - a[1])) {
    console.log(`    ${count.toString().padStart(5)}  ${key}`);
  }
  if (unknown.length > 0) {
    console.log(`  unknown / missing statusValue (left untouched): ${unknown.length}`);
    for (const u of unknown) {
      console.log(`    ${u.id}: ${JSON.stringify(u.statusValue)}`);
    }
  }

  if (apply && ops.length > 0) {
    await commitInBatches(ops);
    console.log(`  Applied ${ops.length} enquiry update(s).`);
  }
}

async function purgeInactiveLegacyStatusDropdowns(): Promise<void> {
  const snap = await firestore.collection("dropdowns").doc("statuses").collection("items").get();
  const ops: Array<{ ref: DocumentReference; delete: true }> = [];

  console.log(`\nStatus dropdown items scanned: ${snap.size}`);
  for (const doc of snap.docs) {
    const data = doc.data();
    const value = typeof data.value === "string" ? data.value : doc.id;
    const canonical = isCanonical(value);
    if (data.active === false && !canonical) {
      console.log(`  delete: ${doc.id} (value=${value}, label=${data.label ?? "—"}, active=false)`);
      ops.push({ ref: doc.ref, delete: true });
    } else if (!canonical) {
      console.log(`  keep (active non-canonical, review manually): ${doc.id} (value=${value})`);
    }
  }
  console.log(`  to delete: ${ops.length}`);

  if (apply && ops.length > 0) {
    await commitInBatches(ops);
    console.log(`  Deleted ${ops.length} dropdown item(s).`);
  }
}

async function main() {
  console.log(apply ? "=== APPLY MODE ===" : "=== DRY RUN (pass --apply to write) ===");
  await normalizeEnquiries();
  await purgeInactiveLegacyStatusDropdowns();
}

main().catch((error) => {
  console.error("Status label normalization failed:", error);
  process.exit(1);
});
