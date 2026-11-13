import { logger } from "firebase-functions/v2";
import { onSchedule } from "firebase-functions/v2/scheduler";
import { onCall, HttpsError } from "firebase-functions/v2/https";
import { onDocumentWritten } from "firebase-functions/v2/firestore";
import { getFirestore, FieldValue, Timestamp } from "firebase-admin/firestore";
import { occasionEventOf } from "./eventFunctions";
import { IST_TIME_ZONE, istDayStart } from "./istTime";
import { notificationExpireAt } from "./notificationTtl";
import { phoneOf, planOccasionStamps, stampFields } from "./occasionStamping";
import {
  ReminderPlan,
  ReminderSource,
  hasOccasionStamp,
  isActiveOpenEnquiry,
  isOccasionKind,
  isWishEligible,
  istDatePlusDays,
  monthDaysForTarget,
  reminderSummary,
  selectReminders,
} from "./reengagementLogic";
import { canonicalStatus } from "./statusVocabulary";
import { isActiveUserData, requireActiveAdmin } from "./auth";

/** Firestore allows 500 writes per batch; leave headroom like autoExpireEnquiries. */
const MAX_BATCH_WRITES = 450;
/** Wishes go out a week ahead (a wish 30 days early reads as a sales nudge). */
const DEFAULT_LEAD_DAYS = 7;
const MIN_LEAD_DAYS = 1;
const MAX_LEAD_DAYS = 90;
/**
 * Daily stamp catch-up: open enquiries become eligible when the event date passes
 * with no write. Bound the scan to eventDate in the last N days before today IST.
 */
export const STAMP_CATCHUP_DAYS = 14;

type ReengagementConfig = { leadDays: number; enabled: boolean };

function stringOrNull(raw: unknown): string | null {
  return typeof raw === "string" && raw.trim() ? raw.trim() : null;
}

function toDate(raw: unknown): Date | null {
  if (raw instanceof Date) return raw;
  if (raw && typeof (raw as { toDate?: unknown }).toDate === "function") {
    return (raw as { toDate: () => Date }).toDate();
  }
  return null;
}

function titleCase(value: string): string {
  return value
    .replace(/[_-]+/g, " ")
    .split(" ")
    .filter(Boolean)
    .map((w) => w[0].toUpperCase() + w.slice(1).toLowerCase())
    .join(" ");
}

function eventTypeLabelOf(data: FirebaseFirestore.DocumentData): string {
  const label = stringOrNull(data.eventTypeLabel);
  if (label) return label;
  const value = stringOrNull(data.eventTypeValue) ?? stringOrNull(data.eventType);
  return value ? titleCase(value) : "Event";
}

/** Wish-eligible under the past-event rule (see isWishEligible). Status is ignored. */
export function wishEligibleOf(
  data: FirebaseFirestore.DocumentData,
  now: Date = new Date()
): boolean {
  const event = occasionEventOf(data);
  return isWishEligible({
    eventDate: event.eventDate,
    now,
    merged: !!data.mergedInto || data.lostReason === "duplicate",
    lostReason: data.lostReason,
    occasionKind: data.occasionKind,
    eventTypeValue: event.eventTypeValue,
    eventTypeLabel: event.eventTypeLabel,
    remindersOn: data.occasionReminders !== false,
    phoneNormalized: phoneOf(data),
  });
}

/** @deprecated Use wishEligibleOf — kept for migration scripts importing the old name. */
export function lostEligibleOf(data: FirebaseFirestore.DocumentData, _status: string | null): boolean {
  return wishEligibleOf(data);
}

export function parseReengagementConfig(data: FirebaseFirestore.DocumentData | undefined): ReengagementConfig {
  const lead = Number(data?.leadDays);
  return {
    leadDays: Number.isInteger(lead) && lead >= MIN_LEAD_DAYS && lead <= MAX_LEAD_DAYS ? lead : DEFAULT_LEAD_DAYS,
    enabled: data?.enabled !== false,
  };
}

