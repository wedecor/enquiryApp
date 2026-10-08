/**
 * Pure logic for yearly re-engagement reminders ("same time next year").
 *
 * No Firebase imports: reused by functions/src/reengagement.ts,
 * functions/src/autoExpireEnquiries.ts and the backfill migration
 * scripts/migrations/2026_10_backfill_occasions.ts.
 *
 * The keyword table and matching rule MUST stay identical to
 * lib/features/reengagement/domain/occasion_kind.dart.
 */

import { IST_OFFSET_MS } from "./istTime";

export type OccasionKind =
  | "wedding_anniversary"
  | "birthday"
  | "anniversary"
  | "baby"
  | "home"
  | "corporate"
  | "celebration";

export const OCCASION_KINDS: readonly OccasionKind[] = [
  "wedding_anniversary",
  "birthday",
  "anniversary",
  "baby",
  "home",
  "corporate",
  "celebration",
];

/**
 * Checked in order against the event type value + label, lower-cased with every
 * non-alphanumeric character removed ("Bride-to-be" → "bridetobe",
 * "Griha Pravesh" → "grihapravesh"). First match wins; no match → `celebration`.
 *
 * `corporate` is checked first so "Corporate cocktail" / "Office birthday" are
 * corporate events, not weddings or birthdays.
 */
export const OCCASION_KIND_KEYWORDS: ReadonlyArray<readonly [OccasionKind, readonly string[]]> = [
  ["corporate", ["corporate", "office", "launch", "conference"]],
  [
    "wedding_anniversary",
    [
      "wedding",
      "marriage",
      "reception",
      "haldi",
      "mehendi",
      "mehndi",
      "mehandi",
      "sangeet",
      "engagement",
      "bride",
      "bridal",
      "groom",
      "bachelor",
      "nikah",
      "nikkah",
      "walima",
      "roka",
      "cocktail",
      "muhurtham",
      "muhurtam",
      "muhurat",
      "shaadi",
    ],
  ],
  ["birthday", ["birthday", "bday"]],
  ["anniversary", ["anniversary"]],
  [
    "baby",
    [
      "babyshower",
      "godhbharai",
      "godbharai",
      "seemantham",
      "seemantam",
      "valaikappu",
      "naming",
      "namkaran",
      "namakaran",
      "cradle",
    ],
  ],
  ["home", ["housewarming", "grihapravesh", "grihapravesam", "gruhapravesh", "gruhapravesam"]],
];

/** Wedding-family event types that ARE the wedding (anchor for the anniversary date). */
const WEDDING_ANCHOR_KEYWORDS: readonly string[] = [
  "wedding",
  "marriage",
  "nikah",
  "nikkah",
  "shaadi",
  "muhurtham",
  "muhurtam",
];

/** Same-customer wedding-family events this close are one wedding (haldi … reception). */
export const WEDDING_GROUP_WINDOW_DAYS = 10;

const DAY_MS = 24 * 60 * 60 * 1000;

/** Lower-cased value + label with every non-alphanumeric character removed. */
export function compactEventTypeText(value: unknown, label?: unknown): string {
  const parts = [value, label].filter((p): p is string => typeof p === "string");
  return parts.join(" ").toLowerCase().replace(/[^a-z0-9]+/g, "");
}

/** Occasion kind for an event type. Every event gets one (fallback `celebration`). */
export function occasionKindFor(value: unknown, label?: unknown): OccasionKind {
  const text = compactEventTypeText(value, label);
  if (!text) return "celebration";
  for (const [kind, keywords] of OCCASION_KIND_KEYWORDS) {
    if (keywords.some((k) => text.includes(k))) return kind;
  }
  return "celebration";
}

export function isOccasionKind(raw: unknown): raw is OccasionKind {
  return typeof raw === "string" && (OCCASION_KINDS as readonly string[]).includes(raw);
}

/** True for the wedding itself (not haldi / pre-wedding shoot / reception…). */
export function isWeddingAnchor(value: unknown, label?: unknown): boolean {
  const text = compactEventTypeText(value, label).replace(/prewedding/g, "");
  return WEDDING_ANCHOR_KEYWORDS.some((k) => text.includes(k));
}

function pad2(n: number): string {
  return n < 10 ? `0${n}` : `${n}`;
}

