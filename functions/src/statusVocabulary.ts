/**
 * Canonical enquiry status vocabulary for Cloud Functions.
 * Must stay in sync with lib/core/constants/status_vocabulary.dart.
 */

export const STATUS_LABELS = {
  new: "New",
  in_talks: "In Talks",
  approved: "Approved",
  completed: "Completed",
  not_interested: "Not Interested",
  closed_lost: "Closed Lost",
  cancelled: "Cancelled",
} as const;

export type CanonicalStatus = keyof typeof STATUS_LABELS;

/** Legacy Firestore values → canonical slug (tolerant reads). */
export const LEGACY_STATUS_ALIASES: Readonly<Record<string, CanonicalStatus>> = {
  contacted: "in_talks",
  quote_sent: "in_talks",
  quoted: "in_talks",
  in_progress: "in_talks",
  assigned: "in_talks",
  confirmed: "approved",
  scheduled: "approved",
  enquired: "new",
  not_intrested: "not_interested",
};

/** Resolves a raw Firestore status (incl. legacy aliases) to canonical, or null if unknown. */
export function canonicalStatus(raw: unknown): CanonicalStatus | null {
  if (typeof raw !== "string" || !raw.trim()) return null;
  const normalized = raw.trim().toLowerCase().replace(/ /g, "_");
  const aliased = Object.hasOwn(LEGACY_STATUS_ALIASES, normalized)
    ? LEGACY_STATUS_ALIASES[normalized]
    : normalized;
  return Object.hasOwn(STATUS_LABELS, aliased) ? (aliased as CanonicalStatus) : null;
}

export function statusLabel(status: CanonicalStatus): string {
  return STATUS_LABELS[status];
}

/** Canonical value plus every legacy alias that resolves to it (for `in` queries). */
export function rawStatusValuesFor(status: CanonicalStatus): string[] {
  const aliases = Object.entries(LEGACY_STATUS_ALIASES)
    .filter(([, canonical]) => canonical === status)
    .map(([alias]) => alias);
  return [status, ...aliases];
}
