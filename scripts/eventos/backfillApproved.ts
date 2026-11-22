/**
 * Backfill / reconcile approved Enquiries → EventOS feed (M5-01).
 *
 * Dry-run by default (counts + 3 PII-masked sample payloads).
 *   npx tsx scripts/eventos/backfillApproved.ts
 *   npx tsx scripts/eventos/backfillApproved.ts --apply
 *
 * Env:
 *   EVENTOS_FEED_URL       full sync URL (required for --apply)
 *   EVENTOS_FEED_SECRET    HMAC secret (required for --apply)
 *   EVENTOS_API_URL        API base for backfill-check (default: feed URL origin)
 *   EVENTOS_OWNER_TOKEN    Bearer access token with integrations:enquiries:manage
 *   GOOGLE_APPLICATION_CREDENTIALS  (or `gcloud auth application-default login`)
 *
 * Throttled to 5 deliveries/second.
 */

import { createHash, randomUUID } from "node:crypto";
import { initializeApp, applicationDefault, getApps } from "firebase-admin/app";
import { getFirestore } from "firebase-admin/firestore";
import {
  buildEventOSPayload,
  hashEventOSPayload,
} from "../../functions/src/eventosPayload";
import { signEventOSFeedBody } from "../../functions/src/eventosSign";
import { canonicalStatus } from "../../functions/src/statusVocabulary";

const APPLY = process.argv.includes("--apply");
const RATE_PER_SEC = 5;

function maskPii(payload: ReturnType<typeof buildEventOSPayload>) {
  return {
    ...payload,
    customer: {
      name: payload.customer.name ? `${payload.customer.name.slice(0, 1)}***` : null,
      phone: payload.customer.phone ? `***${payload.customer.phone.slice(-4)}` : null,
      email: payload.customer.email ? "***@***" : null,
    },
    money: payload.money
      ? { totalCost: "***", advancePaid: "***", currency: payload.money.currency }
      : undefined,
  };
}

function sleep(ms: number) {
  return new Promise((r) => setTimeout(r, ms));
}

async function main() {
  if (getApps().length === 0) {
    initializeApp({ credential: applicationDefault(), projectId: "wedecorenquries" });
  }
  const db = getFirestore();

  // Full collection scan is fine for a rare operator script; avoids `in` query limits
  // across status aliases.
  const all = await db.collection("enquiries").get();
  const candidates: Array<{
    id: string;
    enquiry: Record<string, unknown>;
    financial: Record<string, unknown> | null;
    sourceUpdatedAt: string;
  }> = [];

  for (const doc of all.docs) {
    const enquiry = doc.data() as Record<string, unknown>;
    const status = canonicalStatus(enquiry.statusValue ?? enquiry.status ?? enquiry.eventStatus);
    const syncSnap = await doc.ref.collection("private").doc("eventosSync").get();
    const previouslySynced = syncSnap.exists;
    const include =
      status === "approved" ||
      status === "completed" ||
      (status === "cancelled" && previouslySynced);
    if (!include) continue;

    const financialSnap = await doc.ref.collection("financial").doc("summary").get();
    const financial = financialSnap.exists
      ? (financialSnap.data() as Record<string, unknown>)
      : null;
    const payload = buildEventOSPayload(doc.id, enquiry, financial);
    candidates.push({
      id: doc.id,
      enquiry,
      financial,
      sourceUpdatedAt: payload.sourceUpdatedAt,
    });
  }

  console.log(`Candidates: ${candidates.length} (dry-run=${!APPLY})`);
  for (const sample of candidates.slice(0, 3)) {
    const payload = buildEventOSPayload(sample.id, sample.enquiry, sample.financial);
    console.log("--- sample", sample.id, "hash", hashEventOSPayload(payload).slice(0, 12));
    console.log(JSON.stringify(maskPii(payload), null, 2));
  }

  if (!APPLY) {
    console.log("Re-run with --apply to send. Skipping backfill-check without apply.");
    return;
  }

  const feedUrl = (process.env.EVENTOS_FEED_URL ?? "").trim();
  const secret = (process.env.EVENTOS_FEED_SECRET ?? "").trim();
  if (!feedUrl || !secret) {
    throw new Error("EVENTOS_FEED_URL and EVENTOS_FEED_SECRET are required for --apply");
  }

  const intervalMs = Math.ceil(1000 / RATE_PER_SEC);
  let sent = 0;
  let failed = 0;

  for (const item of candidates) {
    const payload = buildEventOSPayload(item.id, item.enquiry, item.financial);
    const rawBody = JSON.stringify(payload);
    const timestamp = Math.floor(Date.now() / 1000).toString();
    const signature = signEventOSFeedBody(secret, timestamp, rawBody);
    // Stable-ish id per payload version so retries of the same content collide safely.
    const deliveryId =
      createHash("sha256")
        .update(`${item.id}:${hashEventOSPayload(payload)}`)
        .digest("hex")
        .slice(0, 32)
        .replace(/^(.{8})(.{4})(.{4})(.{4})(.{12})$/, "$1-$2-$3-$4-$5") || randomUUID();

    try {
      const res = await fetch(feedUrl, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-EventOS-Timestamp": timestamp,
          "X-EventOS-Signature": signature,
          "X-EventOS-Delivery-Id": deliveryId,
        },
        body: rawBody,
      });
      if (!res.ok) {
        failed += 1;
        console.error(`FAIL ${item.id} http=${res.status}`);
      } else {
        sent += 1;
        console.log(`OK ${item.id} http=${res.status}`);
      }
    } catch (err) {
      failed += 1;
      console.error(`FAIL ${item.id}`, err instanceof Error ? err.message : err);
    }
    await sleep(intervalMs);
  }

  console.log(`Sent=${sent} failed=${failed}`);

  const apiBase =
    (process.env.EVENTOS_API_URL ?? "").trim() ||
    (() => {
      try {
        return new URL(feedUrl).origin;
      } catch {
        return "";
      }
    })();
  const ownerToken = (process.env.EVENTOS_OWNER_TOKEN ?? "").trim();
  if (!apiBase || !ownerToken) {
    console.log(
      "Skip backfill-check (set EVENTOS_API_URL + EVENTOS_OWNER_TOKEN to reconcile).",
    );
    return;
  }

  const items = candidates.map((c) => ({
    enquiryId: c.id,
    sourceUpdatedAt: c.sourceUpdatedAt,
  }));
  const checkRes = await fetch(`${apiBase}/api/v1/integrations/enquiries/backfill-check`, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Authorization: `Bearer ${ownerToken}`,
    },
    body: JSON.stringify({ items }),
  });
  const checkJson = (await checkRes.json()) as {
    data?: { missing?: string[]; stale?: string[]; upToDate?: number };
    missing?: string[];
    stale?: string[];
    upToDate?: number;
  };
  const data = checkJson.data ?? checkJson;
  console.log("Reconciliation:");
  console.log(`  in Firebase: ${candidates.length}`);
  console.log(`  upToDate:    ${data.upToDate ?? "?"}`);
  console.log(`  missing:     ${(data.missing ?? []).length}`, data.missing ?? []);
  console.log(`  stale:       ${(data.stale ?? []).length}`, data.stale ?? []);
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
