import { timingSafeEqual } from "crypto";
import { logger } from "firebase-functions/v2";
import { onRequest } from "firebase-functions/v2/https";
import { defineSecret } from "firebase-functions/params";
import { getFirestore, FieldValue, Timestamp } from "firebase-admin/firestore";
import { normalizePhone } from "./customers";
import { IST_OFFSET_MS, istDayStart, istShortDate } from "./istTime";

/**
 * Website → app enquiries.
 *
 * wedecorevents.com (Next.js, lib/services/leads/notifications.ts) POSTs every
 * contact-form lead to `websiteLead` with the shared secret in `X-Lead-Secret`,
 * and reads the event-type list from `websiteFormOptions` so the website form
 * always offers the app's own event types.
 *
 * Secret: `firebase functions:secrets:set WEBSITE_LEAD_SECRET` — the same value
 * goes into Vercel as LEAD_WEBHOOK_SECRET.
 */
const WEBSITE_LEAD_SECRET = defineSecret("WEBSITE_LEAD_SECRET");

const CREATED_BY = "system:website";
const SOURCE_VALUE = "google_website";
const SOURCE_LABEL_FALLBACK = "Google / Website";
const OTHER_EVENT_TYPE = { value: "others", label: "Others" };

/** Same list as DropdownDefaults.eventTypes (lib/core/constants/dropdown_defaults.dart). */
const DEFAULT_EVENT_TYPES: EventTypeOption[] = [
  { value: "wedding", label: "Wedding" },
  { value: "birthday", label: "Birthday" },
  { value: "corporate_event", label: "Corporate Event" },
  { value: "haldi", label: "Haldi" },
  { value: "anniversary", label: "Anniversary" },
  { value: "others", label: "Others" },
];

export type EventTypeOption = { value: string; label: string };

export type WebsitePlacePayload = {
  placeId?: unknown;
  address?: unknown;
  lat?: unknown;
  lng?: unknown;
  area?: unknown;
  city?: unknown;
};

/** Payload shape of buildCrmPayload() in the website repo. */
export type WebsiteLeadPayload = {
  externalId?: unknown;
  contact?: { name?: unknown; phone?: unknown; email?: unknown };
  event?: {
    type?: unknown;
    date?: unknown;
    budget?: unknown;
    notes?: unknown;
    area?: unknown;
    location?: unknown;
    place?: WebsitePlacePayload;
  };
  metadata?: { pageUrl?: unknown };
};

export type ParsedPlace = {
  placeId: string;
  address: string | null;
  lat: number | null;
  lng: number | null;
  area: string | null;
  city: string | null;
};

export type ParsedWebsiteLead = {
  externalId: string;
  name: string;
  phone: string;
  phoneNormalized: string;
  email: string | null;
  eventType: string;
  /** IST midnight of the event day. */
  eventDate: Date;
  budget: string | null;
  message: string;
  area: string | null;
  place: ParsedPlace | null;
  pageUrl: string | null;
};

function str(value: unknown, max: number): string {
  if (typeof value !== "string") return "";
  // eslint-disable-next-line no-control-regex
  return value.replace(/[\u0000-\u0008\u000B\u000C\u000E-\u001F\u007F]/g, "").trim().slice(0, max);
}

/** "2026-12-12" → IST midnight of that day, or null if not a real date. */
export function parseIstDate(raw: unknown): Date | null {
  const s = str(raw, 32);
  const m = /^(\d{4})-(\d{2})-(\d{2})$/.exec(s);
  if (!m) return null;
  const [y, mo, d] = [Number(m[1]), Number(m[2]), Number(m[3])];
  const utc = Date.UTC(y, mo - 1, d);
  const check = new Date(utc);
  if (check.getUTCFullYear() !== y || check.getUTCMonth() !== mo - 1 || check.getUTCDate() !== d) return null;
  return new Date(utc - IST_OFFSET_MS);
}

