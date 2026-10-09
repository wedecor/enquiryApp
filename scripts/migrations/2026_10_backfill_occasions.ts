#!/usr/bin/env tsx
/**
 * Migration: stamp yearly re-engagement occasion fields on every existing
 * completed enquiry:
 *   occasionKind      — wedding_anniversary | birthday | anniversary | baby | home | corporate | celebration
 *   occasionDate      — Timestamp (event date; wedding-family events use the wedding's date)
 *   occasionMonthDay  — 'MM-DD' in IST (queried daily by scheduleReengagements)
 *
 * Same logic as the live stamping (onEnquiryCompletedStampOccasion /
 * autoExpireEnquiries): it REUSES functions/src/reengagementLogic.ts, so the
 * keyword mapping and the ±10-day wedding-family dedupe cannot drift.
 *
 * Idempotent: writes only when the computed stamp differs from what is stored.
 * Skips merged duplicates and enquiries an admin edited by hand (occasionManual).
 * occasionPerson / occasionReminders and updatedAt are never touched.
 *
 * Usage:
 *   export GOOGLE_APPLICATION_CREDENTIALS="$PWD/serviceAccountKey.json"
 *   npx tsx scripts/migrations/2026_10_backfill_occasions.ts           # dry-run (default)
 *   npx tsx scripts/migrations/2026_10_backfill_occasions.ts --apply
 */

import "dotenv/config";
import { createRequire } from "node:module";
import { db } from "../../src/lib/firebaseAdmin.js";
import { Timestamp, type DocumentData, type DocumentReference } from "firebase-admin/firestore";

// functions/ is CommonJS; load it through require so tsx resolves every export.
type Logic = typeof import("../../functions/src/reengagementLogic.js");
type Status = typeof import("../../functions/src/statusVocabulary.js");
type Functions = typeof import("../../functions/src/eventFunctions.js");
const require = createRequire(import.meta.url);
const logic: Logic = require("../../functions/src/reengagementLogic.ts");
const status: Status = require("../../functions/src/statusVocabulary.ts");
const eventFunctions: Functions = require("../../functions/src/eventFunctions.ts");

type StampSource = import("../../functions/src/reengagementLogic.js").StampSource;

const firestore = db();
const BATCH_SIZE = 400;
const apply = process.argv.includes("--apply");

function toDate(raw: unknown): Date | null {
  if (raw instanceof Date) return raw;
  if (raw && typeof (raw as { toDate?: unknown }).toDate === "function") {
    return (raw as { toDate: () => Date }).toDate();
  }
  return null;
}

function str(raw: unknown): string | null {
  return typeof raw === "string" && raw.trim() ? raw.trim() : null;
}

function normalizePhone(raw: unknown): string {
  if (typeof raw !== "string") return "";
  const digits = raw.replace(/\D/g, "");
  return digits.length > 10 ? digits.slice(-10) : digits;
}

/** Mirrors functions/src/occasionStamping.ts toStampSource. */
function toSource(id: string, data: DocumentData): StampSource {
  // Multi-function bookings: main (wedding-anchor) function's type + date.
  const event = eventFunctions.occasionEventOf(data);
  return {
    id,
    eventTypeValue: event.eventTypeValue,
    eventTypeLabel: event.eventTypeLabel,
    eventDate: event.eventDate,
    fallbackDate: toDate(data.completedAt) ?? toDate(data.updatedAt) ?? toDate(data.createdAt) ?? new Date(),
    status: status.canonicalStatus(data.statusValue),
    merged: !!data.mergedInto,
    manual: data.occasionManual === true,
    occasionKind: data.occasionKind,
    occasionMonthDay: data.occasionMonthDay,
    occasionDate: toDate(data.occasionDate),
  };
}

async function main() {
  console.log(apply ? "=== APPLY MODE ===" : "=== DRY RUN (pass --apply to write) ===");
  const snap = await firestore.collection("enquiries").get();

  const sources = new Map<string, StampSource>();
  const refs = new Map<string, DocumentReference>();
  const byPhone = new Map<string, StampSource[]>();
  for (const doc of snap.docs) {
    const data = doc.data();
    const s = toSource(doc.id, data);
    sources.set(doc.id, s);
    refs.set(doc.id, doc.ref);
    const phone = str(data.phoneNormalized) ?? normalizePhone(data.customerPhone);
    if (phone.length >= 7) {
      const list = byPhone.get(phone) ?? [];
      list.push(s);
      byPhone.set(phone, list);
    }
  }
  const phoneOf = new Map<string, string>();
  for (const [phone, list] of byPhone) for (const s of list) phoneOf.set(s.id, phone);

  const ops: Array<{ ref: DocumentReference; data: Record<string, unknown> }> = [];
  const kindCounts = new Map<string, number>();
  let completed = 0;
  let skippedMerged = 0;
  let skippedManual = 0;
  let alreadyCorrect = 0;
  let weddingDateShifted = 0;
  let noEventDate = 0;

  for (const s of sources.values()) {
    if (s.status !== "completed") continue;
    completed++;
    if (s.merged) {
      skippedMerged++;
      continue;
    }
    if (s.manual) {
      skippedManual++;
      continue;
    }
    if (!s.eventDate) noEventDate++;
    const phone = phoneOf.get(s.id);
    const siblings = phone ? (byPhone.get(phone) ?? []).filter((x) => x.id !== s.id) : [];
    // Each enquiry's own stamp from its own ±10-day window (siblings get theirs in turn).
    const stamp = logic.computeOccasionStamps(s, siblings).get(s.id);
    if (!stamp) continue;

    const same =
      s.occasionKind === stamp.occasionKind &&
      s.occasionMonthDay === stamp.occasionMonthDay &&
      !!s.occasionDate &&
      s.occasionDate.getTime() === stamp.occasionDate.getTime();
    if (same) {
      alreadyCorrect++;
      continue;
    }
    if (s.eventDate && s.eventDate.getTime() !== stamp.occasionDate.getTime()) weddingDateShifted++;
    kindCounts.set(stamp.occasionKind, (kindCounts.get(stamp.occasionKind) ?? 0) + 1);
    ops.push({
      ref: refs.get(s.id)!,
      data: {
        occasionKind: stamp.occasionKind,
        occasionDate: Timestamp.fromDate(stamp.occasionDate),
        occasionMonthDay: stamp.occasionMonthDay,
      },
    });
  }

  console.log(`Enquiries scanned: ${snap.size}`);
  console.log(`  completed: ${completed}`);
  console.log(`    merged duplicates (skipped): ${skippedMerged}`);
  console.log(`    edited by hand (skipped): ${skippedManual}`);
  console.log(`    already stamped correctly: ${alreadyCorrect}`);
  console.log(`    without event date (fallback completedAt/createdAt): ${noEventDate}`);
  console.log(`    to stamp: ${ops.length} (wedding-family date shifted: ${weddingDateShifted})`);
  for (const [kind, count] of [...kindCounts.entries()].sort()) {
    console.log(`      ${kind.padEnd(20)} ${count}`);
  }

  if (apply && ops.length > 0) {
    for (let i = 0; i < ops.length; i += BATCH_SIZE) {
      const batch = firestore.batch();
      for (const op of ops.slice(i, i + BATCH_SIZE)) batch.update(op.ref, op.data);
      await batch.commit();
      console.log(`  committed ${Math.min(i + BATCH_SIZE, ops.length)}/${ops.length}`);
    }
    console.log(`  Applied ${ops.length} enquiry update(s).`);
  }
}

main().catch((error) => {
  console.error("Occasion backfill failed:", error);
  process.exit(1);
});
