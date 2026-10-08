import { logger } from "firebase-functions/v2";
import { onCall, HttpsError } from "firebase-functions/v2/https";
import { getFirestore } from "firebase-admin/firestore";
import { canonicalStatus, CanonicalStatus, statusLabel } from "./statusVocabulary";

/**
 * Customer identity = normalized phone. MUST match
 * `normalizePhone` in lib/core/utils/phone_normalizer.dart and the
 * 2026_10_backfill_phone_normalized migration:
 *   1. keep digits only;
 *   2. if more than 10 digits remain, keep the last 10
 *      (drops +91 / 0091 / leading 0 on Indian mobiles).
 * Shorter numbers (landlines) are kept as-is.
 */
export function normalizePhone(raw: unknown): string {
  if (typeof raw !== "string") return "";
  const digits = raw.replace(/\D/g, "");
  return digits.length > 10 ? digits.slice(-10) : digits;
}

/** Below this many digits a number is too ambiguous to identify a customer. */
const MIN_LOOKUP_DIGITS = 7;
const MAX_RESULTS = 50;
const OPEN_STATUSES: ReadonlySet<CanonicalStatus> = new Set(["new", "in_talks", "approved"]);

type LookupCustomerRequest = {
  phone: string;
  excludeEnquiryId?: string;
};

type LookupCustomerEvent = {
  id: string;
  eventType: string;
  eventDate: string | null;
  status: CanonicalStatus | null;
  statusLabel: string;
  assignedToName: string | null;
  /** True when the caller is the assignee (lets staff open their own enquiries). */
  assignedToMe: boolean;
  createdAt: string | null;
  isOpen: boolean;
};

type LookupCustomerResponse = {
  customer: {
    name: string;
    email: string | null;
    whatsappNumber: string | null;
    phone: string | null;
  } | null;
  events: LookupCustomerEvent[];
  totalEvents: number;
  openEvents: number;
};

/** Users docs written before the isActive migration may still carry `active`. */
function isActiveUserData(data: FirebaseFirestore.DocumentData | undefined): boolean {
  const isActive = data?.isActive ?? data?.active ?? true;
  return isActive !== false;
}

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
 * Finds a customer's other enquiries by phone. Runs server-side because staff can only
 * read enquiries assigned to them. Returns contact basics from the most recent enquiry
 * and a minimal summary per event (no money, notes or internal fields).
 */
export const lookupCustomer = onCall<LookupCustomerRequest, Promise<LookupCustomerResponse>>(
  {
    cors: true,
    region: "asia-south1",
    enforceAppCheck: false,
  },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Must be signed in to look up customers");
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

    const input = (request.data ?? {}) as Partial<LookupCustomerRequest>;
    if (typeof input.phone !== "string" || input.phone.length > 30) {
      throw new HttpsError("invalid-argument", "phone must be a string of at most 30 characters");
    }
    if (input.excludeEnquiryId !== undefined && typeof input.excludeEnquiryId !== "string") {
      throw new HttpsError("invalid-argument", "excludeEnquiryId must be a string");
    }
    const excludeId = input.excludeEnquiryId?.trim() || null;

    const empty: LookupCustomerResponse = { customer: null, events: [], totalEvents: 0, openEvents: 0 };
    const normalized = normalizePhone(input.phone);
    if (normalized.length < MIN_LOOKUP_DIGITS) {
      return empty;
    }

    // Equality only → served by the automatic single-field index (no composite index).
    const snap = await db
      .collection("enquiries")
      .where("phoneNormalized", "==", normalized)
      .limit(MAX_RESULTS)
      .get();

    if (snap.empty) {
      return empty;
    }

    const docs = [...snap.docs].sort((a, b) => {
      const at = toDate(a.get("createdAt"))?.getTime() ?? 0;
      const bt = toDate(b.get("createdAt"))?.getTime() ?? 0;
      return bt - at;
    });

    const latest = docs[0].data();
    const customer = {
      name: stringOrNull(latest.customerName) ?? "Customer",
      email: stringOrNull(latest.customerEmail),
      whatsappNumber: stringOrNull(latest.whatsappNumber),
      phone: stringOrNull(latest.customerPhone),
    };

    // Other events: skip the enquiry being viewed and enquiries already merged away.
    const eventDocs = docs.filter((d) => d.id !== excludeId && !d.get("mergedInto"));

    const assigneeIds = Array.from(
      new Set(
        eventDocs
          .map((d) => stringOrNull(d.get("assignedTo")))
          .filter((uid): uid is string => uid !== null)
      )
    );
    const names = new Map<string, string>();
    if (assigneeIds.length > 0) {
      try {
        const userSnaps = await db.getAll(...assigneeIds.map((uid) => db.collection("users").doc(uid)));
        for (const u of userSnaps) {
          const name = stringOrNull(u.get("name")) ?? stringOrNull(u.get("email"));
          if (u.exists && name) names.set(u.id, name);
        }
      } catch (error: any) {
        logger.warn("lookupCustomer: could not resolve assignee names", { error: error?.message });
      }
    }

    const events: LookupCustomerEvent[] = eventDocs.map((d) => {
      const data = d.data();
      const status = canonicalStatus(data.statusValue);
      const assignedTo = stringOrNull(data.assignedTo);
      return {
        id: d.id,
        eventType: eventTypeLabelOf(data),
        eventDate: toDate(data.eventDate)?.toISOString() ?? null,
        status,
        statusLabel: status ? statusLabel(status) : stringOrNull(data.statusLabel) ?? "Unknown",
        assignedToName: assignedTo ? names.get(assignedTo) ?? "a teammate" : null,
        assignedToMe: assignedTo === callerUid,
        createdAt: toDate(data.createdAt)?.toISOString() ?? null,
        isOpen: status !== null && OPEN_STATUSES.has(status),
      };
    });

    const openEvents = events.filter((e) => e.isOpen).length;
    logger.info("lookupCustomer completed", {
      by: callerUid,
      matches: docs.length,
      events: events.length,
      openEvents,
    });

    return { customer, events, totalEvents: events.length, openEvents };
  }
);