/** IST calendar `MM-DD` and year of an instant (eventDate is stored at 00:00 IST). */
export function istMonthDayYear(date: Date): { monthDay: string; year: number } {
  const ist = new Date(date.getTime() + IST_OFFSET_MS);
  return {
    monthDay: `${pad2(ist.getUTCMonth() + 1)}-${pad2(ist.getUTCDate())}`,
    year: ist.getUTCFullYear(),
  };
}

export function isLeapYear(year: number): boolean {
  return (year % 4 === 0 && year % 100 !== 0) || year % 400 === 0;
}

/** IST calendar date (y, m 1-12, d) of [now] plus [days] calendar days. */
export function istDatePlusDays(now: Date, days: number): { year: number; month: number; day: number } {
  const ist = new Date(now.getTime() + IST_OFFSET_MS);
  const shifted = new Date(Date.UTC(ist.getUTCFullYear(), ist.getUTCMonth(), ist.getUTCDate() + days));
  return { year: shifted.getUTCFullYear(), month: shifted.getUTCMonth() + 1, day: shifted.getUTCDate() };
}

/**
 * `occasionMonthDay` values to look up for a target date. Feb 29 occasions are
 * reminded on Feb 28 in non-leap years.
 */
export function monthDaysForTarget(year: number, month: number, day: number): string[] {
  const md = `${pad2(month)}-${pad2(day)}`;
  if (month === 2 && day === 28 && !isLeapYear(year)) return [md, "02-29"];
  return [md];
}

/** 00:00 IST of `MM-DD` in [year] (Feb 29 → Feb 28 in non-leap years), or null if invalid. */
export function occasionDateIn(monthDay: string, year: number): Date | null {
  const match = /^(\d{2})-(\d{2})$/.exec(monthDay);
  if (!match) return null;
  const month = Number(match[1]);
  let day = Number(match[2]);
  if (month < 1 || month > 12 || day < 1 || day > 31) return null;
  if (month === 2 && day === 29 && !isLeapYear(year)) day = 28;
  const utc = Date.UTC(year, month - 1, day);
  if (new Date(utc).getUTCMonth() !== month - 1) return null;
  return new Date(utc - IST_OFFSET_MS);
}

/** 1 → 1st, 2 → 2nd, 3 → 3rd, 11 → 11th, 21 → 21st. */
export function ordinal(n: number): string {
  const mod100 = n % 100;
  if (mod100 >= 11 && mod100 <= 13) return `${n}th`;
  switch (n % 10) {
    case 1:
      return `${n}st`;
    case 2:
      return `${n}nd`;
    case 3:
      return `${n}rd`;
    default:
      return `${n}th`;
  }
}

/** "2nd wedding anniversary", "Aarav's birthday", "1 year since Baby Shower". Mirrors Dart. */
export function occasionLabel(kind: OccasionKind, nth: number, person: string | null, eventTypeLabel: string): string {
  const n = nth < 1 ? 1 : nth;
  const who = person && person.trim() ? person.trim() : null;
  const years = `${n} year${n === 1 ? "" : "s"}`;
  switch (kind) {
    case "wedding_anniversary":
      return `${ordinal(n)} wedding anniversary`;
    case "birthday":
      return who ? `${who}'s birthday` : "Birthday";
    case "anniversary":
      return who ? `${who}'s anniversary` : "Anniversary";
    case "home":
      return `${ordinal(n)} housewarming anniversary`;
    case "baby":
    case "corporate":
    case "celebration":
      return `${years} since ${eventTypeLabel || "the event"}`;
  }
}

// ── Occasion stamping ────────────────────────────────────────────────────────

/** What the stamping logic needs to know about one enquiry. */
export type StampSource = {
  id: string;
  eventTypeValue: string | null;
  eventTypeLabel: string | null;
  eventDate: Date | null;
  /** Fallback date when eventDate is missing (completedAt / now). */
  fallbackDate: Date;
  /** Canonical status. */
  status: string | null;
  merged: boolean;
  /** Admin edited the date/kind by hand: never re-stamped. */
  manual: boolean;
  /** Existing stamp, if any. */
  occasionKind: unknown;
  occasionMonthDay: unknown;
  occasionDate: Date | null;
};

export type OccasionStamp = {
  occasionKind: OccasionKind;
  occasionDate: Date;
  occasionMonthDay: string;
};

const LOST_STATUSES = new Set(["not_interested", "closed_lost", "cancelled"]);

