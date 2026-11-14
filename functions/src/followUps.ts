import { logger } from "firebase-functions/v2";
import { onDocumentWritten } from "firebase-functions/v2/firestore";
import { onSchedule } from "firebase-functions/v2/scheduler";
import { getFirestore, FieldValue, Timestamp } from "firebase-admin/firestore";
import { notificationExpireAt } from "./notificationTtl";
import { isActiveUserData } from "./auth";
import {
  DEFAULT_FOLLOW_UP_CONFIG,
  FOLLOW_UP_EVENT_QUERY_DAYS,
  FOLLOW_UP_LEAD_DAYS,
  FollowUpConfig,
  FollowUpUpdate,
  SYSTEM_FOLLOW_UPS,
  earliestUpcomingFunctionDate,
  isFollowUpEligible,
  isTenDayFollowUpMatch,
  nextAutoDueAt,
  nextIstSlot,
  parseFollowUpConfig,
  planFollowUpOnWrite,
  reminderRecipients,
  scheduleUpdate,
  tenDayNotificationContent,
  tenDayNotificationId,
} from "./followUpsLogic";
import { IST_TIME_ZONE, istDayStart } from "./istTime";
import { rawStatusValuesFor } from "./statusVocabulary";

/**
 * Follow-ups (Nov 2026).
 * - Old scheduled due/overdue pipeline: opt-in via app_config/notifications.followUpsEnabled === true
 *   (default OFF). When off, onEnquiryWrittenFollowUp schedules nothing and backfill is skipped.
 * - Daily job `followUpReminders` at 10:00 IST: In Talks enquiries whose first upcoming
 *   function is exactly FOLLOW_UP_LEAD_DAYS after today → one in-app notification.
 */

const CONFIG_TTL_MS = 5 * 60 * 1000;
const QUERY_LIMIT = 500;
const BACKFILL_PAGE = 300;
const STATE_DOC = "followups_state";
const MAX_INDIVIDUAL = 5;

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
    throw error;
  }
});

/**
 * One-time schedule for open enquiries written before follow-ups existed.
 * Only runs when the old scheduled pipeline is explicitly enabled.
 */
export async function backfillFollowUps(
  db: FirebaseFirestore.Firestore,
  config: FollowUpConfig,
  now: Date,
): Promise<number> {
  if (!config.enabled) return 0;
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
  candidates: number;
  matched: number;
  sent: number;
  summarised: number;
  skipped: number;
};

/**
 * Daily 10:00 IST job: notify for In Talks enquiries whose first upcoming function
 * is exactly FOLLOW_UP_LEAD_DAYS after today. Idempotent via fu10_* notification ids.
 */
export async function runFollowUpReminders(
  db: FirebaseFirestore.Firestore,
  now: Date = new Date(),
  _configOverride?: FollowUpConfig,
): Promise<ReminderRunStats> {
  const stats: ReminderRunStats = { candidates: 0, matched: 0, sent: 0, summarised: 0, skipped: 0 };

  const usersSnap = await db.collection("users").get();
  const activeIds = new Set(usersSnap.docs.filter((d) => isActiveUserData(d.data())).map((d) => d.id));
  const adminIds = usersSnap.docs
    .filter((d) => d.get("role") === "admin" && activeIds.has(d.id))
    .map((d) => d.id);

  const todayStart = istDayStart(now);
  const windowEnd = new Date(todayStart.getTime() + FOLLOW_UP_EVENT_QUERY_DAYS * 24 * 60 * 60 * 1000);
  const rawValues = rawStatusValuesFor("in_talks");

  const matches: { id: string; data: Record<string, unknown>; eventDate: Date }[] = [];
  let last: FirebaseFirestore.QueryDocumentSnapshot | undefined;
  while (true) {
    let query = db
      .collection("enquiries")
      .where("statusValue", "in", rawValues)
      .where("eventDate", ">=", Timestamp.fromDate(todayStart))
      .where("eventDate", "<=", Timestamp.fromDate(windowEnd))
      .orderBy("eventDate", "asc")
      .limit(QUERY_LIMIT);
    if (last) query = query.startAfter(last);
    const page = await query.get();
    stats.candidates += page.size;
    for (const doc of page.docs) {
      const data = doc.data() as Record<string, unknown>;
      if (!isTenDayFollowUpMatch(data, now)) continue;
      const eventDate = earliestUpcomingFunctionDate(data, now);
      if (!eventDate) continue;
      matches.push({ id: doc.id, data, eventDate });
    }
    if (page.size < QUERY_LIMIT) break;
    last = page.docs[page.docs.length - 1];
  }
  stats.matched = matches.length;

  const byRecipient = new Map<string, typeof matches>();
  for (const m of matches) {
    for (const uid of reminderRecipients(m.data, activeIds, adminIds)) {
      const list = byRecipient.get(uid) ?? [];
      list.push(m);
      byRecipient.set(uid, list);
    }
  }

  for (const [uid, list] of byRecipient) {
    const individual = list.slice(0, MAX_INDIVIDUAL);
    const overflow = list.length - individual.length;
    for (const m of individual) {
      const id = tenDayNotificationId(m.id, now);
      const content = tenDayNotificationContent(m.id, m.data, m.eventDate);
      try {
        await db.collection("users").doc(uid).collection("notifications").doc(id).create({
          title: content.title,
          body: content.body,
          type: content.type,
          data: content.data,
          enquiryId: m.id,
          read: false,
          createdBy: SYSTEM_FOLLOW_UPS,
          createdAt: FieldValue.serverTimestamp(),
          expireAt: notificationExpireAt(now),
        });
        stats.sent += 1;
      } catch (error: any) {
        if (error?.code === 6) {
          stats.skipped += 1; // already exists
        } else {
          logger.warn("followUps: ten-day notify failed", { uid, enquiryId: m.id, error: error?.message });
          stats.skipped += 1;
        }
      }
    }
    if (overflow > 0) {
      const sumId = `fu10sum_${tenDayNotificationId("x", now).slice(5)}_${uid.slice(0, 8)}`;
      try {
        await db.collection("users").doc(uid).collection("notifications").doc(sumId).create({
          title: `${overflow} more events in 10 days`,
          body: `${overflow} more In Talks events are ${FOLLOW_UP_LEAD_DAYS} days away`,
          type: "follow_up_due",
          data: { type: "follow_up_due", count: String(overflow) },
          read: false,
          createdBy: SYSTEM_FOLLOW_UPS,
          createdAt: FieldValue.serverTimestamp(),
          expireAt: notificationExpireAt(now),
        });
        stats.summarised += 1;
      } catch (error: any) {
        if (error?.code !== 6) {
          logger.warn("followUps: ten-day summary failed", { uid, error: error?.message });
        }
      }
    }
  }

  return stats;
}

/** Daily at 10:00 Asia/Kolkata — replaces the former every-15-minutes schedule. */
export const followUpReminders = onSchedule(
  { schedule: "0 10 * * *", timeZone: IST_TIME_ZONE, retryCount: 1, timeoutSeconds: 300 },
  async () => {
    const stats = await runFollowUpReminders(getFirestore());
    logger.info("Follow-up 10-day reminders run", stats);
  },
);
