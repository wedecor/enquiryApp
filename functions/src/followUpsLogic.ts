/**
 * Automatic follow-ups — pure logic (no Firebase I/O), shared by the enquiry
 * trigger, the reminder scheduler and auto-expire. Design and trade-offs:
 * docs/IMPLEMENTATION_PLAN_2026-11.md §3–4.
 *
 * State lives on the enquiry document:
 *   followUpDueAt          Timestamp | null   open follow-up due time (null = none open)
 *   followUpSeq            int                bumped on every schedule / reschedule / complete / cancel
 *   followUpReason         auto | callback | manual | past_event
 *   followUpNotifiedStage  null | due | overdue   reminder already sent for this seq
 *   followUpScheduledBy    uid | system:followups
 *   followUpNote           callback note (client)
 *   followUpLastCompletedAt / followUpLastCompletedBy
 *   pastEventReviewAt      set once by autoExpireEnquiries
 * Mirrors lib/features/enquiries/domain/follow_up.dart for the client view.
 */

import { eventFunctionsOf } from "./eventFunctions";
import { IST_OFFSET_MS, istDayStart } from "./istTime";
import { CanonicalStatus, canonicalStatus } from "./statusVocabulary";

export const SYSTEM_FOLLOW_UPS = "system:followups";
const DAY_MS = 24 * 60 * 60 * 1000;

export type FollowUpReason = "auto" | "callback" | "manual" | "past_event";
export type ReminderStage = "due" | "overdue";

export type FollowUpConfig = {
  enabled: boolean;
  /** Days between follow-ups (app_config/notifications.reminderDaysDefault). */
  cadenceDays: number;
  /** IST hour (0–23) at which automatic follow-ups fall due. */
  dueHourIst: number;
  /** Hours after the due time before the single overdue reminder. */
  overdueHours: number;
  eligibleStatuses: CanonicalStatus[];
  /** Individual pushes per recipient per run; the rest are summarised. */
  maxPushesPerRecipient: number;
};

/** Approved defaults (Nov 2026): every 3 days at 10:00 IST, overdue after 24 h. */
export const DEFAULT_FOLLOW_UP_CONFIG: FollowUpConfig = {
  enabled: true,
  cadenceDays: 3,
  dueHourIst: 10,
  overdueHours: 24,
  eligibleStatuses: ["new", "in_talks"],
  maxPushesPerRecipient: 5,
};

function intIn(raw: unknown, min: number, max: number, fallback: number): number {
  return typeof raw === "number" && Number.isInteger(raw) && raw >= min && raw <= max ? raw : fallback;
}

/** Reads app_config/notifications; out-of-range values fall back to the defaults. */
export function parseFollowUpConfig(data: Record<string, unknown> | undefined): FollowUpConfig {
  const d = data ?? {};
  const statuses = Array.isArray(d.followUpEligibleStatuses)
    ? d.followUpEligibleStatuses
        .map((s) => canonicalStatus(s))
        // Terminal statuses never get follow-ups, whatever the config says.
        .filter((s): s is CanonicalStatus => s === "new" || s === "in_talks" || s === "approved")
    : [];
  return {
    enabled: d.followUpsEnabled !== false,
    cadenceDays: intIn(d.reminderDaysDefault, 1, 30, DEFAULT_FOLLOW_UP_CONFIG.cadenceDays),
    dueHourIst: intIn(d.followUpDueHourIst, 0, 23, DEFAULT_FOLLOW_UP_CONFIG.dueHourIst),
    overdueHours: intIn(d.followUpOverdueHours, 1, 24 * 14, DEFAULT_FOLLOW_UP_CONFIG.overdueHours),
    eligibleStatuses: statuses.length > 0 ? Array.from(new Set(statuses)) : DEFAULT_FOLLOW_UP_CONFIG.eligibleStatuses,
    maxPushesPerRecipient: intIn(d.followUpMaxPushesPerRun, 1, 50, DEFAULT_FOLLOW_UP_CONFIG.maxPushesPerRecipient),
  };
}

export function toDate(raw: unknown): Date | null {
  if (raw instanceof Date) return Number.isNaN(raw.getTime()) ? null : raw;
  if (raw && typeof (raw as { toDate?: unknown }).toDate === "function") {
    return (raw as { toDate: () => Date }).toDate();
  }
  return null;
}

function str(raw: unknown): string | null {
  return typeof raw === "string" && raw.trim() ? raw.trim() : null;
}

/** [hour]:00 IST on the IST calendar day containing [date]. */
export function istSlot(date: Date, hour: number): Date {
  return new Date(istDayStart(date).getTime() + hour * 60 * 60 * 1000);
}

/** The first [hour]:00 IST slot at or after [now]. */
export function nextIstSlot(now: Date, hour: number): Date {
  const today = istSlot(now, hour);
  return today.getTime() >= now.getTime() ? today : new Date(today.getTime() + DAY_MS);
}