/** Validates the website payload. Returns an error string or the parsed lead. */
export function parseWebsiteLead(body: WebsiteLeadPayload, now: Date = new Date()): ParsedWebsiteLead | string {
  const externalId = str(body.externalId, 64);
  if (!/^[A-Za-z0-9-]{8,64}$/.test(externalId)) return "externalId missing or invalid";

  const name = tidyPersonName(str(body.contact?.name, 120));
  if (!name) return "name required";

  const phone = str(body.contact?.phone, 20);
  const phoneNormalized = normalizePhone(phone);
  // Website intake no longer asks for a number; WhatsApp is how we reach them.
  if (phoneNormalized && phoneNormalized.length !== 10) return "phone invalid";

  const emailRaw = str(body.contact?.email, 254).toLowerCase();
  const email = emailRaw && /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(emailRaw) ? emailRaw : null;

  const eventType = str(body.event?.type, 80);
  if (!eventType) return "event type required";

  const eventDate = parseIstDate(body.event?.date);
  if (!eventDate) return "event date required (YYYY-MM-DD)";
  if (eventDate.getTime() < istDayStart(now).getTime()) return "event date is in the past";

  const location = str(body.event?.location, 200) || str(body.event?.area, 200);
  if (!location) return "location required";

  const pageUrlRaw = str(body.metadata?.pageUrl, 500);
  return {
    externalId,
    name,
    phone,
    phoneNormalized,
    email,
    eventType,
    eventDate,
    budget: str(body.event?.budget, 64) || null,
    message: str(body.event?.notes, 4000),
    area: location,
    place: parsePlace(body.event?.place),
    pageUrl: pageUrlRaw || null,
  };
}

function finiteOrNull(raw: unknown): number | null {
  return typeof raw === "number" && Number.isFinite(raw) ? raw : null;
}

function parsePlace(raw: WebsitePlacePayload | undefined): ParsedPlace | null {
  if (!raw || typeof raw !== "object") return null;
  const placeId = str(raw.placeId, 512);
  if (!placeId) return null;
  const lat = finiteOrNull(raw.lat);
  const lng = finiteOrNull(raw.lng);
  return {
    placeId,
    address: str(raw.address, 300) || null,
    lat: lat !== null && lng !== null ? lat : null,
    lng: lat !== null && lng !== null ? lng : null,
    area: str(raw.area, 120) || null,
    city: str(raw.city, 80) || null,
  };
}

/**
 * "priya sharma" → "Priya Sharma"; words that already have a capital are kept
 * as typed. Same rule as tidyPersonName in lib/core/utils/name_case.dart.
 */
export function tidyPersonName(raw: string): string {
  return raw
    .trim()
    .split(/\s+/)
    .filter(Boolean)
    .map((w) => (w === w.toLowerCase() ? w.charAt(0).toUpperCase() + w.slice(1) : w))
    .join(" ");
}

function slug(value: string): string {
  return value.toLowerCase().replace(/[^a-z0-9]+/g, "_").replace(/^_+|_+$/g, "");
}

/** Matches the website's event type (a value or a label) to an app event type. */
export function matchEventType(raw: string, options: readonly EventTypeOption[]): EventTypeOption | null {
  const key = slug(raw);
  if (!key) return null;
  return (
    options.find((o) => o.value === raw) ??
    options.find((o) => slug(o.value) === key || slug(o.label) === key) ??
    null
  );
}

/** Active event types from dropdowns/event_types/items, in admin order; defaults if none. */
export async function loadEventTypes(db: FirebaseFirestore.Firestore): Promise<EventTypeOption[]> {
  const group = db.collection("dropdowns").doc("event_types");
  const [snap, groupSnap] = await Promise.all([group.collection("items").get(), group.get()]);
  const all = snap.docs.map((d) => {
    const data = d.data();
    const value = typeof data.value === "string" && data.value.trim() ? data.value.trim() : d.id;
    const label = typeof data.label === "string" && data.label.trim() ? data.label.trim() : value;
    return { value, label, active: data.active !== false, order: Number(data.order) || 0 };
  });
  const items = all
    .filter((d) => d.active)
    .sort((a, b) => a.order - b.order)
    .map(({ value, label }) => ({ value, label }));
  // Until an admin opens Dropdown Manager (which saves the built-ins once and sets
  // `defaultsSeeded`), the built-ins aren't stored: show them alongside saved items.
  if (groupSnap.get("defaultsSeeded") !== true) {
    const saved = new Set(all.map((d) => d.value));
    return [...DEFAULT_EVENT_TYPES.filter((t) => !saved.has(t.value)), ...items];
  }
  return items.length > 0 ? items : DEFAULT_EVENT_TYPES;
}

