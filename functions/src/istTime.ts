/** IST (Asia/Kolkata) calendar-day helpers. India has no DST: offset is fixed at UTC+05:30. */

export const IST_TIME_ZONE = "Asia/Kolkata";
export const IST_OFFSET_MS = (5 * 60 + 30) * 60 * 1000;

const istDateFormatter = new Intl.DateTimeFormat("en-CA", {
  timeZone: IST_TIME_ZONE,
  year: "numeric",
  month: "2-digit",
  day: "2-digit",
});

/** UTC instant of 00:00 IST on the IST calendar day that contains [date]. */
export function istDayStart(date: Date): Date {
  const parts = istDateFormatter.formatToParts(date);
  const part = (type: Intl.DateTimeFormatPartTypes) =>
    Number(parts.find((p) => p.type === type)?.value);
  return new Date(Date.UTC(part("year"), part("month") - 1, part("day")) - IST_OFFSET_MS);
}

/** "12 Oct" style label for an instant, in IST. */
export function istShortDate(date: Date): string {
  return new Intl.DateTimeFormat("en-IN", {
    timeZone: IST_TIME_ZONE,
    day: "numeric",
    month: "short",
  }).format(date);
}
