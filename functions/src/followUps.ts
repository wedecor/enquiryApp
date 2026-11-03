import { logger } from "firebase-functions/v2";
import { onDocumentWritten } from "firebase-functions/v2/firestore";
import { onSchedule } from "firebase-functions/v2/scheduler";
import { getFirestore, FieldValue } from "firebase-admin/firestore";
import {
  DEFAULT_FOLLOW_UP_CONFIG,
  FollowUpConfig,
  FollowUpUpdate,
  ReminderStage,
  SYSTEM_FOLLOW_UPS,
  isFollowUpEligible,
  nextAutoDueAt,
  nextIstSlot,
  parseFollowUpConfig,
  planFollowUpOnWrite,
  reminderContent,
  reminderNotificationId,
  reminderRecipients,
  reminderStageDue,
  scheduleUpdate,
} from "./followUpsLogic";
import { IST_TIME_ZONE } from "./istTime";
import { rawStatusValuesFor } from "./statusVocabulary";

/**
 * Automatic follow-ups (Nov 2026). Logic: followUpsLogic.ts.
 * - onEnquiryWrittenFollowUp: schedules / cancels / adjusts the open follow-up
 *   whenever an enquiry is written (create, status change, completion, reassignment).
 * - followUpReminders (every 15 min, IST): sends the due reminder once and the overdue
 *   reminder once per follow-up, and runs a one-time backfill for legacy open enquiries.
 * Reminders are in-app + FCM only (via sendNotificationToUser). Never WhatsApp.
 */

const CONFIG_TTL_MS = 5 * 60 * 1000;
const QUERY_LIMIT = 500;
const BACKFILL_PAGE = 300;
const STATE_DOC = "followups_state";

let cachedConfig: { value: FollowUpConfig; at: number } | null = null;

export async function loadFollowUpConfig(db: FirebaseFirestore.Firestore, fresh = false): Promise<FollowUpConfig> {
  if (!fresh && cachedConfig && Date.now() - cachedConfig.at < CONFIG_TTL_MS) return cachedConfig.value;
  try {
    const snap = await db.collection("app_config").doc("notifications").get();
    const value = parseFollowUpConfig(snap.data());
    cachedConfig = { value, at: Date.now() };
    return value;
  } catch (error: any) {
    logger.warn("followUps: config read failed, using defaults", { error: error?.message });
    return DEFAULT_FOLLOW_UP_CONFIG;
  }
}

function historyDoc(entry: { oldValue: string; newValue: string }) {
  // Same shape as AuditService.recordChange (lib/core/services/audit_service.dart).
  return {
    field_changed: "followUp",
    old_value: entry.oldValue,
    new_value: entry.newValue,
    user_id: "system",
    user_email: SYSTEM_FOLLOW_UPS,
    timestamp: FieldValue.serverTimestamp(),
  };
}

function applyUpdate(
  tx: FirebaseFirestore.Transaction,
  ref: FirebaseFirestore.DocumentReference,
  update: FollowUpUpdate,
): void {
  tx.update(ref, update.fields);
  if (update.history) tx.set(ref.collection("history").doc(), historyDoc(update.history));
}

/** Trigger core, exported for tests. Returns what was written (null = nothing). */
export async function applyFollowUpOnWrite(
  db: FirebaseFirestore.Firestore,
  enquiryId: string,
  before: Record<string, unknown> | null,
  config: FollowUpConfig,
  now: Date = new Date(),
): Promise<FollowUpUpdate | null> {
  const ref = db.collection("enquiries").doc(enquiryId);
  return db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    if (!snap.exists) return null;
    const update = planFollowUpOnWrite(before, snap.data() ?? {}, config, now);
    if (update) applyUpdate(tx, ref, update);
    return update;
  });
}

