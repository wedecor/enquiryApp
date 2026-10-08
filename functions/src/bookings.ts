import { logger } from "firebase-functions/v2";
import { onCall, HttpsError } from "firebase-functions/v2/https";
import { getFirestore, Timestamp } from "firebase-admin/firestore";
import { IST_OFFSET_MS } from "./istTime";
import { rawStatusValuesFor } from "./statusVocabulary";

/** Safety cap: a single day never has anywhere near this many approved bookings. */
const MAX_RESULTS = 50;

type ApprovedOnDateRequest = {
  /** The event's calendar day as the user sees it (IST), `YYYY-MM-DD`. */
  date: string;
  excludeEnquiryId?: string;
};

type ApprovedOnDateEvent = {
  id: string;
  /** `eventLocation`, or null when blank. */
  area: string | null;
  eventType: string;
};

type ApprovedOnDateResponse = {
  count: number;
  events: ApprovedOnDateEvent[];
};

/** Users docs written before the isActive migration may still carry `active`. */
function isActiveUserData(data: FirebaseFirestore.DocumentData | undefined): boolean {
  const isActive = data?.isActive ?? data?.active ?? true;
  return isActive !== false;
}

function stringOrNull(raw: unknown): string | null {
  return typeof raw === "string" && raw.trim() ? raw.trim() : null;
}

function titleCase(value: string): string {
  return value
    .replace(/_/g, " ")
    .split(" ")
    .filter(Boolean)
    .map((w) => w[0].toUpperCase() + w.slice(1))
    .join(" ");
}

function eventTypeLabelOf(data: FirebaseFirestore.DocumentData): string {
  const label = stringOrNull(data.eventTypeLabel);
  if (label) return label;
  const value = stringOrNull(data.eventTypeValue) ?? stringOrNull(data.eventType);
  return value ? titleCase(value) : "Event";
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
 * Other APPROVED enquiries on an event day, for the "date clash" warning shown before
 * approving an enquiry or moving an approved one to a new date. Runs server-side
 * because staff can only read enquiries assigned to them. Returns only area and event
 * type (no customer, money or notes).
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
    if (typeof input.date !== "string") {
      throw new HttpsError("invalid-argument", "date must be a YYYY-MM-DD string");
    }
    const range = istDayRange(input.date.trim());
    if (!range) {
      throw new HttpsError("invalid-argument", "date must be a valid YYYY-MM-DD date");
    }
    if (input.excludeEnquiryId !== undefined && typeof input.excludeEnquiryId !== "string") {
      throw new HttpsError("invalid-argument", "excludeEnquiryId must be a string");
    }
    const excludeId = input.excludeEnquiryId?.trim() || null;

    // `in` + range → composite index statusValue ASC, eventDate ASC (firestore.indexes.json).
    const snap = await db
      .collection("enquiries")
      .where("statusValue", "in", rawStatusValuesFor("approved"))
      .where("eventDate", ">=", Timestamp.fromDate(range.start))
      .where("eventDate", "<", Timestamp.fromDate(range.end))
      .limit(MAX_RESULTS)
      .get();

    const events: ApprovedOnDateEvent[] = snap.docs
      .filter((d) => d.id !== excludeId && !d.get("mergedInto"))
      .map((d) => {
        const data = d.data();
        return {
          id: d.id,
          area: stringOrNull(data.eventLocation),
          eventType: eventTypeLabelOf(data),
        };
      });

    logger.info("approvedOnDate completed", {
      by: callerUid,
      date: input.date,
      count: events.length,
    });

    return { count: events.length, events };
  }
);
