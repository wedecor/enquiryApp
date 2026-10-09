import { logger } from "firebase-functions/v2";
import { Timestamp } from "firebase-admin/firestore";
import { normalizePhone } from "./customers";
import { occasionEventOf } from "./eventFunctions";
import { OccasionStamp, StampSource, computeOccasionStamps } from "./reengagementLogic";
import { canonicalStatus } from "./statusVocabulary";

/** Sibling lookup cap per customer (same as lookupCustomer). */
const MAX_SIBLINGS = 50;

function toDate(raw: unknown): Date | null {
  if (raw instanceof Date) return raw;
  if (raw && typeof (raw as { toDate?: unknown }).toDate === "function") {
    return (raw as { toDate: () => Date }).toDate();
  }
  return null;
}

function stringOrNull(raw: unknown): string | null {
  return typeof raw === "string" && raw.trim() ? raw.trim() : null;
}

export function phoneOf(data: FirebaseFirestore.DocumentData): string {
  return stringOrNull(data.phoneNormalized) ?? normalizePhone(data.customerPhone);
}

/**
 * Enquiry doc → stamping input. [statusOverride] = status being written in the same update.
 *
 * Multi-function bookings: kind from the MAIN function's type and date from the
 * wedding-anchor function when present, else the main function (occasionEventOf).
 * Legacy single-event docs: their top-level event type and date, as before.
 */
export function toStampSource(
  id: string,
  data: FirebaseFirestore.DocumentData,
  statusOverride?: string
): StampSource {
  const event = occasionEventOf(data);
  return {
    id,
    eventTypeValue: event.eventTypeValue,
    eventTypeLabel: event.eventTypeLabel,
    eventDate: event.eventDate,
    fallbackDate: toDate(data.completedAt) ?? new Date(),
    status: statusOverride ?? canonicalStatus(data.statusValue),
    merged: !!data.mergedInto,
    manual: data.occasionManual === true,
    occasionKind: data.occasionKind,
    occasionMonthDay: data.occasionMonthDay,
    occasionDate: toDate(data.occasionDate),
  };
}

/** Firestore fields for a stamp. */
export function stampFields(stamp: OccasionStamp): Record<string, unknown> {
  return {
    occasionKind: stamp.occasionKind,
    occasionDate: Timestamp.fromDate(stamp.occasionDate),
    occasionMonthDay: stamp.occasionMonthDay,
  };
}

/**
 * Stamps for an enquiry becoming completed, including wedding-family siblings of
 * the same customer (see computeOccasionStamps). A failed sibling lookup still
 * stamps the enquiry itself with its own event date.
 */
export async function planOccasionStamps(
  db: FirebaseFirestore.Firestore,
  enquiryId: string,
  data: FirebaseFirestore.DocumentData,
  statusOverride?: string
): Promise<Map<string, OccasionStamp>> {
  const target = toStampSource(enquiryId, data, statusOverride);
  const phone = phoneOf(data);
  let siblings: StampSource[] = [];
  if (phone.length >= 7) {
    try {
      // Equality only → automatic single-field index.
      const snap = await db.collection("enquiries").where("phoneNormalized", "==", phone).limit(MAX_SIBLINGS).get();
      siblings = snap.docs.filter((d) => d.id !== enquiryId).map((d) => toStampSource(d.id, d.data()));
    } catch (error: any) {
      logger.warn("Occasion stamping: sibling lookup failed", { enquiryId, error: error?.message });
    }
  }
  return computeOccasionStamps(target, siblings);
}
