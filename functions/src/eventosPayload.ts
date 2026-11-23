/**
 * Pure EventOS feed payload builder (M5-01 bridge).
 * No Firebase imports — unit-tested in isolation.
 */

import { createHash } from "crypto";
import { normalizePhone } from "./customers";
import { eventFunctionsOf, istDayKey, type EventFunction } from "./eventFunctions";
import { canonicalStatus, type CanonicalStatus } from "./statusVocabulary";
import { normalizeEventOSWallClockTime } from "./eventosTime";

export { normalizeEventOSWallClockTime } from "./eventosTime";

export const EVENTOS_SCHEMA_VERSION = 1 as const;
export const EVENTOS_SOURCE = "wedecor-enquiries" as const;

export type EventOSMoney = {
  totalCost: number;
  advancePaid: number;
  currency: string;
};

export type EventOSFunctionPayload = {
  functionId: string;
  eventType: string;
  eventTypeLabel: string | null;
  date: string;
  time: string | null;
  location: string | null;
  locationArea: string | null;
  locationAddress: string | null;
  locationPlaceId: string | null;
  lat: number | null;
  lng: number | null;
  notes: string | null;
};

export type EventOSPayload = {
  schemaVersion: typeof EVENTOS_SCHEMA_VERSION;
  source: typeof EVENTOS_SOURCE;
  enquiryId: string;
  sourceUpdatedAt: string;
  status: string;
  customer: { name: string; phone: string | null; email: string | null };
  event: {
    eventType: string;
    eventTypeLabel: string | null;
    startDate: string;
    endDate: string;
    guestCount: number | null;
    notes: string | null;
    assigneeName: string | null;
  };
  functions: EventOSFunctionPayload[];
  money?: EventOSMoney;
};

export type EventosSyncBookkeeping = {
  syncedAt?: unknown;
  lastHash?: string;
  lastStatus?: string;
  lastHttpStatus?: number;
  lastError?: string | null;
  eventosEventId?: string | null;
};

export type BuildEventOSPayloadOptions = {
  /** Called when a non-empty time string could not be normalised (never receives the value). */
  onTimeUnparsed?: (enquiryId: string) => void;
};

function str(raw: unknown): string | null {
  return typeof raw === "string" && raw.trim() ? raw.trim() : null;
}

function optionalText(raw: unknown, max: number): string | null {
  const s = str(raw);
  if (!s) return null;
  return s.length > max ? s.slice(0, max) : s;
}

function toDate(raw: unknown): Date | null {
  if (raw instanceof Date) return Number.isNaN(raw.getTime()) ? null : raw;
  if (raw && typeof (raw as { toDate?: unknown }).toDate === "function") {
    return (raw as { toDate: () => Date }).toDate();
  }
  if (typeof raw === "string" && raw.trim()) {
    const d = new Date(raw);
    return Number.isNaN(d.getTime()) ? null : d;
  }
  return null;
}

function toIsoWithOffset(date: Date): string {
  // Prefer the stored instant's ISO; EventOS accepts ISO-8601 with offset.
  return date.toISOString();
}

/** 10-digit Indian mobile → +91XXXXXXXXXX; otherwise null. */
export function formatEventOSPhone(raw: unknown): string | null {
  const digits = normalizePhone(raw);
  if (digits.length !== 10) return null;
  return `+91${digits}`;
}

function numOrNull(raw: unknown): number | null {
  if (typeof raw === "number" && Number.isFinite(raw)) return raw;
  if (typeof raw === "string" && raw.trim()) {
    const n = Number(raw);
    return Number.isFinite(n) ? n : null;
  }
  return null;
}

function coordsFromMap(m: Record<string, unknown>): { lat: number | null; lng: number | null } {
  const lat = numOrNull(m.lat) ?? numOrNull(m.locationLat);
  const lng = numOrNull(m.lng) ?? numOrNull(m.locationLng);
  return {
    lat: lat !== null && lat >= -90 && lat <= 90 ? lat : null,
    lng: lng !== null && lng >= -180 && lng <= 180 ? lng : null,
  };
}

function nonEmptyEventType(raw: unknown, fallback = "others"): string {
  return str(raw) ?? fallback;
}

