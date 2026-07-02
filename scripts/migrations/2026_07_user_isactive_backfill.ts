#!/usr/bin/env tsx
/**
 * Migration: backfill `isActive` on user documents.
 *
 * DEPENDENCY: Run this migration in Phase 7 BEFORE shipping the app change that
 * filters getActiveUsers() with `where('isActive', isEqualTo: true)`.
 * Legacy docs may use `active` instead of `isActive`.
 *
 * For each user doc missing `isActive`, sets `isActive: (data.active ?? true)`.
 *
 * Usage:
 *   export GOOGLE_APPLICATION_CREDENTIALS="$PWD/serviceAccountKey.json"
 *   npx tsx scripts/migrations/2026_07_user_isactive_backfill.ts           # dry-run (default)
 *   npx tsx scripts/migrations/2026_07_user_isactive_backfill.ts --apply
 */

import "dotenv/config";
import { db } from "../../src/lib/firebaseAdmin.js";
import { FieldValue } from "firebase-admin/firestore";

const firestore = db();
const BATCH_SIZE = 400;

const apply = process.argv.includes("--apply");

interface Change {
  id: string;
  before: Record<string, unknown>;
  after: Record<string, unknown>;
}

async function collectChanges(): Promise<Change[]> {
  const changes: Change[] = [];
  const snapshot = await firestore.collection("users").get();

  for (const doc of snapshot.docs) {
    const data = doc.data();
    if (data.isActive !== undefined) continue;

    const isActive = data.active ?? true;
    changes.push({
      id: doc.id,
      before: { isActive: data.isActive, active: data.active },
      after: { isActive },
    });
  }

  return changes;
}

async function applyChanges(changes: Change[]): Promise<void> {
  for (let i = 0; i < changes.length; i += BATCH_SIZE) {
    const batch = firestore.batch();
    const slice = changes.slice(i, i + BATCH_SIZE);

    for (const change of slice) {
      batch.update(firestore.collection("users").doc(change.id), {
        isActive: change.after.isActive,
        updatedAt: FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
    console.log(`Committed batch ${Math.floor(i / BATCH_SIZE) + 1} (${slice.length} docs)`);
  }
}

async function main(): Promise<void> {
  const changes = await collectChanges();
  console.log(`Found ${changes.length} user(s) missing isActive`);

  const samples = changes.slice(0, 5);
  for (const sample of samples) {
    console.log(`  ${sample.id}: ${JSON.stringify(sample.before)} → ${JSON.stringify(sample.after)}`);
  }

  if (!apply) {
    console.log("Dry-run only. Pass --apply to write changes.");
    return;
  }

  if (changes.length === 0) {
    console.log("Nothing to apply.");
    return;
  }

  await applyChanges(changes);
  console.log(`Applied ${changes.length} update(s).`);
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