export function hasOccasionStamp(s: Pick<StampSource, "occasionKind" | "occasionMonthDay" | "occasionDate">): boolean {
  return isOccasionKind(s.occasionKind) && typeof s.occasionMonthDay === "string" && !!s.occasionDate;
}

function stampFor(kind: OccasionKind, date: Date): OccasionStamp {
  return { occasionKind: kind, occasionDate: date, occasionMonthDay: istMonthDayYear(date).monthDay };
}

/**
 * Stamps for [target] (which just became completed) and — for weddings — the
 * same customer's other completed wedding-family enquiries within ±10 days.
 *
 * [siblings] = the customer's other enquiries (same phoneNormalized), any status.
 * Anchor date: the latest wedding-typed event of the group (approved ones count,
 * so a haldi completed before the wedding already gets the wedding date), else the
 * latest date of the group. Only completed, non-merged, non-manual enquiries whose
 * stamp would change are returned. The target is always returned unless manual.
 */
export function computeOccasionStamps(target: StampSource, siblings: readonly StampSource[]): Map<string, OccasionStamp> {
  const result = new Map<string, OccasionStamp>();
  if (target.manual) return result;
  const kind = occasionKindFor(target.eventTypeValue, target.eventTypeLabel);
  const targetDate = target.eventDate ?? target.fallbackDate;

  if (kind !== "wedding_anniversary" || !target.eventDate) {
    result.set(target.id, stampFor(kind, targetDate));
    return result;
  }

  const windowMs = WEDDING_GROUP_WINDOW_DAYS * DAY_MS;
  const group: StampSource[] = [target];
  for (const s of siblings) {
    if (s.id === target.id || s.merged || !s.eventDate) continue;
    if (s.status && LOST_STATUSES.has(s.status)) continue;
    if (occasionKindFor(s.eventTypeValue, s.eventTypeLabel) !== "wedding_anniversary") continue;
    if (Math.abs(s.eventDate.getTime() - target.eventDate.getTime()) > windowMs) continue;
    group.push(s);
  }

  const anchorDate = pickAnchorDate(group);
  result.set(target.id, stampFor(kind, anchorDate));
  for (const s of group) {
    if (s.id === target.id || s.manual || s.status !== "completed") continue;
    const stamp = stampFor("wedding_anniversary", anchorDate);
    const same =
      s.occasionKind === stamp.occasionKind &&
      s.occasionMonthDay === stamp.occasionMonthDay &&
      !!s.occasionDate &&
      s.occasionDate.getTime() === anchorDate.getTime();
    if (!same) result.set(s.id, stamp);
  }
  return result;
}

/** Latest wedding-typed date of the group, else the latest date. */
export function pickAnchorDate(group: readonly Pick<StampSource, "eventDate" | "fallbackDate" | "eventTypeValue" | "eventTypeLabel">[]): Date {
  const dated = group.map((g) => ({ g, d: g.eventDate ?? g.fallbackDate }));
  const anchors = dated.filter((x) => isWeddingAnchor(x.g.eventTypeValue, x.g.eventTypeLabel));
  const pool = anchors.length > 0 ? anchors : dated;
  return pool.reduce((best, x) => (x.d.getTime() > best.d.getTime() ? x : best)).d;
}

// ── Daily reminder selection ─────────────────────────────────────────────────

/** A completed enquiry whose occasionMonthDay matched the target day. */
export type ReminderSource = {
  id: string;
  phoneNormalized: string;
  customerName: string;
  customerPhone: string | null;
  status: string | null;
  merged: boolean;
  /** `occasionReminders` (false = off for this enquiry). */
  remindersOn: boolean;
  occasionKind: OccasionKind;
  occasionMonthDay: string;
  occasionDate: Date;
  person: string | null;
  eventTypeValue: string | null;
  eventTypeLabel: string;
  eventDate: Date | null;
  assignedTo: string | null;
};

export type ReminderPlan = {
  docId: string;
  source: ReminderSource;
  /** This year's occasion date (00:00 IST). */
  occasionDate: Date;
  nth: number;
};

export const MIN_PHONE_DIGITS = 7;

export function reminderDocId(phoneNormalized: string, kind: OccasionKind, year: number): string {
  return `${phoneNormalized}_${kind}_${year}`;
}