function normalizeFunctionTime(
  enquiryId: string,
  raw: string | null,
  onTimeUnparsed?: (enquiryId: string) => void,
): string | null {
  if (raw == null || !raw.trim()) return null;
  const normalized = normalizeEventOSWallClockTime(raw);
  if (normalized === null) {
    onTimeUnparsed?.(enquiryId);
  }
  return normalized;
}

function functionPayload(
  enquiryId: string,
  f: EventFunction,
  coords: { lat: number | null; lng: number | null },
  onTimeUnparsed?: (enquiryId: string) => void,
): EventOSFunctionPayload {
  return {
    functionId: f.id.trim() || "main",
    eventType: nonEmptyEventType(f.eventType),
    eventTypeLabel: optionalText(f.eventTypeLabel, 200),
    date: istDayKey(f.date),
    time: normalizeFunctionTime(enquiryId, f.time, onTimeUnparsed),
    location: optionalText(f.location, 500),
    locationArea: optionalText(f.locationArea, 500),
    locationAddress: optionalText(f.locationAddress, 1000),
    locationPlaceId: optionalText(f.locationPlaceId, 256),
    lat: coords.lat,
    lng: coords.lng,
    notes: optionalText(f.notes, 4000),
  };
}

function coordsForFunction(
  f: EventFunction,
  enquiry: Record<string, unknown>,
): { lat: number | null; lng: number | null } {
  const raw = enquiry.functions;
  if (Array.isArray(raw)) {
    for (const entry of raw) {
      if (!entry || typeof entry !== "object") continue;
      const m = entry as Record<string, unknown>;
      const id = str(m.id);
      if (id === f.id || (!id && f.id.startsWith("f"))) {
        const c = coordsFromMap(m);
        if (c.lat !== null || c.lng !== null) return c;
      }
    }
  }
  // Legacy single-function: top-level place coords.
  if (f.id === "main") return coordsFromMap(enquiry);
  return { lat: null, lng: null };
}

function resolveSourceUpdatedAt(enquiry: Record<string, unknown>): string {
  const candidates = [enquiry.updatedAt, enquiry.statusUpdatedAt, enquiry.createdAt];
  for (const c of candidates) {
    const d = toDate(c);
    if (d) return toIsoWithOffset(d);
  }
  return toIsoWithOffset(new Date());
}

/** Non-negative integer guest count, or null when missing / not a finite number. */
export function resolveGuestCount(enquiry: Record<string, unknown>): number | null {
  const n =
    numOrNull(enquiry.guestCount) ??
    numOrNull(enquiry.numberOfGuests) ??
    numOrNull(enquiry.guests);
  if (n === null || n < 0) return null;
  const rounded = Math.round(n);
  if (rounded < 0 || rounded > 1_000_000) return null;
  return rounded;
}

function resolveMoney(financial: Record<string, unknown> | null): EventOSMoney | undefined {
  if (!financial) return undefined;
  const totalCost = numOrNull(financial.totalCost);
  const advancePaid = numOrNull(financial.advancePaid);
  if (totalCost === null && advancePaid === null) return undefined;
  const currencyRaw = str(financial.currency) ?? "INR";
  const currency = currencyRaw.length === 3 ? currencyRaw.toUpperCase() : "INR";
  return {
    totalCost: Math.max(0, totalCost ?? 0),
    advancePaid: Math.max(0, advancePaid ?? 0),
    currency,
  };
}

/** Ensure functionId values are unique (EventOS schema refine). */
function uniquifyFunctionIds(fns: EventOSFunctionPayload[]): EventOSFunctionPayload[] {
  const seen = new Set<string>();
  return fns.map((fn, index) => {
    let id = fn.functionId;
    if (!id || seen.has(id)) {
      id = `${fn.functionId || "f"}_${index}`;
      let n = 1;
      while (seen.has(id)) {
        id = `${fn.functionId || "f"}_${index}_${n}`;
        n += 1;
      }
    }
    seen.add(id);
    return id === fn.functionId ? fn : { ...fn, functionId: id };
  });
}

/**
 * Builds the schemaVersion:1 EventOS feed payload.
 * Dates are IST calendar days via `istDayKey`. Times are normalised to HH:mm.
 */
