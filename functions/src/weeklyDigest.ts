import { logger } from "firebase-functions/v2";
import { onSchedule } from "firebase-functions/v2/scheduler";
import { getFirestore } from "firebase-admin/firestore";
import { createEmailTransporter, getSmtpFromAddress, SMTP_SECRET_NAMES } from "./smtp";
import { canonicalStatus, type CanonicalStatus } from "./statusVocabulary";
import { IST_TIME_ZONE, istDayStart, istShortDate } from "./istTime";

const DAY_MS = 24 * 60 * 60 * 1000;

const LOST_REASON_LABELS: Record<string, string> = {
  price_too_high: "Price too high",
  booked_other_vendor: "Booked another vendor",
  date_unavailable: "Date not available",
  no_response: "No response",
  event_cancelled: "Event cancelled / postponed",
  out_of_scope: "Not something we do",
  other: "Other",
};

type Row = Record<string, unknown> & { id: string };

function toDate(raw: unknown): Date | null {
  if (raw instanceof Date) return raw;
  if (raw && typeof (raw as { toDate?: unknown }).toDate === "function") {
    return (raw as { toDate: () => Date }).toDate();
  }
  return null;
}

function num(raw: unknown): number {
  return typeof raw === "number" && Number.isFinite(raw) ? raw : 0;
}

const WON: CanonicalStatus[] = ["approved", "completed"];
const LOST: CanonicalStatus[] = ["not_interested", "closed_lost", "cancelled"];

function statusOf(row: Row): CanonicalStatus | null {
  return canonicalStatus(row.statusValue);
}

function isOpen(row: Row): boolean {
  const s = statusOf(row);
  return s === null || s === "new" || s === "in_talks";
}

function money(v: number): string {
  if (v >= 100000) return `₹${(v / 100000).toFixed(1)}L`;
  if (v >= 1000) return `₹${(v / 1000).toFixed(1)}K`;
  return `₹${Math.round(v)}`;
}

function hours(ms: number): string {
  const h = ms / 3600000;
  if (h < 1) return `${Math.round(ms / 60000)}m`;
  if (h < 48) return `${h.toFixed(h < 10 ? 1 : 0)}h`;
  return `${(h / 24).toFixed(1)}d`;
}

function median(values: number[]): number | null {
  if (values.length === 0) return null;
  const sorted = [...values].sort((a, b) => a - b);
  const mid = Math.floor(sorted.length / 2);
  return sorted.length % 2 ? sorted[mid] : (sorted[mid - 1] + sorted[mid]) / 2;
}

function escapeHtml(s: string): string {
  return s.replace(/[&<>"']/g, (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" })[c]!);
}

export interface DigestData {
  newCount: number;
  contacted24hShare: number | null;
  won: number;
  lost: number;
  topLostReasons: Array<{ label: string; count: number }>;
  bookedValue: number;
  medianResponseMs: number | null;
  stale: Array<{ name: string; assignee: string; days: number }>;
  upcoming: Array<{ date: string; name: string; eventType: string; balance: number }>;
}

/**
 * Pure digest computation (exported for testing). [names] maps uid → display name.
 * Last 7 days = [todayStart − 7d, todayStart) in IST.
 */