async function sourceLabel(db: FirebaseFirestore.Firestore): Promise<string> {
  const snap = await db
    .collection("dropdowns").doc("sources").collection("items")
    .where("value", "==", SOURCE_VALUE).limit(1).get();
  const label = snap.docs[0]?.get("label");
  return typeof label === "string" && label ? label : SOURCE_LABEL_FALLBACK;
}

async function activeAdminIds(db: FirebaseFirestore.Firestore): Promise<string[]> {
  const snap = await db.collection("users").where("role", "==", "admin").get();
  return snap.docs
    .filter((d) => (d.get("isActive") ?? d.get("active") ?? true) !== false)
    .map((d) => d.id);
}

const ZAKIR_UID = "q6fRF2hRHCa988zgzFT5ySddjw73";

function isActiveUser(data: FirebaseFirestore.DocumentData | undefined): boolean {
  return (data?.isActive ?? data?.active ?? true) !== false;
}

/** Website leads are assigned to Mohammed Zakir. */
export async function defaultAssigneeId(db: FirebaseFirestore.Firestore): Promise<string | null> {
  const known = await db.collection("users").doc(ZAKIR_UID).get();
  if (known.exists && isActiveUser(known.data())) return ZAKIR_UID;

  const snap = await db.collection("users").get();
  const match = snap.docs.find((d) => {
    const name = String(d.get("name") || d.get("displayName") || "").toLowerCase();
    return isActiveUser(d.data()) && /(^|\s)zakir(\s|$)/.test(name);
  });
  return match?.id ?? null;
}

function secretMatches(given: string | undefined, expected: string): boolean {
  if (!given || !expected) return false;
  const a = Buffer.from(given);
  const b = Buffer.from(expected);
  return a.length === b.length && timingSafeEqual(a, b);
}

function truncate(value: string, max: number): string {
  return value.length <= max ? value : `${value.slice(0, max - 1)}…`;
}

/** Fields the app's search uses — same as FirestoreService._searchIndexFields. */
export function searchIndexFields(lead: ParsedWebsiteLead, eventTypeLabel: string): Record<string, unknown> {
  return {
    customerNameLower: lead.name.toLowerCase(),
    phoneNormalized: lead.phoneNormalized,
    ...(lead.email ? { customerEmail: lead.email } : {}),
    textIndex: [lead.name, lead.phone, lead.email ?? "", lead.message, eventTypeLabel].join(" ").toLowerCase(),
  };
}

/** Enquiry document in the same shape FirestoreService.createEnquiry writes. */
export function buildEnquiryDoc(
  lead: ParsedWebsiteLead,
  eventType: EventTypeOption,
  unmatchedType: string | null,
  sourceLabelText: string,
  assignedTo: string | null = null,
): Record<string, unknown> {
  const notes = [
    lead.message,
    unmatchedType ? `Event type on website: ${unmatchedType}` : "",
  ].filter(Boolean).join("\n\n");
  return {
    customerName: lead.name,
    customerPhone: lead.phone,
    eventType: eventType.value,
    eventTypeValue: eventType.value,
    eventTypeLabel: eventType.label,
    eventDate: Timestamp.fromDate(lead.eventDate),
    eventLocation: lead.area ?? "",
    guestCount: 0,
    ...(lead.place?.placeId
      ? {
          locationPlaceId: lead.place.placeId,
          ...(lead.place.address ? { locationAddress: lead.place.address } : {}),
          ...(lead.place.lat !== null ? { locationLat: lead.place.lat } : {}),
          ...(lead.place.lng !== null ? { locationLng: lead.place.lng } : {}),
          ...(lead.place.area ? { locationArea: lead.place.area } : {}),
          ...(lead.place.city ? { locationCity: lead.place.city } : {}),
        }
      : lead.area
        ? { locationArea: lead.area }
        : {}),
    ...(lead.budget ? { budgetRange: lead.budget } : {}),
    ...(notes ? { notes, description: notes } : {}),
    statusValue: "new",
    statusLabel: "New",
    paymentStatus: "pending",
    paymentStatusValue: "pending",
    totalCost: null,
    advancePaid: null,
    assignedTo,
    createdBy: CREATED_BY,
    priority: "medium",
    priorityValue: "medium",
    priorityLabel: "Medium",
    source: SOURCE_VALUE,
    sourceValue: SOURCE_VALUE,
    sourceLabel: sourceLabelText,
    websiteLeadId: lead.externalId,
    ...(lead.pageUrl ? { sourcePageUrl: lead.pageUrl } : {}),
    ...searchIndexFields(lead, eventType.label),
    createdAt: FieldValue.serverTimestamp(),
    updatedAt: FieldValue.serverTimestamp(),
  };
}