export function buildEventOSPayload(
  enquiryId: string,
  enquiry: Record<string, unknown>,
  financial: Record<string, unknown> | null = null,
  options?: BuildEventOSPayloadOptions,
): EventOSPayload {
  const status = canonicalStatus(enquiry.statusValue ?? enquiry.status ?? enquiry.eventStatus) ?? "new";
  const functions = eventFunctionsOf(enquiry);
  const functionPayloads = uniquifyFunctionIds(
    functions.map((f) =>
      functionPayload(enquiryId, f, coordsForFunction(f, enquiry), options?.onTimeUnparsed),
    ),
  );

  let startDate: string;
  let endDate: string;
  if (functionPayloads.length > 0) {
    const days = functionPayloads.map((f) => f.date).sort();
    startDate = days[0];
    endDate = days[days.length - 1];
  } else {
    const fallback = toDate(enquiry.eventDate) ?? new Date();
    startDate = endDate = istDayKey(fallback);
  }
  if (endDate < startDate) {
    const swap = startDate;
    startDate = endDate;
    endDate = swap;
  }

  const main = functions[0];
  const payload: EventOSPayload = {
    schemaVersion: EVENTOS_SCHEMA_VERSION,
    source: EVENTOS_SOURCE,
    enquiryId,
    sourceUpdatedAt: resolveSourceUpdatedAt(enquiry),
    status,
    customer: {
      name: optionalText(enquiry.customerName, 200) ?? optionalText(enquiry.name, 200) ?? "Unknown",
      phone: formatEventOSPhone(enquiry.customerPhone ?? enquiry.phone ?? enquiry.phoneNormalized),
      email: optionalText(enquiry.customerEmail, 254) ?? optionalText(enquiry.email, 254),
    },
    event: {
      eventType: nonEmptyEventType(
        main?.eventType ?? enquiry.eventTypeValue ?? enquiry.eventType,
      ),
      eventTypeLabel:
        optionalText(main?.eventTypeLabel, 200) ??
        optionalText(enquiry.eventTypeLabel, 200) ??
        optionalText(enquiry.eventType, 200),
      startDate,
      endDate,
      guestCount: resolveGuestCount(enquiry),
      notes:
        optionalText(enquiry.notes, 8000) ??
        optionalText(enquiry.eventNotes, 8000) ??
        optionalText(enquiry.message, 8000),
      assigneeName:
        optionalText(enquiry.assignedToName, 200) ?? optionalText(enquiry.assigneeName, 200),
    },
    functions: functionPayloads,
  };

  const money = resolveMoney(financial);
  if (money) payload.money = money;
  return payload;
}

/** Deterministic JSON for hashing (sorted object keys; arrays keep order). */
export function stableStringify(value: unknown): string {
  if (value === null || typeof value !== "object") return JSON.stringify(value);
  if (Array.isArray(value)) {
    return `[${value.map((v) => stableStringify(v)).join(",")}]`;
  }
  const obj = value as Record<string, unknown>;
  const keys = Object.keys(obj).sort();
  return `{${keys.map((k) => `${JSON.stringify(k)}:${stableStringify(obj[k])}`).join(",")}}`;
}

/** SHA-256 hex of the payload excluding `sourceUpdatedAt` (ordering-only field). */
export function hashEventOSPayload(payload: EventOSPayload): string {
  const { sourceUpdatedAt: _omit, ...rest } = payload;
  return createHash("sha256").update(stableStringify(rest)).digest("hex");
}

export type ShouldSendInput = {
  status: CanonicalStatus | string;
  previouslySynced: boolean;
  lastHash: string | null | undefined;
  nextHash: string;
};

/**
 * Send when approved/completed, or when previously synced and the hash changed
 * (covers cancellations and other post-sync edits). Never send never-approved
 * first sightings.
 */
export function shouldSendToEventOS(input: ShouldSendInput): boolean {
  if (input.lastHash && input.lastHash === input.nextHash) return false;
  const status = canonicalStatus(input.status) ?? String(input.status);
  if (status === "approved" || status === "completed") return true;
  if (input.previouslySynced) return true;
  return false;
}