export function computeDigest(rows: Row[], now: Date, names: Map<string, string>): DigestData {
  const todayStart = istDayStart(now);
  const weekStart = new Date(todayStart.getTime() - 7 * DAY_MS);
  const in14 = new Date(todayStart.getTime() + 14 * DAY_MS);
  const inWeek = (d: Date | null) => !!d && d >= weekStart && d < todayStart;

  const created = rows.filter((r) => inWeek(toDate(r.createdAt)));
  const responses: number[] = [];
  let contactedWithin24h = 0;
  for (const r of created) {
    const c = toDate(r.createdAt);
    const f = toDate(r.firstContactAt);
    if (c && f && r.firstContactEstimated !== true) {
      const ms = Math.max(0, f.getTime() - c.getTime());
      responses.push(ms);
      if (ms <= DAY_MS) contactedWithin24h++;
    }
  }

  // Wins / losses decided this week (by the stage timestamp, else status update time).
  const decidedAt = (r: Row, field: string) =>
    toDate(r[field]) ?? toDate(r.statusUpdatedAt);
  const wonRows = rows.filter((r) => {
    const s = statusOf(r);
    return s !== null && WON.includes(s) && inWeek(decidedAt(r, "approvedAt"));
  });
  const lostRows = rows.filter((r) => {
    const s = statusOf(r);
    return s !== null && LOST.includes(s) && inWeek(decidedAt(r, "lostAt"));
  });

  const reasonCounts = new Map<string, number>();
  for (const r of lostRows) {
    const key = typeof r.lostReason === "string" && r.lostReason ? r.lostReason : "not_recorded";
    reasonCounts.set(key, (reasonCounts.get(key) ?? 0) + 1);
  }
  const topLostReasons = [...reasonCounts.entries()]
    .sort((a, b) => b[1] - a[1])
    .slice(0, 3)
    .map(([key, count]) => ({ label: LOST_REASON_LABELS[key] ?? "Not recorded", count }));

  const stale = rows
    .filter(isOpen)
    .map((r) => {
      const last = toDate(r.lastContactAt) ?? toDate(r.createdAt);
      return { r, days: last ? Math.floor((now.getTime() - last.getTime()) / DAY_MS) : 0 };
    })
    .filter((x) => x.days >= 7)
    .sort((a, b) => b.days - a.days)
    .slice(0, 10)
    .map(({ r, days }) => ({
      name: String(r.customerName ?? "Customer"),
      assignee:
        typeof r.assignedTo === "string" && r.assignedTo
          ? names.get(r.assignedTo) ?? "Unknown"
          : "Unassigned",
      days,
    }));

  const upcoming = rows
    .filter((r) => {
      const s = statusOf(r);
      const e = toDate(r.eventDate);
      return s !== null && !LOST.includes(s) && !!e && e >= todayStart && e < in14;
    })
    .sort((a, b) => toDate(a.eventDate)!.getTime() - toDate(b.eventDate)!.getTime())
    .map((r) => ({
      date: istShortDate(toDate(r.eventDate)!),
      name: String(r.customerName ?? "Customer"),
      eventType: String(r.eventTypeLabel ?? r.eventTypeValue ?? r.eventType ?? ""),
      balance: Math.max(0, num(r.totalCost) - num(r.advancePaid)),
    }));

  return {
    newCount: created.length,
    contacted24hShare: created.length ? contactedWithin24h / created.length : null,
    won: wonRows.length,
    lost: lostRows.length,
    topLostReasons,
    bookedValue: wonRows.reduce((sum, r) => sum + num(r.totalCost), 0),
    medianResponseMs: median(responses),
    stale,
    upcoming,
  };
}