/**
 * Stamps `occasionKind` / `occasionDate` / `occasionMonthDay` when an enquiry
 * becomes wish-eligible (past occasion date under [isWishEligible]) or when the
 * event type/date changes on an already-stamped eligible enquiry.
 * autoExpireEnquiries stamps completed in its own write; open-past enquiries are
 * also stamped by the daily schedule (no write when only time passes).
 *
 * Loop-safe: stamp fields never change status or eventDate/type, so a stamp write
 * cannot re-enter the "needs stamp" path. Never overwrites occasionManual.
 */
export const onEnquiryCompletedStampOccasion = onDocumentWritten("enquiries/{enquiryId}", async (event) => {
  const after = event.data?.after?.data();
  if (!after) return;
  const before = event.data?.before?.data();
  if (!wishEligibleOf(after)) return;
  if (after.occasionManual === true) return;
  const stamped = hasOccasionStamp({
    occasionKind: after.occasionKind,
    occasionMonthDay: after.occasionMonthDay,
    occasionDate: toDate(after.occasionDate),
  });
  const beforeStatus = before ? canonicalStatus(before.statusValue) : null;
  const afterStatus = canonicalStatus(after.statusValue);
  const statusChanged = !before || beforeStatus !== afterStatus;
  // Event date / type corrected → re-stamp (stamp never changes those fields).
  const beforeEvent = before ? occasionEventOf(before) : null;
  const afterEvent = occasionEventOf(after);
  const eventChanged =
    !!before &&
    (toDate(before.eventDate)?.getTime() !== toDate(after.eventDate)?.getTime() ||
      before.eventTypeValue !== after.eventTypeValue ||
      beforeEvent?.eventDate?.getTime() !== afterEvent.eventDate?.getTime() ||
      beforeEvent?.eventTypeValue !== afterEvent.eventTypeValue);
  const newlyEligible =
    statusChanged ||
    eventChanged ||
    (!!before && !wishEligibleOf(before) && wishEligibleOf(after));
  if (!(newlyEligible && !stamped) && !(stamped && eventChanged)) return;

  const enquiryId = event.params.enquiryId;
  const db = getFirestore();
  try {
    const stamps = await planOccasionStamps(db, enquiryId, after);
    if (stamps.size === 0) return;
    const batch = db.batch();
    for (const [id, stamp] of stamps) {
      batch.update(db.collection("enquiries").doc(id), stampFields(stamp));
    }
    await batch.commit();
    logger.info("Occasion stamped", {
      enquiryId,
      kind: stamps.get(enquiryId)?.occasionKind,
      monthDay: stamps.get(enquiryId)?.occasionMonthDay,
      siblingsRestamped: stamps.size - (stamps.has(enquiryId) ? 1 : 0),
    });
  } catch (error: any) {
    logger.error("Occasion stamping failed", { enquiryId, error: error?.message });
  }
});

function toReminderSource(doc: FirebaseFirestore.QueryDocumentSnapshot): ReminderSource | null {
  const data = doc.data();
  const occasionDate = toDate(data.occasionDate);
  const monthDay = stringOrNull(data.occasionMonthDay);
  if (!isOccasionKind(data.occasionKind) || !occasionDate || !monthDay) return null;
  return {
    id: doc.id,
    phoneNormalized: phoneOf(data),
    customerName: stringOrNull(data.customerName) ?? "Customer",
    customerPhone: stringOrNull(data.customerPhone) ?? stringOrNull(data.whatsappNumber),
    status: canonicalStatus(data.statusValue),
    merged: !!data.mergedInto || data.lostReason === "duplicate",
    remindersOn: data.occasionReminders !== false,
    occasionKind: data.occasionKind,
    occasionMonthDay: monthDay,
    occasionDate,
    person: stringOrNull(data.occasionPerson),
    eventTypeValue: stringOrNull(data.eventTypeValue) ?? stringOrNull(data.eventType),
    eventTypeLabel: eventTypeLabelOf(data),
    eventDate: toDate(data.eventDate),
    assignedTo: stringOrNull(data.assignedTo),
    wishEligible: wishEligibleOf(data),
  };
}