export function isFollowUpEligible(data: Record<string, unknown>, config: FollowUpConfig): boolean {
  if (data.mergedInto) return false;
  const status = canonicalStatus(data.statusValue);
  return status !== null && config.eligibleStatuses.includes(status);
}

/**
 * Earliest function whose IST day is today or later. Multi-function bookings
 * (Haldi → Wedding → Reception) follow up before the FIRST upcoming function,
 * not the top-level eventDate (which is the last one).
 */
export function earliestUpcomingFunctionDate(data: Record<string, unknown>, now: Date): Date | null {
  const today = istDayStart(now).getTime();
  const upcoming = eventFunctionsOf(data)
    .map((f) => f.date)
    .filter((d) => istDayStart(d).getTime() >= today)
    .sort((a, b) => a.getTime() - b.getTime());
  return upcoming[0] ?? null;
}

/** True when the enquiry has dated functions and every one is on a past IST day. */
export function allEventDaysPassed(data: Record<string, unknown>, now: Date): boolean {
  const functions = eventFunctionsOf(data);
  return functions.length > 0 && earliestUpcomingFunctionDate(data, now) === null;
}

export type AutoSchedule = { dueAt: Date; reason: FollowUpReason };

/**
 * Next automatic due time: [cadenceDays] after the last completion (or creation)
 * at the configured IST hour, but no later than that hour on the day before the
 * earliest upcoming function. Never before [floor] (default now). When every event
 * day has passed the enquiry needs review now (reason past_event).
 */
export function nextAutoDueAt(
  data: Record<string, unknown>,
  config: FollowUpConfig,
  now: Date,
  floor: Date = now,
): AutoSchedule {
  const completedAt = toDate(data.followUpLastCompletedAt);
  if (allEventDaysPassed(data, now)) {
    const lastEventDay = Math.max(...eventFunctionsOf(data).map((f) => istDayStart(f.date).getTime()));
    // Already followed up since the event passed: keep the normal cadence, don't re-flag now.
    if (completedAt && istDayStart(completedAt).getTime() > lastEventDay) {
      const due = istSlot(new Date(completedAt.getTime() + config.cadenceDays * DAY_MS), config.dueHourIst);
      return { dueAt: due.getTime() < floor.getTime() ? floor : due, reason: "past_event" };
    }
    return { dueAt: floor, reason: "past_event" };
  }
  const base = completedAt ?? toDate(data.createdAt) ?? now;
  let due = istSlot(new Date(base.getTime() + config.cadenceDays * DAY_MS), config.dueHourIst);
  const upcoming = earliestUpcomingFunctionDate(data, now);
  if (upcoming) {
    const dayBefore = istSlot(new Date(istDayStart(upcoming).getTime() - DAY_MS + 12 * 60 * 60 * 1000), config.dueHourIst);
    if (dayBefore.getTime() < due.getTime()) due = dayBefore;
  }
  if (due.getTime() < floor.getTime()) due = floor;
  return { dueAt: due, reason: "auto" };
}

export type HistoryEntry = { oldValue: string; newValue: string };

export type FollowUpUpdate = {
  /** Fields to merge into the enquiry (Date for timestamps, null clears). */
  fields: Record<string, unknown>;
  /** One enquiries/{id}/history entry (field_changed: followUp), if the change is auditable. */
  history: HistoryEntry | null;
};

function seqOf(data: Record<string, unknown>): number {
  return typeof data.followUpSeq === "number" && Number.isFinite(data.followUpSeq) ? data.followUpSeq : 0;
}

function describeDue(dueAt: Date | null, reason: string | null): string {
  if (!dueAt) return "none";
  const ist = new Date(dueAt.getTime() + IST_OFFSET_MS).toISOString().slice(0, 16).replace("T", " ");
  return `due ${ist} IST${reason ? ` (${reason})` : ""}`;
}

/** Fields + history for a system schedule (initial, next after completion, backfill). */
export function scheduleUpdate(
  data: Record<string, unknown>,
  schedule: AutoSchedule,
  action: "scheduled" | "rescheduled",
): FollowUpUpdate {
  const oldDue = toDate(data.followUpDueAt);
  return {
    fields: {
      followUpDueAt: schedule.dueAt,
      followUpSeq: seqOf(data) + 1,
      followUpReason: schedule.reason,
      followUpNotifiedStage: null,
      followUpScheduledBy: SYSTEM_FOLLOW_UPS,
      followUpNote: null,
    },
    history: {
      oldValue: describeDue(oldDue, str(data.followUpReason)),
      newValue: `${action}: ${describeDue(schedule.dueAt, schedule.reason)}`,
    },
  };
}

/**
 * What the enquiry trigger should change after a write, or null when the stored
 * follow-up state is already consistent (this is what stops the trigger looping
 * on its own writes).
 */
