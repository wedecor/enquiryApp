import { logger } from "firebase-functions/v2";
import { onCall, HttpsError } from "firebase-functions/v2/https";
import { getFirestore, Timestamp } from "firebase-admin/firestore";
import { EventFunction, eventFunctionsOf, functionLabel, istDayKey } from "./eventFunctions";
import { IST_OFFSET_MS } from "./istTime";
import { rawStatusValuesFor } from "./statusVocabulary";

/**
 * Safety cap on approved bookings read per call. The query spans the requested
 * days + 31 (eventDate = a booking's LAST function), so allow plenty.
 */
const MAX_RESULTS = 500;

/** At most this many days per call (a booking rarely has more functions). */
export const MAX_DATES = 10;

/** A booking's functions span days, not months: eventDate (last function) is < first day + 31d. */
export const FUNCTION_SPAN_DAYS = 31;

const DAY_MS = 24 * 60 * 60 * 1000;

type ApprovedOnDateRequest = {
  /** Legacy single day, `YYYY-MM-DD` (IST). */
  date?: string;
  /** 1–10 days, `YYYY-MM-DD` (IST): every function date of the booking being checked. */
  dates?: string[];
  excludeEnquiryId?: string;
};

type ApprovedOnDateEvent = {
  id: string;
  /** The function's `locationArea`, else its location text; null when both blank. */
  area: string | null;
  eventType: string;
};

type ApprovedOnDateDay = {
  date: string;
  count: number;
  events: ApprovedOnDateEvent[];
};

type ApprovedOnDateResponse = {
  /** Total over every requested day (legacy `date`: that day). */
  count: number;
  events: ApprovedOnDateEvent[];
  days: ApprovedOnDateDay[];
};

/** Doc shape needed for day matching (id + data). */
export type ApprovedDoc = { id: string; data: Record<string, unknown> };

/**
 * Pure day matching: for each requested IST day, the approved FUNCTIONS on that day
 * across [docs] (legacy docs = their single synthesized function). Skips
 * [excludeId] and merged duplicates.
 */
export function matchApprovedFunctions(
  docs: readonly ApprovedDoc[],
  dayKeys: readonly string[],
  excludeId: string | null
): ApprovedOnDateDay[] {
  const byDay = new Map<string, ApprovedOnDateEvent[]>(dayKeys.map((d) => [d, []]));
  for (const doc of docs) {
    if (doc.id === excludeId || doc.data.mergedInto) continue;
    for (const fn of eventFunctionsOf(doc.data) as EventFunction[]) {
      const list = byDay.get(istDayKey(fn.date));
      if (!list) continue;
      list.push({
        id: doc.id,
        area: fn.locationArea ?? fn.location,
        eventType: functionLabel(fn),
      });
    }
  }
  return dayKeys.map((date) => {
    const events = byDay.get(date) ?? [];
    return { date, count: events.length, events };
  });
}

/** Users docs written before the isActive migration may still carry `active`. */
function isActiveUserData(data: FirebaseFirestore.DocumentData | undefined): boolean {
  const isActive = data?.isActive ?? data?.active ?? true;
  return isActive !== false;
}

/**
 * [start, end) UTC instants of the IST calendar day `YYYY-MM-DD`, or null if invalid.
 *
 * The app stores `eventDate` as the date picker's local midnight (`Timestamp.fromDate`
 * of `DateTime(y, m, d)`); on IST devices that is exactly 00:00 IST (18:30Z the day
 * before). Any time later that IST day (legacy docs with a time of day, or devices west
 * of IST) also falls inside the range.
 */
export function istDayRange(date: string): { start: Date; end: Date } | null {
  const match = /^(\d{4})-(\d{2})-(\d{2})$/.exec(date);
  if (!match) return null;
  const year = Number(match[1]);
  const month = Number(match[2]);
  const day = Number(match[3]);
  const utcMidnight = Date.UTC(year, month - 1, day);
  const check = new Date(utcMidnight);
  if (
    check.getUTCFullYear() !== year ||
    check.getUTCMonth() !== month - 1 ||
    check.getUTCDate() !== day
  ) {
    return null; // e.g. 2026-02-30
  }
  const start = new Date(utcMidnight - IST_OFFSET_MS);
  const end = new Date(start.getTime() + 24 * 60 * 60 * 1000); // IST has no DST
  return { start, end };
}

