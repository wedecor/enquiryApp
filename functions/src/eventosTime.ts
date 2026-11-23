/**
 * Pure wall-clock normaliser for the EventOS feed (HH:mm 24 h).
 * Accepts common Firestore time strings; never throws.
 */

const TWELVE_HOUR =
  /^\s*(\d{1,2})(?::(\d{2}))?(?::(\d{2}))?\s*(AM|PM)\s*$/i;
const TWENTY_FOUR_HOUR = /^\s*(\d{1,2}):(\d{2})(?::(\d{2}))?\s*$/;

function pad2(n: number): string {
  return n < 10 ? `0${n}` : String(n);
}

/**
 * Normalise a stored enquiry function time to `"HH:mm"` (24 h).
 * Returns null for empty / missing / unparseable input.
 *
 * Accepted examples: `"18:30"`, `"18:30:00"`, `"6:30 PM"`, `"6:30pm"`,
 * `"06:30 PM"`, `"6 PM"`, `"12:00 AM"`, `"12:30 PM"`.
 */
export function normalizeEventOSWallClockTime(raw: unknown): string | null {
  if (raw == null) return null;
  if (typeof raw !== "string") return null;
  const trimmed = raw.trim();
  if (!trimmed) return null;

  const twelve = TWELVE_HOUR.exec(trimmed);
  if (twelve) {
    let hour = Number(twelve[1]);
    const minute = Number(twelve[2] ?? "0");
    const meridiem = twelve[4].toUpperCase();
    if (!Number.isInteger(hour) || hour < 1 || hour > 12) return null;
    if (!Number.isInteger(minute) || minute < 0 || minute > 59) return null;
    if (meridiem === "AM") {
      if (hour === 12) hour = 0;
    } else if (hour !== 12) {
      hour += 12;
    }
    return `${pad2(hour)}:${pad2(minute)}`;
  }

  const twentyFour = TWENTY_FOUR_HOUR.exec(trimmed);
  if (twentyFour) {
    const hour = Number(twentyFour[1]);
    const minute = Number(twentyFour[2]);
    if (!Number.isInteger(hour) || hour < 0 || hour > 23) return null;
    if (!Number.isInteger(minute) || minute < 0 || minute > 59) return null;
    return `${pad2(hour)}:${pad2(minute)}`;
  }

  return null;
}