export const onEnquiryWrittenFollowUp = onDocumentWritten("enquiries/{id}", async (event) => {
  const after = event.data?.after?.data();
  if (!after) return;
  const before = event.data?.before?.data() ?? null;
  const db = getFirestore();
  const config = await loadFollowUpConfig(db);
  // Cheap pre-check on the event payload; most writes need nothing.
  if (!planFollowUpOnWrite(before, after, config, new Date())) return;
  try {
    const update = await applyFollowUpOnWrite(db, event.params.id, before, config);
    if (update?.history) {
      logger.info("followUps: updated", { enquiryId: event.params.id, change: update.history.newValue });
    }
  } catch (error: any) {
    logger.error("followUps: trigger failed", { enquiryId: event.params.id, error: error?.message });
    throw error; // let Functions retry the event
  }
});

function isActiveUserData(data: FirebaseFirestore.DocumentData | undefined): boolean {
  return (data?.isActive ?? data?.active ?? true) !== false;
}

/**
 * One-time schedule for open enquiries written before follow-ups existed. Due times
 * start at the next due-hour slot, so nothing is "due" the moment it is backfilled.
 */
export async function backfillFollowUps(
  db: FirebaseFirestore.Firestore,
  config: FollowUpConfig,
  now: Date,
): Promise<number> {
  const stateRef = db.collection("app_config").doc(STATE_DOC);
  const state = await stateRef.get();
  if (state.get("backfilledAt")) return 0;

  const floor = nextIstSlot(now, config.dueHourIst);
  const rawValues = config.eligibleStatuses.flatMap(rawStatusValuesFor);
  let scheduled = 0;
  let last: FirebaseFirestore.QueryDocumentSnapshot | undefined;
  while (true) {
    let query = db.collection("enquiries").where("statusValue", "in", rawValues).orderBy("__name__").limit(BACKFILL_PAGE);
    if (last) query = query.startAfter(last);
    const page = await query.get();
    for (const doc of page.docs) {
      if (typeof doc.get("followUpSeq") === "number" || doc.get("followUpDueAt")) continue;
      const done = await db.runTransaction(async (tx) => {
        const fresh = await tx.get(doc.ref);
        const data = fresh.data() ?? {};
        if (typeof data.followUpSeq === "number" || data.followUpDueAt || !isFollowUpEligible(data, config)) return false;
        applyUpdate(tx, doc.ref, scheduleUpdate(data, nextAutoDueAt(data, config, now, floor), "scheduled"));
        return true;
      });
      if (done) scheduled += 1;
    }
    if (page.size < BACKFILL_PAGE) break;
    last = page.docs[page.docs.length - 1];
  }
  await stateRef.set({ backfilledAt: FieldValue.serverTimestamp(), backfilledCount: scheduled }, { merge: true });
  return scheduled;
}

export type ReminderRunStats = {
  backfilled: number;
  candidates: number;
  sent: number;
  summarised: number;
  skipped: number;
};