/**
 * Daily at 09:00 IST: for every wish-eligible enquiry (past occasion date) whose
 * occasion falls within the next `leadDays` (default 7, `app_config/reengagement`), create one idempotent
 * `reminders/{phone}_{kind}_{year}` doc per customer and occasion kind, then send
 * ONE summary notification per recipient (assignee if active, else all active admins).
 */
export type ReengagementRunResult = { created: number; planned: number; enabled: boolean };

/**
 * Body of the daily run (also used by the admin "Check now" callable): creates the
 * missing reminders for occasions within the next `leadDays` and notifies recipients.
 * Idempotent — existing reminder docs are never touched.
 */
/**
 * Stamp unstamped wish-eligible enquiries whose top-level eventDate fell into the
 * past within [STAMP_CATCHUP_DAYS] (bounded). Covers open enquiries that become
 * eligible only because time passed. Skips occasionManual; idempotent.
 */
export async function stampNewlyEligibleEnquiries(
  db: FirebaseFirestore.Firestore,
  now: Date
): Promise<{ scanned: number; stamped: number; reads: number }> {
  const todayStart = istDayStart(now);
  const windowStart = new Date(todayStart.getTime() - STAMP_CATCHUP_DAYS * 24 * 60 * 60 * 1000);
  let scanned = 0;
  let stampedCount = 0;
  let reads = 0;
  let last: FirebaseFirestore.QueryDocumentSnapshot | undefined;

  for (;;) {
    let q: FirebaseFirestore.Query = db
      .collection("enquiries")
      .where("eventDate", ">=", Timestamp.fromDate(windowStart))
      .where("eventDate", "<", Timestamp.fromDate(todayStart))
      .orderBy("eventDate")
      .limit(200);
    if (last) q = q.startAfter(last);
    const snap = await q.get();
    reads += 1;
    if (snap.empty) break;
    last = snap.docs[snap.docs.length - 1];
    scanned += snap.size;

    let batch = db.batch();
    let pending = 0;
    const flush = async () => {
      if (pending === 0) return;
      await batch.commit();
      batch = db.batch();
      pending = 0;
    };

    for (const doc of snap.docs) {
      const data = doc.data();
      if (data.occasionManual === true) continue;
      if (
        hasOccasionStamp({
          occasionKind: data.occasionKind,
          occasionMonthDay: data.occasionMonthDay,
          occasionDate: toDate(data.occasionDate),
        })
      ) {
        continue;
      }
      if (!wishEligibleOf(data, now)) continue;
      try {
        const stamps = await planOccasionStamps(db, doc.id, data);
        // Sibling lookup is an extra read when the phone is known.
        if (phoneOf(data).length >= 7) reads += 1;
        if (stamps.size === 0) continue;
        for (const [id, stamp] of stamps) {
          if (pending + 1 > MAX_BATCH_WRITES) await flush();
          batch.update(db.collection("enquiries").doc(id), stampFields(stamp));
          pending += 1;
          stampedCount += 1;
        }
      } catch (error: any) {
        logger.warn("Daily occasion stamp failed", { enquiryId: doc.id, error: error?.message });
      }
    }
    await flush();
    if (snap.size < 200) break;
  }
  return { scanned, stamped: stampedCount, reads };
}