export const websiteLead = onRequest(
  { secrets: [WEBSITE_LEAD_SECRET], invoker: "public", cors: false, maxInstances: 3 },
  async (req, res) => {
    if (req.method !== "POST") {
      res.status(405).json({ ok: false, error: "method not allowed" });
      return;
    }
    if (!secretMatches(req.get("x-lead-secret"), WEBSITE_LEAD_SECRET.value())) {
      res.status(401).json({ ok: false, error: "unauthorized" });
      return;
    }

    const parsed = parseWebsiteLead((req.body ?? {}) as WebsiteLeadPayload);
    if (typeof parsed === "string") {
      logger.warn("websiteLead: rejected", { reason: parsed });
      res.status(400).json({ ok: false, error: parsed });
      return;
    }

    const db = getFirestore();
    const [eventTypes, sourceLabelText, adminIds, assignedTo, previous] = await Promise.all([
      loadEventTypes(db),
      sourceLabel(db),
      activeAdminIds(db),
      defaultAssigneeId(db),
      parsed.phoneNormalized.length === 10
        ? db.collection("enquiries").where("phoneNormalized", "==", parsed.phoneNormalized).limit(1).get()
        : Promise.resolve({ empty: true as const }),
    ]);
    const matched = matchEventType(parsed.eventType, eventTypes);
    const eventType = matched ?? eventTypes.find((t) => t.value === OTHER_EVENT_TYPE.value) ?? OTHER_EVENT_TYPE;
    const repeat = !previous.empty;

    // Doc id from the website's lead id: a retried webhook can't create a second enquiry.
    const ref = db.collection("enquiries").doc(`web_${parsed.externalId}`);
    const batch = db.batch();
    batch.create(
      ref,
      buildEnquiryDoc(parsed, eventType, matched ? null : parsed.eventType, sourceLabelText, assignedTo),
    );

    const title = repeat ? "New website enquiry · repeat customer" : "New website enquiry";
    const body = truncate(
      [parsed.name, eventType.label, istShortDate(parsed.eventDate), parsed.area].filter(Boolean).join(" · "),
      500,
    );
    const notifyUids = Array.from(new Set([...adminIds, assignedTo].filter((id): id is string => !!id)));
    for (const uid of notifyUids) {
      batch.set(db.collection("users").doc(uid).collection("notifications").doc(), {
        title,
        body,
        type: "new_enquiry",
        enquiryId: ref.id,
        data: {
          type: "new_enquiry",
          enquiryId: ref.id,
          customerName: parsed.name,
          eventType: eventType.label,
          createdBy: CREATED_BY,
        },
        read: false,
        createdAt: FieldValue.serverTimestamp(),
      });
    }

    try {
      await batch.commit();
    } catch (error: any) {
      // gRPC 6 = ALREADY_EXISTS: the same lead was delivered before.
      if (error?.code === 6) {
        res.status(200).json({ ok: true, enquiryId: ref.id, duplicate: true });
        return;
      }
      logger.error("websiteLead: write failed", { error: error?.message });
      res.status(500).json({ ok: false, error: "write failed" });
      return;
    }

    logger.info("websiteLead: created", { enquiryId: ref.id, repeat, notified: notifyUids.length });
    res.status(201).json({ ok: true, enquiryId: ref.id });
  },
);

/** Event types for the website form (server-to-server; same secret). */
export const websiteFormOptions = onRequest(
  { secrets: [WEBSITE_LEAD_SECRET], invoker: "public", cors: false, maxInstances: 2 },
  async (req, res) => {
    if (req.method !== "GET") {
      res.status(405).json({ ok: false, error: "method not allowed" });
      return;
    }
    if (!secretMatches(req.get("x-lead-secret"), WEBSITE_LEAD_SECRET.value())) {
      res.status(401).json({ ok: false, error: "unauthorized" });
      return;
    }
    const eventTypes = await loadEventTypes(getFirestore());
    res.set("Cache-Control", "private, max-age=300");
    res.status(200).json({ ok: true, eventTypes });
  },
);