export function planFollowUpOnWrite(
  before: Record<string, unknown> | null,
  after: Record<string, unknown>,
  config: FollowUpConfig,
  now: Date,
): FollowUpUpdate | null {
  const dueAt = toDate(after.followUpDueAt);
  const fields: Record<string, unknown> = {};

  // Event moved back into the future → the past-event flag no longer applies.
  if (after.pastEventReviewAt && !allEventDaysPassed(after, now)) {
    fields.pastEventReviewAt = null;
  }

  if (!isFollowUpEligible(after, config)) {
    if (dueAt) {
      const status = canonicalStatus(after.statusValue) ?? "unknown";
      return {
        fields: {
          ...fields,
          followUpDueAt: null,
          followUpSeq: seqOf(after) + 1,
          followUpNotifiedStage: null,
          followUpScheduledBy: SYSTEM_FOLLOW_UPS,
        },
        history: {
          oldValue: describeDue(dueAt, str(after.followUpReason)),
          newValue: after.mergedInto ? "cancelled: merged as duplicate" : `cancelled: status ${status}`,
        },
      };
    }
    return Object.keys(fields).length > 0 ? { fields, history: null } : null;
  }

  if (!config.enabled) {
    return Object.keys(fields).length > 0 ? { fields, history: null } : null;
  }

  if (!dueAt) {
    // New enquiry, a just-completed follow-up, or a legacy doc: schedule the next one.
    const update = scheduleUpdate(after, nextAutoDueAt(after, config, now), "scheduled");
    return { fields: { ...fields, ...update.fields }, history: update.history };
  }

  // Reassigned after the reminder went out: the new assignee should hear about it too.
  const assigneeChanged = before !== null && (str(before.assignedTo) ?? null) !== (str(after.assignedTo) ?? null);
  if (assigneeChanged && after.followUpNotifiedStage) {
    fields.followUpNotifiedStage = null;
  }

  // An automatic follow-up that has not fired yet moves earlier if the event moved earlier.
  if (after.followUpReason === "auto" && !after.followUpNotifiedStage) {
    const next = nextAutoDueAt(after, config, now);
    if (next.dueAt.getTime() < dueAt.getTime()) {
      const update = scheduleUpdate(after, next, "rescheduled");
      return { fields: { ...fields, ...update.fields }, history: update.history };
    }
  }

  return Object.keys(fields).length > 0 ? { fields, history: null } : null;
}

/** Which reminder (if any) is owed now for the stored follow-up. */
export function reminderStageDue(
  data: Record<string, unknown>,
  config: FollowUpConfig,
  now: Date,
): ReminderStage | null {
  if (!config.enabled || !isFollowUpEligible(data, config)) return null;
  const dueAt = toDate(data.followUpDueAt);
  if (!dueAt || now.getTime() < dueAt.getTime()) return null;
  const overdue = now.getTime() >= dueAt.getTime() + config.overdueHours * 60 * 60 * 1000;
  const sent = data.followUpNotifiedStage;
  if (sent === "overdue") return null;
  if (sent === "due") return overdue ? "overdue" : null;
  // Nothing sent yet. If it is already overdue (e.g. the job was down), send one
  // overdue reminder rather than a due and an overdue back to back.
  return overdue ? "overdue" : "due";
}

/** Assignee when active; otherwise (unassigned / inactive assignee) every active admin. */
export function reminderRecipients(
  data: Record<string, unknown>,
  activeUserIds: ReadonlySet<string>,
  activeAdminIds: readonly string[],
): string[] {
  const assignee = str(data.assignedTo);
  if (assignee && activeUserIds.has(assignee)) return [assignee];
  return [...activeAdminIds];
}

export function reminderNotificationId(enquiryId: string, data: Record<string, unknown>, stage: ReminderStage): string {
  return `fu_${enquiryId}_${seqOf(data)}_${stage}`;
}

function eventTypeLabelOf(data: Record<string, unknown>): string {
  const label = str(data.eventTypeLabel);
  if (label) return label;
  const value = str(data.eventTypeValue) ?? str(data.eventType);
  return value ? value.replace(/_/g, " ").replace(/\b\w/g, (c) => c.toUpperCase()) : "Event";
}

function truncate(value: string, max: number): string {
  return value.length <= max ? value : `${value.slice(0, max - 1)}…`;
}

export function reminderContent(
  enquiryId: string,
  data: Record<string, unknown>,
  stage: ReminderStage,
): { title: string; body: string; type: string; data: Record<string, string> } {
  const customer = str(data.customerName) ?? "Customer";
  const reason = str(data.followUpReason);
  const title =
    reason === "past_event"
      ? stage === "overdue" ? "Past event still open — overdue" : "Event date passed — needs review"
      : stage === "overdue" ? "Follow-up overdue" : reason === "callback" ? "Callback due" : "Follow-up due";
  const parts = [customer, eventTypeLabelOf(data)];
  const note = str(data.followUpNote);
  if (note) parts.push(note);
  const type = stage === "overdue" ? "follow_up_overdue" : "follow_up_due";
  return {
    title,
    body: truncate(parts.join(" · "), 500),
    type,
    data: { type, enquiryId, customerName: customer, stage },
  };
}