export type SkipCounts = Record<"notCompleted" | "merged" | "remindersOff" | "sameYear" | "noPhone" | "optedOut" | "duplicate", number>;

/**
 * One reminder per (phone, kind, year) for the target year. Skips: not completed,
 * merged duplicates, `occasionReminders == false`, occasion in the target year or
 * later (not an anniversary yet), no usable phone, opted-out customers.
 * Within a (phone, kind) group the wedding itself wins, then a filled-in person,
 * then the latest event.
 */
export function selectReminders(
  sources: readonly ReminderSource[],
  targetYear: number,
  optedOutPhones: ReadonlySet<string>
): { plans: ReminderPlan[]; skipped: SkipCounts } {
  const skipped: SkipCounts = {
    notCompleted: 0,
    merged: 0,
    remindersOff: 0,
    sameYear: 0,
    noPhone: 0,
    optedOut: 0,
    duplicate: 0,
  };
  const groups = new Map<string, ReminderSource[]>();
  for (const s of sources) {
    if (s.status !== "completed") {
      skipped.notCompleted++;
      continue;
    }
    if (s.merged) {
      skipped.merged++;
      continue;
    }
    if (!s.remindersOn) {
      skipped.remindersOff++;
      continue;
    }
    if (istMonthDayYear(s.occasionDate).year >= targetYear) {
      skipped.sameYear++;
      continue;
    }
    if (s.phoneNormalized.length < MIN_PHONE_DIGITS) {
      skipped.noPhone++;
      continue;
    }
    if (optedOutPhones.has(s.phoneNormalized)) {
      skipped.optedOut++;
      continue;
    }
    const key = reminderDocId(s.phoneNormalized, s.occasionKind, targetYear);
    const list = groups.get(key) ?? [];
    list.push(s);
    groups.set(key, list);
  }

  const plans: ReminderPlan[] = [];
  for (const [docId, list] of groups) {
    skipped.duplicate += list.length - 1;
    const best = [...list].sort(compareReminderSources)[0];
    const occasionDate = occasionDateIn(best.occasionMonthDay, targetYear);
    if (!occasionDate) continue;
    plans.push({
      docId,
      source: best,
      occasionDate,
      nth: Math.max(1, targetYear - istMonthDayYear(best.occasionDate).year),
    });
  }
  plans.sort((a, b) => a.docId.localeCompare(b.docId));
  return { plans, skipped };
}

function compareReminderSources(a: ReminderSource, b: ReminderSource): number {
  const wa = isWeddingAnchor(a.eventTypeValue, a.eventTypeLabel) ? 0 : 1;
  const wb = isWeddingAnchor(b.eventTypeValue, b.eventTypeLabel) ? 0 : 1;
  if (wa !== wb) return wa - wb;
  const pa = a.person ? 0 : 1;
  const pb = b.person ? 0 : 1;
  if (pa !== pb) return pa - pb;
  const da = (a.eventDate ?? a.occasionDate).getTime();
  const db = (b.eventDate ?? b.occasionDate).getTime();
  if (da !== db) return db - da;
  return a.id < b.id ? -1 : a.id > b.id ? 1 : 0;
}

/** "12 Dec" in IST. */
export function istDayMonth(date: Date): string {
  const months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
  const ist = new Date(date.getTime() + IST_OFFSET_MS);
  return `${ist.getUTCDate()} ${months[ist.getUTCMonth()]}`;
}

function truncate(value: string, max: number): string {
  return value.length <= max ? value : `${value.slice(0, max - 1)}…`;
}

/** Title (≤120) + body (≤500) of one recipient's daily summary notification. */
export function reminderSummary(plans: readonly ReminderPlan[], _leadDays?: number): { title: string; body: string } {
  const line = (p: ReminderPlan) =>
    `${p.source.customerName} – ${occasionLabel(p.source.occasionKind, p.nth, p.source.person, p.source.eventTypeLabel)} on ${istDayMonth(p.occasionDate)}`;
  if (plans.length === 1) {
    const p = plans[0];
    return {
      title: truncate(`Upcoming occasion: ${p.source.customerName}`, 120),
      body: truncate(`${line(p)}. Send them a wish on WhatsApp.`, 500),
    };
  }
  return {
    title: truncate(`${plans.length} upcoming occasions to wish`, 120),
    body: truncate(plans.map(line).join("\n"), 500),
  };
}