/**
 * Approved FUNCTIONS of other bookings on each requested day, for the "date clash"
 * warning shown before approving a booking (all its function dates) or saving new
 * function dates on an approved one. Accepts `dates` (1–10 IST days) or the legacy
 * single `date`; legacy single-event bookings count as one function on their eventDate.
 * Runs server-side because staff can only read enquiries assigned to them. Returns only
 * area and event type (no customer, money or notes).
 */
export const approvedOnDate = onCall<ApprovedOnDateRequest, Promise<ApprovedOnDateResponse>>(
  {
    cors: true,
    region: "asia-south1",
    enforceAppCheck: false,
  },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Must be signed in to check bookings");
    }
    const callerUid = request.auth.uid;
    const db = getFirestore();

    const callerSnap = await db.collection("users").doc(callerUid).get();
    const callerData = callerSnap.data();
    const callerRole = callerData?.role;
    if (
      !callerSnap.exists ||
      !isActiveUserData(callerData) ||
      (callerRole !== "admin" && callerRole !== "staff")
    ) {
      throw new HttpsError("permission-denied", "Active account required");
    }

    const input = (request.data ?? {}) as Partial<ApprovedOnDateRequest>;
    let rawDates: unknown[];
    if (input.dates !== undefined) {
      if (!Array.isArray(input.dates) || input.dates.length < 1 || input.dates.length > MAX_DATES) {
        throw new HttpsError("invalid-argument", `dates must be 1–${MAX_DATES} YYYY-MM-DD strings`);
      }
      rawDates = input.dates;
    } else if (typeof input.date === "string") {
      rawDates = [input.date];
    } else {
      throw new HttpsError("invalid-argument", "date must be a YYYY-MM-DD string");
    }
    const dayKeys: string[] = [];
    const ranges: { start: Date; end: Date }[] = [];
    for (const raw of rawDates) {
      const key = typeof raw === "string" ? raw.trim() : "";
      const range = istDayRange(key);
      if (!range) {
        throw new HttpsError("invalid-argument", "dates must be valid YYYY-MM-DD dates");
      }
      if (dayKeys.includes(key)) continue;
      dayKeys.push(key);
      ranges.push(range);
    }
    if (input.excludeEnquiryId !== undefined && typeof input.excludeEnquiryId !== "string") {
      throw new HttpsError("invalid-argument", "excludeEnquiryId must be a string");
    }
    const excludeId = input.excludeEnquiryId?.trim() || null;

    // eventDate = the LAST function's date, so a booking with a function on day D has
    // eventDate in [D, D + 31d). One query covers every requested day.
    // `in` + range → composite index statusValue ASC, eventDate ASC (firestore.indexes.json).
    const start = new Date(Math.min(...ranges.map((r) => r.start.getTime())));
    const end = new Date(Math.max(...ranges.map((r) => r.start.getTime())) + FUNCTION_SPAN_DAYS * DAY_MS);
    const snap = await db
      .collection("enquiries")
      .where("statusValue", "in", rawStatusValuesFor("approved"))
      .where("eventDate", ">=", Timestamp.fromDate(start))
      .where("eventDate", "<", Timestamp.fromDate(end))
      .limit(MAX_RESULTS)
      .get();
    if (snap.size >= MAX_RESULTS) {
      const dates = dayKeys;
      logger.warn("approvedOnDate hit the result cap", { dates, cap: MAX_RESULTS });
    }

    const days = matchApprovedFunctions(
      snap.docs.map((d) => ({ id: d.id, data: d.data() })),
      dayKeys,
      excludeId
    );
    const count = days.reduce((total, d) => total + d.count, 0);

    logger.info("approvedOnDate completed", {
      by: callerUid,
      dates: dayKeys,
      count,
    });

    return { count, events: days.flatMap((d) => d.events), days };
  }
);