export function renderDigestHtml(d: DigestData, weekLabel: string): string {
  const td = 'style="padding:6px 10px;border-top:1px solid #e4dfd3;font-size:14px"';
  const th = 'style="padding:6px 10px;text-align:left;font-size:11px;letter-spacing:1px;color:#5f6368;text-transform:uppercase"';
  const kpi = (label: string, value: string) =>
    `<tr><td ${td}>${escapeHtml(label)}</td><td ${td} align="right"><b>${escapeHtml(value)}</b></td></tr>`;
  const reasons = d.topLostReasons.length
    ? d.topLostReasons.map((r) => `${escapeHtml(r.label)} (${r.count})`).join(", ")
    : "—";

  const staleRows = d.stale.length
    ? d.stale
        .map((s) => `<tr><td ${td}>${escapeHtml(s.name)}</td><td ${td}>${escapeHtml(s.assignee)}</td><td ${td} align="right">${s.days}</td></tr>`)
        .join("")
    : `<tr><td ${td} colspan="3">Nothing overdue — nice.</td></tr>`;

  const upcomingRows = d.upcoming.length
    ? d.upcoming
        .map((u) => `<tr><td ${td}>${escapeHtml(u.date)}</td><td ${td}>${escapeHtml(u.name)}</td><td ${td}>${escapeHtml(u.eventType)}</td><td ${td} align="right">${u.balance > 0 ? money(u.balance) : "—"}</td></tr>`)
        .join("")
    : `<tr><td ${td} colspan="4">No events in the next 14 days.</td></tr>`;

  return `<!doctype html><html><body style="font-family:-apple-system,Segoe UI,Helvetica,Arial,sans-serif;color:#1f2124;background:#f7f4ec;margin:0;padding:24px">
<div style="max-width:620px;margin:0 auto;background:#fff;border:1px solid #e4dfd3;border-radius:8px;padding:24px">
<div style="font-size:11px;letter-spacing:2px;color:#7a5c22;text-transform:uppercase">We Decor · Weekly digest</div>
<h2 style="margin:6px 0 16px;font-size:20px">${escapeHtml(weekLabel)}</h2>
<table width="100%" cellspacing="0" cellpadding="0">
${kpi("New enquiries", String(d.newCount))}
${kpi("Contacted within 24h", d.contacted24hShare === null ? "—" : `${Math.round(d.contacted24hShare * 100)}%`)}
${kpi("Median response time", d.medianResponseMs === null ? "—" : hours(d.medianResponseMs))}
${kpi("Won", String(d.won))}
${kpi("Booked value (won this week)", money(d.bookedValue))}
${kpi("Lost", String(d.lost))}
${kpi("Top lost reasons", reasons)}
</table>
<h3 style="margin:24px 0 8px;font-size:16px">Not contacted for 7+ days</h3>
<table width="100%" cellspacing="0" cellpadding="0"><tr><th ${th}>Customer</th><th ${th}>Assignee</th><th ${th} style="text-align:right">Days</th></tr>${staleRows}</table>
<h3 style="margin:24px 0 8px;font-size:16px">Events in the next 14 days</h3>
<table width="100%" cellspacing="0" cellpadding="0"><tr><th ${th}>Date</th><th ${th}>Customer</th><th ${th}>Event</th><th ${th} style="text-align:right">Balance due</th></tr>${upcomingRows}</table>
<p style="margin-top:24px;font-size:12px;color:#5f6368">Turn this email off in the app: Settings → Notifications → Weekly Digest.</p>
</div></body></html>`;
}

/** Monday 08:52 IST: emails each active admin (who hasn't opted out) last week's numbers. */
export const weeklyDigest = onSchedule(
  {
    schedule: "52 8 * * 1",
    timeZone: IST_TIME_ZONE,
    retryCount: 0,
    secrets: [...SMTP_SECRET_NAMES],
  },
  async () => {
    const transporter = createEmailTransporter();
    if (!transporter) {
      logger.warn("weeklyDigest: SMTP not configured — skipping");
      return;
    }

    const db = getFirestore();
    const [enquiriesSnap, usersSnap] = await Promise.all([
      db.collection("enquiries").get(),
      db.collection("users").get(),
    ]);

    const names = new Map<string, string>();
    const admins: Array<{ uid: string; email: string }> = [];
    for (const doc of usersSnap.docs) {
      const u = doc.data();
      names.set(doc.id, String(u.name ?? u.email ?? "Unknown"));
      const active = (u.isActive ?? u.active ?? true) === true;
      if (u.role === "admin" && active && typeof u.email === "string" && u.email) {
        admins.push({ uid: doc.id, email: u.email });
      }
    }

    const rows: Row[] = enquiriesSnap.docs.map((d) => ({ id: d.id, ...d.data() }));
    const now = new Date();
    const digest = computeDigest(rows, now, names);
    const todayStart = istDayStart(now);
    const weekLabel = `${istShortDate(new Date(todayStart.getTime() - 7 * DAY_MS))} – ${istShortDate(new Date(todayStart.getTime() - DAY_MS))}`;
    const html = renderDigestHtml(digest, weekLabel);

    let sent = 0;
    for (const admin of admins) {
      const prefs = await db.doc(`users/${admin.uid}/settings/preferences`).get();
      if (prefs.exists && prefs.get("weeklyDigest") === false) continue;
      try {
        await transporter.sendMail({
          from: getSmtpFromAddress(),
          to: admin.email,
          subject: `We Decor weekly digest · ${weekLabel}`,
          html,
        });
        sent++;
      } catch (error) {
        logger.error("weeklyDigest: send failed", { uid: admin.uid, error: String(error) });
      }
    }
    logger.info("weeklyDigest: done", { admins: admins.length, sent, newCount: digest.newCount });
  }
);
