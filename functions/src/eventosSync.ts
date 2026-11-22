/**
 * EventOS booking feed sender (M5-01 temporary bridge).
 *
 * Triggers on enquiry writes and financial/summary writes. Re-reads the current
 * enquiry + functions + financial before building the payload (never trusts the
 * trigger snapshot). Bookkeeping lives in enquiries/{id}/private/eventosSync so
 * we never re-trigger enquiry listeners.
 *
 * Off switch: leave EVENTOS_FEED_URL empty in functions/.env.
 * Secret: firebase functions:secrets:set EVENTOS_FEED_SECRET
 */

import { logger } from "firebase-functions/v2";
import { onDocumentWritten } from "firebase-functions/v2/firestore";
import { defineSecret } from "firebase-functions/params";
import { FieldValue, getFirestore } from "firebase-admin/firestore";
import {
  buildEventOSPayload,
  hashEventOSPayload,
  shouldSendToEventOS,
  type EventOSPayload,
  type EventosSyncBookkeeping,
} from "./eventosPayload";
import { signEventOSFeedBody } from "./eventosSign";
import { canonicalStatus } from "./statusVocabulary";

export const EVENTOS_FEED_SECRET = defineSecret("EVENTOS_FEED_SECRET");

const SYNC_TIMEOUT_MS = 10_000;
const MAX_EVENT_AGE_MS = 24 * 60 * 60 * 1000;

export type SyncDeps = {
  db: FirebaseFirestore.Firestore;
  feedUrl: string;
  secret: string;
  deliveryId: string;
  eventTimeMs: number;
  fetchImpl?: typeof fetch;
  nowMs?: number;
};

export type SyncResult =
  | { action: "disabled" }
  | { action: "skipped"; reason: string }
  | { action: "dropped"; reason: string }
  | { action: "sent"; httpStatus: number; eventosEventId?: string }
  | { action: "rejected"; httpStatus: number; body: string };

function feedUrlFromEnv(): string {
  return (process.env.EVENTOS_FEED_URL ?? "").trim();
}

function privateSyncRef(db: FirebaseFirestore.Firestore, enquiryId: string) {
  return db.collection("enquiries").doc(enquiryId).collection("private").doc("eventosSync");
}

async function readSyncBookkeeping(
  db: FirebaseFirestore.Firestore,
  enquiryId: string,
): Promise<EventosSyncBookkeeping | null> {
  const snap = await privateSyncRef(db, enquiryId).get();
  if (!snap.exists) return null;
  return (snap.data() ?? {}) as EventosSyncBookkeeping;
}

async function writeSyncBookkeeping(
  db: FirebaseFirestore.Firestore,
  enquiryId: string,
  data: Record<string, unknown>,
): Promise<void> {
  await privateSyncRef(db, enquiryId).set(
    { ...data, updatedAt: FieldValue.serverTimestamp() },
    { merge: true },
  );
}

/**
 * Re-reads enquiry + financial, decides whether to send, POSTs the signed
 * payload, and updates private bookkeeping. Throws on 5xx / network so CF retries.
 */