export async function scheduleReengagementsCore(now: Date): Promise<ReengagementRunResult> {
  const db = getFirestore();

  let config: ReengagementConfig;
  try {
    config = parseReengagementConfig((await db.collection("app_config").doc("reengagement").get()).data());
  } catch (error: any) {
    logger.warn("Re-engagement: could not load config, using defaults", { error: error?.message });
    config = parseReengagementConfig(undefined);
  }
  if (!config.enabled) {
    logger.info("Re-engagement: disabled in app_config/reengagement");
    return { created: 0, planned: 0, enabled: false };
  }

  try {
    const stampPass = await stampNewlyEligibleEnquiries(db, now);
    if (stampPass.scanned > 0 || stampPass.stamped > 0) {
      logger.info("Re-engagement: daily stamp pass", stampPass);
    }
  } catch (error: any) {
    logger.error("Re-engagement: daily stamp pass failed", { error: error?.message });
  }

  // Window: every day from today to `leadDays` ahead. Reminder ids are
  // idempotent, so each occasion is created once — normally on the day it
  // enters the window (leadDays ahead), but occasions that were missed (first
  // run after the backfill, a failed run, leadDays changed) are caught up too.
  const monthDaysByYear = new Map<number, Set<string>>();
  for (let offset = 0; offset <= config.leadDays; offset++) {
    const day = istDatePlusDays(now, offset);
    const set = monthDaysByYear.get(day.year) ?? new Set<string>();
    for (const md of monthDaysForTarget(day.year, day.month, day.day)) set.add(md);
    monthDaysByYear.set(day.year, set);
  }

  let scanned = 0;
  const plans: ReminderPlan[] = [];
  const skipped: Record<string, number> = {};
  const monthDays: string[] = [];
  for (const [year, set] of monthDaysByYear) {
    const values = Array.from(set);
    monthDays.push(...values);
    // `in` takes at most 30 values; single-field filter → automatic index.
    for (let i = 0; i < values.length; i += 30) {
      const snap = await db.collection("enquiries").where("occasionMonthDay", "in", values.slice(i, i + 30)).get();
      scanned += snap.size;
      const sources = snap.docs.map(toReminderSource).filter((s): s is ReminderSource => s !== null);
      if (sources.length === 0) continue;

      const phones = Array.from(new Set(sources.map((s) => s.phoneNormalized).filter((p) => p.length >= 7)));
      const optedOut = new Set<string>();
      if (phones.length > 0) {
        const prefSnaps = await db.getAll(...phones.map((p) => db.collection("customer_prefs").doc(p)));
        for (const s of prefSnaps) if (s.get("noReminders") === true) optedOut.add(s.id);
      }

      // Still talking: open status AND event date today/future. Open+past does not block.
      const activePhones = new Set<string>();
      for (let j = 0; j < phones.length; j += 30) {
        const openSnap = await db
          .collection("enquiries")
          .where("phoneNormalized", "in", phones.slice(j, j + 30))
          .get();
        for (const d of openSnap.docs) {
          const data = d.data();
          const st = canonicalStatus(data.statusValue);
          const eventDate = occasionEventOf(data).eventDate;
          if (isActiveOpenEnquiry(st, eventDate, now)) {
            const phone = phoneOf(data);
            if (phone) activePhones.add(phone);
          }
        }
      }

      const result = selectReminders(sources, year, optedOut, activePhones);
      for (const [k, v] of Object.entries(result.skipped)) skipped[k] = (skipped[k] ?? 0) + (v as number);
      for (const plan of result.plans) {
        if (!plans.some((p) => p.docId === plan.docId)) plans.push(plan);
      }
    }
  }
  if (plans.length === 0) {
    logger.info("Re-engagement: nothing due", { monthDays, scanned, skipped });
    return { created: 0, planned: 0, enabled: true };
  }

  // Idempotency: never overwrite an existing reminder (it may be sent/skipped).
  const existing = new Set<string>();
  for (let i = 0; i < plans.length; i += 100) {
    const chunk = plans.slice(i, i + 100);
    const snaps = await db.getAll(...chunk.map((p) => db.collection("reminders").doc(p.docId)));
    for (const s of snaps) if (s.exists) existing.add(s.id);
  }
  const fresh = plans.filter((p) => !existing.has(p.docId));
  if (fresh.length === 0) {
    logger.info("Re-engagement: all due reminders already exist", { planned: plans.length });
    return { created: 0, planned: plans.length, enabled: true };
  }

  const userActive = new Map<string, boolean>();
  const isActiveUid = async (uid: string): Promise<boolean> => {
    const cached = userActive.get(uid);
    if (cached !== undefined) return cached;
    const userSnap = await db.collection("users").doc(uid).get();
    const active = userSnap.exists && isActiveUserData(userSnap.data());
    userActive.set(uid, active);
    return active;
  };

  let activeAdminIds: string[] | null = null;
  const loadAdmins = async (): Promise<string[]> => {
    if (activeAdminIds !== null) return activeAdminIds;
    try {
      const admins = await db.collection("users").where("role", "==", "admin").get();
      activeAdminIds = admins.docs.filter((d) => isActiveUserData(d.data())).map((d) => d.id);
    } catch (error: any) {
      logger.error("Re-engagement: failed to load admins", { error: error?.message });
      activeAdminIds = [];
    }
    return activeAdminIds;
  };

  const byRecipient = new Map<string, ReminderPlan[]>();
  let batch = db.batch();
  let pendingWrites = 0;
  const commitIfFull = async (extra: number) => {
    if (pendingWrites > 0 && pendingWrites + extra > MAX_BATCH_WRITES) {
      await batch.commit();
      batch = db.batch();
      pendingWrites = 0;
    }
  };

  for (const plan of fresh) {
    const s = plan.source;
    const assignedTo = s.assignedTo && (await isActiveUid(s.assignedTo)) ? s.assignedTo : null;
    await commitIfFull(1);
    batch.set(db.collection("reminders").doc(plan.docId), {
      enquiryId: s.id,
      phoneNormalized: s.phoneNormalized,
      customerName: s.customerName,
      customerPhone: s.customerPhone,
      occasionKind: s.occasionKind,
      occasionDate: Timestamp.fromDate(plan.occasionDate),
      nth: plan.nth,
      person: s.person,
      eventTypeLabel: s.eventTypeLabel,
      assignedTo,
      // Picks the message version and the PAST CUSTOMER / ENQUIRED marker in the app.
      pastCustomer: s.status === "completed",
      status: "pending",
      createdAt: FieldValue.serverTimestamp(),
    });
    pendingWrites += 1;

    const recipients = assignedTo ? [assignedTo] : await loadAdmins();
    for (const uid of recipients) {
      const list = byRecipient.get(uid) ?? [];
      list.push(plan);
      byRecipient.set(uid, list);
    }
  }

  // One summary per recipient — same doc shape as autoExpireEnquiries /
  // NotificationService; sendNotificationToUser turns it into a push.
  for (const [uid, list] of byRecipient) {
    const { title, body } = reminderSummary(list, config.leadDays);
    await commitIfFull(1);
    batch.set(db.collection("users").doc(uid).collection("notifications").doc(), {
      title,
      body,
      type: "reengagement",
      enquiryId: list.length === 1 ? list[0].source.id : null,
      data: {
        type: "reengagement",
        count: list.length,
      },
      read: false,
      createdAt: FieldValue.serverTimestamp(),
      expireAt: notificationExpireAt(now),
    });
    pendingWrites += 1;
  }

  if (pendingWrites > 0) await batch.commit();

  logger.info("Re-engagement reminders scheduled", {
    monthDays,
    leadDays: config.leadDays,
    scanned,
    planned: plans.length,
    created: fresh.length,
    alreadyExisted: plans.length - fresh.length,
    notifications: byRecipient.size,
    skipped,
  });
  return { created: fresh.length, planned: plans.length, enabled: true };
}

export const scheduleReengagements = onSchedule(
  {
    schedule: "0 9 * * *",
    timeZone: IST_TIME_ZONE,
    retryCount: 0,
  },
  async () => {
    await scheduleReengagementsCore(new Date());
  }
);

/**
 * Admin "Check now": runs the same job as the 09:00 IST scheduler immediately.
 * Returns `{created, planned}` (planned = reminders due in the window, created =
 * the ones that did not exist yet).
 */
export const runReengagementNow = onCall<unknown, Promise<ReengagementRunResult>>(
  {
    cors: true,
    region: "asia-south1",
    enforceAppCheck: false,
    timeoutSeconds: 300,
  },
  async (request) => {
    const { uid: caller } = await requireActiveAdmin(getFirestore(), request.auth?.uid, {
      deniedMessage: "Only active admins can run reminders",
    });
    try {
      const result = await scheduleReengagementsCore(new Date());
      logger.info("Re-engagement: manual run", { caller, ...result });
      return result;
    } catch (error: any) {
      logger.error("Re-engagement: manual run failed", { error: error?.message });
      throw new HttpsError("internal", "Could not check reminders. Try again later.");
    }
  }
);