/** Scheduler core, exported for tests. Safe to run repeatedly (and concurrently). */
export async function runFollowUpReminders(
  db: FirebaseFirestore.Firestore,
  now: Date = new Date(),
  configOverride?: FollowUpConfig,
): Promise<ReminderRunStats> {
  const config = configOverride ?? (await loadFollowUpConfig(db, true));
  const stats: ReminderRunStats = { backfilled: 0, candidates: 0, sent: 0, summarised: 0, skipped: 0 };
  if (!config.enabled) return stats;

  stats.backfilled = await backfillFollowUps(db, config, now);

  const usersSnap = await db.collection("users").get();
  const activeIds = new Set(usersSnap.docs.filter((d) => isActiveUserData(d.data())).map((d) => d.id));
  const adminIds = usersSnap.docs
    .filter((d) => d.get("role") === "admin" && activeIds.has(d.id))
    .map((d) => d.id);

  const overdueCutoff = new Date(now.getTime() - config.overdueHours * 60 * 60 * 1000);
  const [dueSnap, overdueSnap] = await Promise.all([
    db.collection("enquiries")
      .where("followUpNotifiedStage", "==", null)
      .where("followUpDueAt", "<=", now)
      .orderBy("followUpDueAt", "asc")
      .limit(QUERY_LIMIT)
      .get(),
    db.collection("enquiries")
      .where("followUpNotifiedStage", "==", "due")
      .where("followUpDueAt", "<=", overdueCutoff)
      .orderBy("followUpDueAt", "asc")
      .limit(QUERY_LIMIT)
      .get(),
  ]);
  const refs = new Map<string, FirebaseFirestore.DocumentReference>();
  for (const d of [...dueSnap.docs, ...overdueSnap.docs]) refs.set(d.id, d.ref);
  stats.candidates = refs.size;

  const pushes = new Map<string, number>();
  const summaries = new Map<string, { stage: ReminderStage; names: string[] }[]>();

  for (const [enquiryId, ref] of refs) {
    const result = await db.runTransaction(async (tx) => {
      const snap = await tx.get(ref);
      const data = snap.data() ?? {};
      const stage = reminderStageDue(data, config, now);
      if (!snap.exists || !stage) return null;
      const recipients = reminderRecipients(data, activeIds, adminIds);
      const individual = recipients.filter((uid) => (pushes.get(uid) ?? 0) < config.maxPushesPerRecipient);
      const summarised = recipients.filter((uid) => !individual.includes(uid));
      const id = reminderNotificationId(enquiryId, data, stage);
      const notifRefs = individual.map((uid) => db.collection("users").doc(uid).collection("notifications").doc(id));
      const existing = notifRefs.length > 0 ? await tx.getAll(...notifRefs) : [];
      tx.update(ref, { followUpNotifiedStage: stage, followUpLastNotifiedAt: now });
      const content = reminderContent(enquiryId, data, stage);
      notifRefs.forEach((nref, i) => {
        if (existing[i]?.exists) return; // already delivered by an earlier (retried) run
        tx.create(nref, {
          ...content,
          enquiryId,
          read: false,
          createdBy: SYSTEM_FOLLOW_UPS,
          createdAt: FieldValue.serverTimestamp(),
        });
      });
      return { stage, individual, summarised, name: content.data.customerName };
    });
    if (!result) {
      stats.skipped += 1;
      continue;
    }
    for (const uid of result.individual) pushes.set(uid, (pushes.get(uid) ?? 0) + 1);
    stats.sent += result.individual.length;
    for (const uid of result.summarised) {
      const list = summaries.get(uid) ?? [];
      list.push({ stage: result.stage, names: [result.name] });
      summaries.set(uid, list);
      stats.summarised += 1;
    }
  }

  // One "N more" notification per recipient over the per-run push limit.
  const runKey = new Date(Math.floor(now.getTime() / (15 * 60 * 1000)) * 15 * 60 * 1000).toISOString().slice(0, 16);
  for (const [uid, items] of summaries) {
    const names = items.flatMap((i) => i.names);
    const overdue = items.filter((i) => i.stage === "overdue").length;
    const title = `${items.length} more follow-up${items.length === 1 ? "" : "s"} due`;
    const body = `${names.slice(0, 5).join(", ")}${names.length > 5 ? ` +${names.length - 5}` : ""}${overdue ? ` · ${overdue} overdue` : ""}`;
    try {
      await db.collection("users").doc(uid).collection("notifications").doc(`fusum_${runKey.replace(/[:]/g, "")}`).create({
        title,
        body: body.slice(0, 500),
        type: "follow_up_summary",
        data: { type: "follow_up_summary", count: String(items.length) },
        read: false,
        createdBy: SYSTEM_FOLLOW_UPS,
        createdAt: FieldValue.serverTimestamp(),
      });
    } catch (error: any) {
      if (error?.code !== 6) logger.warn("followUps: summary failed", { uid, error: error?.message });
    }
  }
  return stats;
}

export const followUpReminders = onSchedule(
  { schedule: "*/15 * * * *", timeZone: IST_TIME_ZONE, retryCount: 1, timeoutSeconds: 300 },
  async () => {
    const stats = await runFollowUpReminders(getFirestore());
    logger.info("Follow-up reminders run", stats);
  },
);
