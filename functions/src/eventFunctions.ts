/**
 * Multi-function bookings (Haldi, Mehendi, Wedding, Reception… on their own days).
 *
 * Pure helpers — no Firebase imports — so they are reused by bookings.ts,
 * occasionStamping.ts, reengagement.ts and the backfill migration.
 *
 * Mirrors lib/features/enquiries/domain/event_functions.dart (functionsOf,
 * mainFunctionOf). Keep the two in sync.
 *
 * Data model: enquiry field `functions` = array of
 *   { id, eventType, eventTypeLabel, date (Timestamp, local midnight), time?, location?,
 *     locationArea?, locationPlaceId?, locationAddress?, notes? }
 * Absent / empty `functions` = legacy single-event enquiry: ONE function is
 * synthesized from the top-level eventType / eventTypeLabel / eventDate /
 * eventLocation / locationArea. When functions are saved the app keeps the
 * top-level fields in sync (eventDate = LAST function date, eventStartDate =
 * FIRST, eventType = main function, location = main function's).
 */

import { IST_OFFSET_MS } from "./istTime";
import { isWeddingAnchor } from "./reengagementLogic";

export type EventFunction = {
  id: string;
  eventType: string;
  eventTypeLabel: string | null;
  date: Date;
  time: string | null;
  location: string | null;
  locationArea: string | null;
  locationPlaceId: string | null;
  locationAddress: string | null;
  notes: string | null;
};

function toDate(raw: unknown): Date | null {
  if (raw instanceof Date) return Number.isNaN(raw.getTime()) ? null : raw;
  if (raw && typeof (raw as { toDate?: unknown }).toDate === "function") {
    return (raw as { toDate: () => Date }).toDate();
  }
  return null;
}

function str(raw: unknown): string | null {
  return typeof raw === "string" && raw.trim() ? raw.trim() : null;
}

/** `YYYY-MM-DD` of the IST calendar day containing [date]. */
export function istDayKey(date: Date): string {
  const ist = new Date(date.getTime() + IST_OFFSET_MS);
  const pad = (n: number) => (n < 10 ? `0${n}` : `${n}`);
  return `${ist.getUTCFullYear()}-${pad(ist.getUTCMonth() + 1)}-${pad(ist.getUTCDate())}`;
}

function compareFunctions(a: EventFunction, b: EventFunction): number {
  const byDay = istDayKey(a.date).localeCompare(istDayKey(b.date));
  if (byDay !== 0) return byDay;
  return (a.time ?? "").localeCompare(b.time ?? "");
}

function functionFromMap(raw: unknown, index: number): EventFunction | null {
  if (!raw || typeof raw !== "object") return null;
  const m = raw as Record<string, unknown>;
  const date = toDate(m.date);
  const eventType = str(m.eventType);
  if (!date || !eventType) return null;
  return {
    id: str(m.id) ?? `f${index}`,
    eventType,
    eventTypeLabel: str(m.eventTypeLabel),
    date,
    time: str(m.time),
    location: str(m.location),
    locationArea: str(m.locationArea),
    locationPlaceId: str(m.locationPlaceId),
    locationAddress: str(m.locationAddress),
    notes: str(m.notes),
  };
}

/**
 * The booking's functions, ordered by (IST) date then time. Legacy docs give ONE
 * function built from the top-level fields; a legacy doc without an event date
 * gives none.
 */
export function eventFunctionsOf(data: Record<string, unknown>): EventFunction[] {
  const raw = data.functions;
  if (Array.isArray(raw) && raw.length > 0) {
    const parsed = raw
      .map((r, i) => functionFromMap(r, i))
      .filter((f): f is EventFunction => f !== null);
    if (parsed.length > 0) return parsed.sort(compareFunctions);
  }
  const date = toDate(data.eventDate);
  if (!date) return [];
  return [
    {
      id: "main",
      eventType: str(data.eventTypeValue) ?? str(data.eventType) ?? "event",
      eventTypeLabel: str(data.eventTypeLabel),
      date,
      time: null,
      location: str(data.eventLocation) ?? str(data.location),
      locationArea: str(data.locationArea),
      locationPlaceId: str(data.locationPlaceId),
      locationAddress: str(data.locationAddress),
      notes: null,
    },
  ];
}

/** First wedding-anchor function (wedding / marriage / nikah / shaadi / muhurtham), else the first. */
export function mainFunctionOf(functions: readonly EventFunction[]): EventFunction | null {
  if (functions.length === 0) return null;
  return functions.find((f) => isWeddingAnchor(f.eventType, f.eventTypeLabel)) ?? functions[0];
}

/** Functions whose IST calendar day is [dayKey] (`YYYY-MM-DD`). */
export function functionsOnIstDay(data: Record<string, unknown>, dayKey: string): EventFunction[] {
  return eventFunctionsOf(data).filter((f) => istDayKey(f.date) === dayKey);
}

/**
 * Event type + date used for yearly occasion stamping: the MAIN function's type
 * (wedding anchor when present) and its date. Falls back to the top-level
 * fields when the doc has no dated function.
 */
export function occasionEventOf(data: Record<string, unknown>): {
  eventTypeValue: string | null;
  eventTypeLabel: string | null;
  eventDate: Date | null;
} {
  const main = mainFunctionOf(eventFunctionsOf(data));
  if (main) {
    return { eventTypeValue: main.eventType, eventTypeLabel: main.eventTypeLabel, eventDate: main.date };
  }
  return {
    eventTypeValue: str(data.eventTypeValue) ?? str(data.eventType),
    eventTypeLabel: str(data.eventTypeLabel),
    eventDate: toDate(data.eventDate),
  };
}

/** "Haldi" — label, else the title-cased type value. */
export function functionLabel(f: EventFunction): string {
  if (f.eventTypeLabel) return f.eventTypeLabel;
  return f.eventType
    .replace(/_/g, " ")
    .split(" ")
    .filter(Boolean)
    .map((w) => w[0].toUpperCase() + w.slice(1))
    .join(" ");
}
