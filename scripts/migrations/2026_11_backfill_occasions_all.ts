#!/usr/bin/env tsx
/**
 * Migration: stamp yearly re-engagement occasion fields on every enquiry that is
 * wish-eligible under the Nov 2026 rule (functions/src/reengagementLogic.isWishEligible):
 *   - occasion event date (main / wedding-anchor function) is in the past (IST)
 *   - not merged, lostReason not duplicate/out_of_scope, kind not corporate
 *   - usable phone, occasionReminders not false
 * Status does not matter: completed, lost, and open-past all qualify.
 *
 * Idempotent: writes only when the computed stamp differs. Skips occasionManual.
 * Never prints customer data — only aggregate counts by category.
 *
 * Usage:
 *   export GOOGLE_APPLICATION_CREDENTIALS="$PWD/serviceAccountKey.json"
 *   npx tsx scripts/migrations/2026_11_backfill_occasions_all.ts           # dry-run
 *   npx tsx scripts/migrations/2026_11_backfill_occasions_all.ts --apply
 */

import "dotenv/config";
import { createRequire } from "node:module";
import { db } from "../../src/lib/firebaseAdmin.js";
import { Timestamp, type DocumentData, type DocumentReference } from "firebase-admin/firestore";

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
const LOST = new Set(["not_interested", "closed_lost", "cancelled"]);
const OPEN = new Set(["new", "in_talks", "approved"]);

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

function toSource(id: string, data: DocumentData): StampSource {
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

function categoryOf(st: string | null): "completed" | "lost" | "open-past" | "other" {
  if (st === "completed") return "completed";
  if (st && LOST.has(st)) return "lost";
  if (st && OPEN.has(st)) return "open-past";
  return "other";
}

async function main() {
  console.log(apply ? "=== APPLY MODE ===" : "=== DRY RUN (pass --apply to write) ===");
  const snap = await firestore.collection("enquiries").get();
  const now = new Date();

  const sources = new Map<string, StampSource>();
  const refs = new Map<string, DocumentReference>();
  const raw = new Map<string, DocumentData>();
  const byPhone = new Map<string, StampSource[]>();
  for (const doc of snap.docs) {
    const data = doc.data();
    const s = toSource(doc.id, data);
    sources.set(doc.id, s);
    refs.set(doc.id, doc.ref);
    raw.set(doc.id, data);
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
  const eligibleByCat = { completed: 0, lost: 0, "open-past": 0, other: 0 };
  const toStampByCat = { completed: 0, lost: 0, "open-past": 0, other: 0 };
  let skippedMerged = 0;
  let skippedManual = 0;
  let alreadyCorrect = 0;
  let notEligible = 0;

  for (const s of sources.values()) {
    const data = raw.get(s.id)!;
    const phone = phoneOf.get(s.id) ?? "";
    const eligible = logic.isWishEligible({
      eventDate: s.eventDate,
      now,
      merged: s.merged || data.lostReason === "duplicate",
      lostReason: data.lostReason,
      occasionKind: s.occasionKind,
      eventTypeValue: s.eventTypeValue,
      eventTypeLabel: s.eventTypeLabel,
      remindersOn: data.occasionReminders !== false,
      phoneNormalized: phone,
    });
    if (!eligible) {
      notEligible++;
      continue;
    }
    const cat = categoryOf(s.status);
    eligibleByCat[cat]++;
    if (s.merged) {
      skippedMerged++;
      continue;
    }
    if (s.manual) {
      skippedManual++;
      continue;
    }
    const siblings = phone ? (byPhone.get(phone) ?? []).filter((x) => x.id !== s.id) : [];
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
    toStampByCat[cat]++;
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
  console.log(`  not eligible: ${notEligible}`);
  console.log(`  eligible: completed=${eligibleByCat.completed} lost=${eligibleByCat.lost} open-past=${eligibleByCat["open-past"]} other=${eligibleByCat.other}`);
  console.log(`    merged (skipped): ${skippedMerged}`);
  console.log(`    edited by hand (skipped): ${skippedManual}`);
  console.log(`    already stamped correctly: ${alreadyCorrect}`);
  console.log(
    `    to stamp: ${ops.length} (completed=${toStampByCat.completed} lost=${toStampByCat.lost} open-past=${toStampByCat["open-past"]} other=${toStampByCat.other})`
  );
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
  console.error("Occasion backfill (all eligible) failed:", error);
  process.exit(1);
});