export async function syncEnquiryToEventOS(
  enquiryId: string,
  deps: SyncDeps,
): Promise<SyncResult> {
  const nowMs = deps.nowMs ?? Date.now();
  if (!deps.feedUrl) {
    logger.info("eventos_sync_disabled", { enquiryId, reason: "EVENTOS_FEED_URL empty" });
    return { action: "disabled" };
  }

  if (nowMs - deps.eventTimeMs > MAX_EVENT_AGE_MS) {
    logger.error("eventos_sync_dropped_stale_event", {
      enquiryId,
      eventAgeMs: nowMs - deps.eventTimeMs,
    });
    return { action: "dropped", reason: "event_older_than_24h" };
  }

  const enquiryRef = deps.db.collection("enquiries").doc(enquiryId);
  const enquirySnap = await enquiryRef.get();
  if (!enquirySnap.exists) {
    return { action: "skipped", reason: "enquiry_missing" };
  }
  const enquiry = (enquirySnap.data() ?? {}) as Record<string, unknown>;

  const financialSnap = await enquiryRef.collection("financial").doc("summary").get();
  const financial = financialSnap.exists
    ? ((financialSnap.data() ?? {}) as Record<string, unknown>)
    : null;

  const payload = buildEventOSPayload(enquiryId, enquiry, financial);
  const nextHash = hashEventOSPayload(payload);
  const bookkeeping = await readSyncBookkeeping(deps.db, enquiryId);
  const previouslySynced = !!bookkeeping?.syncedAt;
  const status = canonicalStatus(payload.status) ?? payload.status;

  if (
    !shouldSendToEventOS({
      status,
      previouslySynced,
      lastHash: bookkeeping?.lastHash,
      nextHash,
    })
  ) {
    logger.info("eventos_sync_skipped", {
      enquiryId,
      reason: previouslySynced && bookkeeping?.lastHash === nextHash ? "unchanged_hash" : "not_eligible",
      status,
    });
    return {
      action: "skipped",
      reason:
        previouslySynced && bookkeeping?.lastHash === nextHash ? "unchanged_hash" : "not_eligible",
    };
  }

  const rawBody = JSON.stringify(payload);
  const timestamp = Math.floor(nowMs / 1000).toString();
  const signature = signEventOSFeedBody(deps.secret, timestamp, rawBody);
  const fetchImpl = deps.fetchImpl ?? fetch;

  let response: Response;
  try {
    const controller = new AbortController();
    const timer = setTimeout(() => controller.abort(), SYNC_TIMEOUT_MS);
    try {
      response = await fetchImpl(deps.feedUrl, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-EventOS-Timestamp": timestamp,
          "X-EventOS-Signature": signature,
          "X-EventOS-Delivery-Id": deps.deliveryId,
        },
        body: rawBody,
        signal: controller.signal,
      });
    } finally {
      clearTimeout(timer);
    }
  } catch (err) {
    logger.error("eventos_sync_network_error", {
      enquiryId,
      deliveryId: deps.deliveryId,
      error: err instanceof Error ? err.message : "network",
    });
    throw err;
  }

  const responseText = await response.text().catch(() => "");
  let eventosEventId: string | undefined;
  try {
    const json = JSON.parse(responseText) as { eventId?: string };
    if (typeof json.eventId === "string") eventosEventId = json.eventId;
  } catch {
    /* ignore non-JSON */
  }

  if (response.status >= 500) {
    logger.error("eventos_sync_server_error", {
      enquiryId,
      deliveryId: deps.deliveryId,
      httpStatus: response.status,
    });
    throw new Error(`EventOS feed returned ${response.status}`);
  }

  if (response.status >= 400) {
    logger.error("eventos_sync_rejected", {
      enquiryId,
      deliveryId: deps.deliveryId,
      httpStatus: response.status,
    });
    await writeSyncBookkeeping(deps.db, enquiryId, {
      lastHash: nextHash,
      lastStatus: payload.status,
      lastHttpStatus: response.status,
      lastError: `http_${response.status}`,
      eventosEventId: eventosEventId ?? null,
    });
    return { action: "rejected", httpStatus: response.status, body: responseText.slice(0, 200) };
  }

  await writeSyncBookkeeping(deps.db, enquiryId, {
    syncedAt: FieldValue.serverTimestamp(),
    lastHash: nextHash,
    lastStatus: payload.status,
    lastHttpStatus: response.status,
    lastError: null,
    eventosEventId: eventosEventId ?? null,
  });

  logger.info("eventos_sync_sent", {
    enquiryId,
    deliveryId: deps.deliveryId,
    httpStatus: response.status,
    status: payload.status,
  });
  return { action: "sent", httpStatus: response.status, eventosEventId };
}

async function runSyncFromTrigger(
  enquiryId: string,
  deliveryId: string,
  eventTimeMs: number,
  secret: string,
): Promise<void> {
  const url = feedUrlFromEnv();
  if (!url) {
    // Log once per invocation is fine; empty URL is the intentional off switch.
    logger.info("eventos_sync_disabled", { enquiryId });
    return;
  }
  await syncEnquiryToEventOS(enquiryId, {
    db: getFirestore(),
    feedUrl: url,
    secret,
    deliveryId,
    eventTimeMs,
  });
}

export const onEnquiryWrittenSyncEventOS = onDocumentWritten(
  {
    document: "enquiries/{id}",
    region: "asia-south1",
    retry: true,
    secrets: [EVENTOS_FEED_SECRET],
    timeoutSeconds: 30,
    memory: "256MiB",
  },
  async (event) => {
    const enquiryId = event.params.id;
    // Deletes: nothing to sync.
    if (!event.data?.after.exists) return;
    const eventTimeMs = event.time ? Date.parse(event.time) : Date.now();
    await runSyncFromTrigger(
      enquiryId,
      event.id,
      Number.isFinite(eventTimeMs) ? eventTimeMs : Date.now(),
      EVENTOS_FEED_SECRET.value(),
    );
  },
);

export const onEnquiryFinancialWrittenSyncEventOS = onDocumentWritten(
  {
    document: "enquiries/{id}/financial/summary",
    region: "asia-south1",
    retry: true,
    secrets: [EVENTOS_FEED_SECRET],
    timeoutSeconds: 30,
    memory: "256MiB",
  },
  async (event) => {
    const enquiryId = event.params.id;
    const eventTimeMs = event.time ? Date.parse(event.time) : Date.now();
    await runSyncFromTrigger(
      enquiryId,
      event.id,
      Number.isFinite(eventTimeMs) ? eventTimeMs : Date.now(),
      EVENTOS_FEED_SECRET.value(),
    );
  },
);

/** Exported for tests that need a sample payload without Firestore. */
export type { EventOSPayload };
