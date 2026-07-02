#!/usr/bin/env tsx
/**
 * Migration: normalize enquiry statusValue to canonical vocabulary (D1).
 *
 * Usage:
 *   export GOOGLE_APPLICATION_CREDENTIALS="$PWD/serviceAccountKey.json"
 *   npx tsx scripts/migrations/2026_07_canonical_statuses.ts           # dry-run (default)
 *   npx tsx scripts/migrations/2026_07_canonical_statuses.ts --apply
 */

import "dotenv/config";
import { db } from "../../src/lib/firebaseAdmin.js";
import { FieldValue } from "firebase-admin/firestore";

const firestore = db();
const BATCH_SIZE = 400;
const apply = process.argv.includes("--apply");

const LEGACY_ALIASES: Record<string, string> = {
  in_progress: "in_talks",
  confirmed: "approved",
  quoted: "quote_sent",
  enquired: "new",
  assigned: "in_talks",
};

const LABELS: Record<string, string> = {
  new: "New",
  contacted: "Contacted",
  in_talks: "In Talks",
  quote_sent: "Quote Sent",
  approved: "Approved",
  scheduled: "Scheduled",
  completed: "Completed",
  not_interested: "Not Interested",
  closed_lost: "Closed Lost",
  cancelled: "Cancelled",
};

const LEGACY_FIELDS = ["status", "eventStatus", "status_slug"] as const;

function canonicalStatus(raw: unknown): string | null {
  if (typeof raw !== "string" || !raw.trim()) return null;
  const normalized = raw.trim().toLowerCase().replace(/\s+/g, "_");
  const canonical = LEGACY_ALIASES[normalized] ?? normalized;
  return canonical in LABELS ? canonical : null;
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
    const rawStatus = data.statusValue ?? data.eventStatus ?? data.status ?? data.status_slug;
    const canonical = canonicalStatus(rawStatus);
    if (!canonical) continue;

    const currentCanonical = canonicalStatus(data.statusValue);
    const hasLegacyFields = LEGACY_FIELDS.some((f) => data[f] != null);
    const needsLabel = data.statusLabel !== LABELS[canonical];
    const needsValue = currentCanonical !== canonical;

    if (!needsValue && !needsLabel && !hasLegacyFields) continue;

    const after: Record<string, unknown> = {
      statusValue: canonical,
      statusLabel: LABELS[canonical],
      updatedAt: FieldValue.serverTimestamp(),
    };
    for (const field of LEGACY_FIELDS) {
      after[field] = FieldValue.delete();
    }

    changes.push({
      id: doc.id,
      before: {
        statusValue: data.statusValue,
        statusLabel: data.statusLabel,
        status: data.status,
        eventStatus: data.eventStatus,
        status_slug: data.status_slug,
      },
      after: {
        statusValue: canonical,
        statusLabel: LABELS[canonical],
        deletedLegacyFields: LEGACY_FIELDS.filter((f) => data[f] != null),
      },
    });
  }

  return changes;
}

async function applyChanges(changes: Change[]): Promise<void> {
  for (let i = 0; i < changes.length; i += BATCH_SIZE) {
    const batch = firestore.batch();
    for (const change of changes.slice(i, i + BATCH_SIZE)) {
      batch.update(firestore.collection("enquiries").doc(change.id), change.after);
    }
    await batch.commit();
  }
}

async function main() {
  const changes = await collectChanges();
  console.log(`Status migration: ${changes.length} document(s) would change`);
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
  console.error("Status migration failed:", error);
  process.exit(1);
});
