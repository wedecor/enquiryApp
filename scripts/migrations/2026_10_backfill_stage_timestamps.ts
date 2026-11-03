#!/usr/bin/env tsx
/**
 * Migration: backfill analytics stage timestamps from each enquiry's history.
 *
 * For every enquiry, reads `enquiries/{id}/history` entries where
 * field_changed is a status field and sets, only when missing:
 *   - inTalksAt / approvedAt / completedAt / lostAt  → earliest entry INTO that stage
 *   - firstContactAt (+ firstContactEstimated: true) → earliest entry OUT OF "new"
 *
 * Current status is also honoured: an enquiry that is approved today but has no
 * history entry gets no invented timestamp (left empty on purpose).
 *
 * Vocabulary mirrors lib/core/constants/status_vocabulary.dart.
 *
 * Usage:
 *   export GOOGLE_APPLICATION_CREDENTIALS="$PWD/serviceAccountKey.json"
 *   npx tsx scripts/migrations/2026_10_backfill_stage_timestamps.ts           # dry-run (default)
 *   npx tsx scripts/migrations/2026_10_backfill_stage_timestamps.ts --apply
 */

import "dotenv/config";
import { db } from "../../src/lib/firebaseAdmin.js";
import { Timestamp, type DocumentReference } from "firebase-admin/firestore";

const firestore = db();
const BATCH_SIZE = 400;
const apply = process.argv.includes("--apply");

const CANONICAL = new Set([
  "new",
  "in_talks",
  "approved",
  "completed",
  "not_interested",
  "closed_lost",
  "cancelled",
]);

const LEGACY_ALIASES: Record<string, string> = {
  contacted: "in_talks",
  quote_sent: "in_talks",
  quoted: "in_talks",
  in_progress: "in_talks",
  assigned: "in_talks",
  confirmed: "approved",
  scheduled: "approved",
  enquired: "new",
  not_intrested: "not_interested",
};

const STATUS_FIELDS = new Set(["statusValue", "status", "eventStatus"]);

function canonical(raw: unknown): string | null {
  if (typeof raw !== "string" || !raw.trim()) return null;
  const n = raw.trim().toLowerCase().replace(/ /g, "_");
  const c = Object.hasOwn(LEGACY_ALIASES, n) ? LEGACY_ALIASES[n] : n;
  return CANONICAL.has(c) ? c : null;
}

function stageField(status: string): string | null {
  switch (status) {
    case "in_talks":
      return "inTalksAt";
    case "approved":
      return "approvedAt";
    case "completed":
      return "completedAt";
    case "not_interested":
    case "closed_lost":
    case "cancelled":
      return "lostAt";
    default:
      return null;
  }
}

function toTimestamp(raw: unknown): Timestamp | null {
  if (raw instanceof Timestamp) return raw;
  if (raw instanceof Date) return Timestamp.fromDate(raw);
  return null;
}

async function main() {
  console.log(apply ? "=== APPLY MODE ===" : "=== DRY RUN (pass --apply to write) ===");
  const snap = await firestore.collection("enquiries").get();
  const ops: Array<{ ref: DocumentReference; data: Record<string, unknown> }> = [];
  const fieldCounts = new Map<string, number>();
  let withoutHistory = 0;

  for (const doc of snap.docs) {
    const data = doc.data();
    const history = await doc.ref.collection("history").get();

    const entries = history.docs
      .map((h) => h.data())
      .filter((h) => STATUS_FIELDS.has(String(h.field_changed ?? "")))
      .map((h) => ({
        from: canonical(h.old_value),
        to: canonical(h.new_value),
        at: toTimestamp(h.timestamp),
      }))
      .filter((e): e is { from: string | null; to: string; at: Timestamp } => !!e.to && !!e.at)
      .sort((a, b) => a.at.toMillis() - b.at.toMillis());

    if (entries.length === 0) {
      withoutHistory += 1;
      continue;
    }

    const update: Record<string, unknown> = {};
    for (const e of entries) {
      const field = stageField(e.to);
      if (field && data[field] == null && update[field] == null) {
        update[field] = e.at;
      }
      if (
        data.firstContactAt == null &&
        update.firstContactAt == null &&
        (e.from === "new" || e.from === null) &&
        e.to !== "new"
      ) {
        update.firstContactAt = e.at;
        update.firstContactEstimated = true;
      }
    }

    if (Object.keys(update).length > 0) {
      ops.push({ ref: doc.ref, data: update });
      for (const key of Object.keys(update)) {
        if (key === "firstContactEstimated") continue;
        fieldCounts.set(key, (fieldCounts.get(key) ?? 0) + 1);
      }
    }
  }

  console.log(`Enquiries scanned: ${snap.size}`);
  console.log(`  without status history (skipped): ${withoutHistory}`);
  console.log(`  to update: ${ops.length}`);
  for (const [field, count] of [...fieldCounts.entries()].sort()) {
    console.log(`    ${field.padEnd(16)} ${count}`);
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
  console.error("Stage timestamp backfill failed:", error);
  process.exit(1);
});
