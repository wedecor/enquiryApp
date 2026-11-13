import { logger } from "firebase-functions/v2";
import { onDocumentWritten } from "firebase-functions/v2/firestore";
import { onCall, HttpsError } from "firebase-functions/v2/https";
import { getFirestore, FieldValue } from "firebase-admin/firestore";
import { canonicalStatus, statusLabel } from "./statusVocabulary";
import { notificationExpireAt } from "./notificationTtl";
import { isActiveUserData } from "./auth";
import { WEBSITE_LEAD_CREATED_BY } from "./websiteLeads";

/**
 * Trusted enquiry notifications (create / assign / status change / edit).
 *
 * The app used to write users/{uid}/notifications itself, so any active user could
 * push any text to any colleague. Clients may no longer create those documents
 * (firestore.rules); they call `notifyEnquiryEvent` instead. The server checks that
 * the caller may act on the enquiry, picks the recipients from the enquiry and the
 * users collection, and builds the title and body from stored data. The client only
 * supplies the enquiry id, the kind of event and the previous status.
 *
 * Recipient rules and wording mirror the old NotificationService so existing flows
 * stay the same; sendNotificationToUser still turns each document into a push.
 */

export type EnquiryEventKind = "created" | "assigned" | "status_changed" | "updated";
const EVENT_KINDS: ReadonlySet<string> = new Set(["created", "assigned", "status_changed", "updated"]);

/** A notification must follow a real, recent write to the enquiry. */
export const MAX_EVENT_AGE_MS = 15 * 60 * 1000;
/** Same event by the same actor within this window → one notification (client retries). */
export const DEDUPE_WINDOW_MS = 30 * 1000;

const MAX_TITLE = 120;
const MAX_BODY = 500;

export type NotifyEnquiryEventRequest = {
  enquiryId?: unknown;
  event?: unknown;
  /** Previous status value (status_changed only). Canonicalised; unknown values are dropped. */
  oldStatus?: unknown;
  /** Default true. False when the same save already told every admin. */
  notifyAdmins?: unknown;
  /** Default true. False when the assignee gets a separate "Assigned to You" push. */
  notifyAssignee?: unknown;
};

export type ActiveUser = { uid: string; name: string; role: "admin" | "staff" };

export type PlannedNotification = {
  uid: string;
  title: string;
  body: string;
  type: string;
  data: Record<string, string>;
};

export type PlanInput = {
  event: EnquiryEventKind;
  actorUid: string;
  enquiryId: string;
  enquiry: FirebaseFirestore.DocumentData;
  /** Active admins (any order). */
  admins: readonly ActiveUser[];
  /** The enquiry's current assignee if that user is active, else null. */
  assignee: ActiveUser | null;
  oldStatus: string | null;
  notifyAdmins: boolean;
  notifyAssignee: boolean;
};

function truncate(value: string, max: number): string {
  return value.length <= max ? value : `${value.slice(0, max - 1)}…`;
}

function str(raw: unknown): string | null {
  return typeof raw === "string" && raw.trim() ? raw.trim() : null;
}

function toDate(raw: unknown): Date | null {
  if (raw instanceof Date) return raw;
  if (raw && typeof (raw as { toDate?: unknown }).toDate === "function") {
    return (raw as { toDate: () => Date }).toDate();
  }
  return null;
}

function eventTypeLabelOf(data: FirebaseFirestore.DocumentData): string {
  const label = str(data.eventTypeLabel);
  if (label) return label;
  const value = str(data.eventTypeValue) ?? str(data.eventType);
  if (!value) return "Event";
  return value
    .replace(/_/g, " ")
    .split(" ")
    .filter(Boolean)
    .map((w) => w[0].toUpperCase() + w.slice(1))
    .join(" ");
}

function statusText(raw: unknown): string {
  const canonical = canonicalStatus(raw);
  return canonical ? statusLabel(canonical) : "Unknown";
}

/**
 * Whether [actor] may announce [event] on [enquiry]. Mirrors the enquiry rules:
 * only admins create and assign; admins or the assignee change status and edit.
 */
export function canAnnounce(
  event: EnquiryEventKind,
  actor: ActiveUser,
  enquiry: FirebaseFirestore.DocumentData,
): boolean {
  if (actor.role === "admin") return true;
  if (event === "created" || event === "assigned") return false;
  return str(enquiry.assignedTo) === actor.uid;
}

/** True when the enquiry was written recently enough to match [event]. */
export function isRecentEvent(
  event: EnquiryEventKind,
  enquiry: FirebaseFirestore.DocumentData,
  now: Date,
): boolean {
  const stamp =
    event === "created"
      ? toDate(enquiry.createdAt)
      : event === "status_changed"
        ? toDate(enquiry.statusUpdatedAt) ?? toDate(enquiry.updatedAt)
        : toDate(enquiry.updatedAt);
  if (!stamp) return false;
  const age = now.getTime() - stamp.getTime();
  // Small negative ages come from clock skew between server timestamp and now.
  return age <= MAX_EVENT_AGE_MS && age >= -60 * 1000;
}

/** Recipients and content for one enquiry event. Pure — no Firestore access. */
export function planEnquiryNotifications(input: PlanInput): PlannedNotification[] {
  const { event, actorUid, enquiryId, enquiry, admins, assignee } = input;
  const customerName = str(enquiry.customerName) ?? "Unknown Customer";
  const eventType = eventTypeLabelOf(enquiry);
  const out: PlannedNotification[] = [];
  const add = (uid: string, title: string, body: string, type: string, data: Record<string, string>) => {
    if (out.some((n) => n.uid === uid)) return;
    out.push({
      uid,
      title: truncate(title, MAX_TITLE),
      body: truncate(body, MAX_BODY),
      type,
      data: { type, enquiryId, ...data },
    });
  };
  const otherAdmins = admins.filter((a) => a.uid !== actorUid);

  switch (event) {
    case "created": {
      for (const admin of otherAdmins) {
        add(admin.uid, "New Enquiry Created", `New enquiry from ${customerName} for ${eventType}`, "new_enquiry", {
          customerName,
          eventType,
          createdBy: actorUid,
        });
      }
      break;
    }
    case "assigned": {
      if (!assignee) break;
      if (input.notifyAssignee && assignee.uid !== actorUid) {
        add(
          assignee.uid,
          "Enquiry Assigned to You",
          `You have been assigned an enquiry from ${customerName} for ${eventType}`,
          "enquiry_assigned",
          { customerName, eventType, assignedBy: actorUid },
        );
      }
      if (input.notifyAdmins) {
        for (const admin of otherAdmins) {
          if (admin.uid === assignee.uid) continue;
          add(admin.uid, "Enquiry Assigned", `Enquiry from ${customerName} assigned to ${assignee.name}`, "enquiry_assigned", {
            customerName,
            assignedTo: assignee.uid,
            assignedBy: actorUid,
          });
        }
      }
      break;
    }
    case "status_changed": {
      const newStatus = canonicalStatus(enquiry.statusValue);
      const oldStatus = canonicalStatus(input.oldStatus);
      if (!newStatus || oldStatus === newStatus) break;
      const oldText = oldStatus ? statusLabel(oldStatus) : "Unknown";
      const newText = statusText(enquiry.statusValue);
      const body = `Status changed from ${oldText} to ${newText} for ${customerName}`;
      const data = { customerName, oldStatus: oldText, newStatus: newText, updatedBy: actorUid };
      if (input.notifyAdmins) {
        for (const admin of otherAdmins) add(admin.uid, "Enquiry Status Updated", body, "status_update", data);
      }
      if (input.notifyAssignee && assignee && assignee.uid !== actorUid) {
        add(assignee.uid, "Enquiry Status Updated", body, "status_update", data);
      }
      break;
    }
    case "updated": {
      const body = `Enquiry from ${customerName} for ${eventType} has been updated`;
      const data = { customerName, eventType, updatedBy: actorUid };
      if (input.notifyAdmins) {
        for (const admin of otherAdmins) add(admin.uid, "Enquiry Updated", body, "enquiry_updated", data);
      }
      if (input.notifyAssignee && assignee && assignee.uid !== actorUid) {
        add(assignee.uid, "Enquiry Updated", body, "enquiry_updated", data);
      }
      break;
    }
  }
  return out;
}

/** Deterministic notification id: a retried call inside the window writes nothing new. */
export function eventNotificationId(
  event: EnquiryEventKind,
  enquiryId: string,
  actorUid: string,
  enquiry: FirebaseFirestore.DocumentData,
  now: Date,
): string {
  const bucket = Math.floor(now.getTime() / DEDUPE_WINDOW_MS);
  const detail =
    event === "status_changed"
      ? canonicalStatus(enquiry.statusValue) ?? "unknown"
      : event === "assigned"
        ? str(enquiry.assignedTo) ?? "none"
        : "x";
  return `ev_${enquiryId}_${event}_${detail}_${actorUid}_${bucket}`.slice(0, 1400);
}

function toActiveUser(snap: FirebaseFirestore.DocumentSnapshot): ActiveUser | null {
  if (!snap.exists) return null;
  const data = snap.data();
  if (!isActiveUserData(data)) return null;
  const role = data?.role;
  if (role !== "admin" && role !== "staff") return null;
  return {
    uid: snap.id,
    name: str(data?.name) ?? str(data?.email) ?? "a teammate",
    role,
  };
}

function boolOr(raw: unknown, fallback: boolean): boolean {
  return typeof raw === "boolean" ? raw : fallback;
}

export type NotifyEnquiryEventResult = { queued: number; skipped?: string };

const USER_FACING_FIELDS = [
  "customerName",
  "customerPhone",
  "customerEmail",
  "eventDate",
  "eventType",
  "eventTypeValue",
  "eventTypeLabel",
  "eventLocation",
  "location",
  "eventCity",
  "eventFunctions",
  "guestCount",
  "notes",
  "description",
  "budgetRange",
  "priority",
  "priorityValue",
  "priorityLabel",
] as const;

function normalizeCompareValue(v: unknown): unknown {
  if (v === undefined || v === null) return null;
  if (v instanceof Date) return v.getTime();
  if (typeof (v as { toMillis?: unknown }).toMillis === "function") {
    return (v as { toMillis: () => number }).toMillis();
  }
  if (Array.isArray(v)) return v.map(normalizeCompareValue);
  if (typeof v === "object") {
    const obj = v as Record<string, unknown>;
    const sorted: Record<string, unknown> = {};
    for (const k of Object.keys(obj).sort()) {
      sorted[k] = normalizeCompareValue(obj[k]);
    }
    return sorted;
  }
  return v;
}

function valuesEqual(a: unknown, b: unknown): boolean {
  return JSON.stringify(normalizeCompareValue(a)) === JSON.stringify(normalizeCompareValue(b));
}

function triggerActorUid(data: FirebaseFirestore.DocumentData, event: EnquiryEventKind): string {
  const raw =
    event === "status_changed"
      ? str(data.statusUpdatedBy) ?? str(data.updatedBy) ?? str(data.createdBy)
      : event === "created"
        ? str(data.createdBy)
        : str(data.updatedBy) ?? str(data.createdBy);
  if (!raw || raw === "system" || raw.startsWith("system:")) return "";
  return raw;
}

export type DerivedEnquiryEvent = {
  event: EnquiryEventKind;
  actorUid: string;
  oldStatus?: string | null;
  notifyAdmins: boolean;
  notifyAssignee: boolean;
};

/**
 * Pure before/after → notification event mapping for `enquiries/{id}` writes.
 * Emits `assigned` to the new assignee and at most one of `status_changed` /
 * `updated` to everyone else. Server-only field writes produce nothing.
 */
export function deriveEnquiryNotificationEvents(
  before: FirebaseFirestore.DocumentData | undefined,
  after: FirebaseFirestore.DocumentData | undefined,
): DerivedEnquiryEvent[] {
  if (!after) return [];

  if (!before) {
    if (str(after.createdBy) === WEBSITE_LEAD_CREATED_BY) return [];
    const actorUid = triggerActorUid(after, "created");
    const out: DerivedEnquiryEvent[] = [
      { event: "created", actorUid, notifyAdmins: true, notifyAssignee: false },
    ];
    if (str(after.assignedTo)) {
      out.push({ event: "assigned", actorUid, notifyAdmins: false, notifyAssignee: true });
    }
    return out;
  }

  const beforeAssignee = str(before.assignedTo);
  const afterAssignee = str(after.assignedTo);
  const assignedChanged = afterAssignee !== null && afterAssignee !== beforeAssignee;

  const beforeStatus = canonicalStatus(before.statusValue);
  const afterStatus = canonicalStatus(after.statusValue);
  const statusChanged = afterStatus !== null && beforeStatus !== afterStatus;

  const userChanged = !statusChanged && USER_FACING_FIELDS.some((f) => !valuesEqual(before[f], after[f]));

  if (!assignedChanged && !statusChanged && !userChanged) return [];

  const actorForOther = triggerActorUid(after, "updated");
  if (assignedChanged && !statusChanged && !userChanged) {
    return [{ event: "assigned", actorUid: actorForOther, notifyAdmins: true, notifyAssignee: true }];
  }

  const out: DerivedEnquiryEvent[] = [];
  if (assignedChanged) {
    out.push({ event: "assigned", actorUid: actorForOther, notifyAdmins: false, notifyAssignee: true });
  }
  if (statusChanged) {
    out.push({
      event: "status_changed",
      actorUid: triggerActorUid(after, "status_changed"),
      oldStatus: typeof before.statusValue === "string" ? before.statusValue : null,
      notifyAdmins: true,
      notifyAssignee: !assignedChanged,
    });
  } else if (userChanged) {
    out.push({
      event: "updated",
      actorUid: actorForOther,
      notifyAdmins: true,
      notifyAssignee: !assignedChanged,
    });
  }
  return out;
}

/** Trigger core, exported for emulator tests. */
export async function handleEnquiryWrittenNotify(
  db: FirebaseFirestore.Firestore,
  enquiryId: string,
  eventId: string,
  before: FirebaseFirestore.DocumentData | undefined,
  after: FirebaseFirestore.DocumentData | undefined,
  now: Date = new Date(),
): Promise<number> {
  const derived = deriveEnquiryNotificationEvents(before, after);
  if (derived.length === 0 || !after) return 0;

  const assigneeUid = str(after.assignedTo);
  const [adminSnap, assigneeSnap] = await Promise.all([
    db.collection("users").where("role", "==", "admin").get(),
    assigneeUid ? db.collection("users").doc(assigneeUid).get() : Promise.resolve(null),
  ]);
  const admins = adminSnap.docs.map(toActiveUser).filter((u): u is ActiveUser => u !== null && u.role === "admin");
  const assignee = assigneeSnap ? toActiveUser(assigneeSnap) : null;

  const seenUids = new Set<string>();
  const toSend: Array<PlannedNotification & { event: EnquiryEventKind; actorUid: string }> = [];

  for (const d of derived) {
    const planned = planEnquiryNotifications({
      event: d.event,
      actorUid: d.actorUid,
      enquiryId,
      enquiry: after,
      admins,
      assignee,
      oldStatus: d.oldStatus ?? null,
      notifyAdmins: d.notifyAdmins,
      notifyAssignee: d.notifyAssignee,
    });
    for (const item of planned) {
      if (seenUids.has(item.uid)) continue;
      seenUids.add(item.uid);
      toSend.push({ ...item, event: d.event, actorUid: d.actorUid });
    }
  }

  if (toSend.length === 0) return 0;

  let queued = 0;
  await Promise.all(
    toSend.map(async (n) => {
      const notificationId = `ev_${enquiryId}_${n.event}_${eventId}`.slice(0, 1400);
      try {
        await db.collection("users").doc(n.uid).collection("notifications").doc(notificationId).create({
          title: n.title,
          body: n.body,
          type: n.type,
          enquiryId,
          data: n.data,
          read: false,
          createdBy: n.actorUid || "system",
          createdAt: FieldValue.serverTimestamp(),
          expireAt: notificationExpireAt(now),
        });
        queued += 1;
      } catch (error: any) {
        if (error?.code !== 6) throw error;
      }
    }),
  );

  logger.info("onEnquiryWrittenNotify", { enquiryId, eventId, queued });
  return queued;
}

export const onEnquiryWrittenNotify = onDocumentWritten(
  { document: "enquiries/{id}", region: "asia-south1" },
  async (event) => {
    const enquiryId = event.params.id;
    const before = event.data?.before.exists ? event.data.before.data() : undefined;
    const after = event.data?.after.exists ? event.data.after.data() : undefined;
    await handleEnquiryWrittenNotify(getFirestore(), enquiryId, event.id, before, after);
  },
);

/**
 * Legacy callable retained for old app builds; notifications now come from
 * `onEnquiryWrittenNotify` so nothing is written here.
 */
export async function handleNotifyEnquiryEvent(
  _db: FirebaseFirestore.Firestore,
  _callerUid: string | undefined,
  _input: NotifyEnquiryEventRequest,
  _now: Date = new Date(),
): Promise<NotifyEnquiryEventResult> {
  return { queued: 0, skipped: "server" };
}

export const notifyEnquiryEvent = onCall<NotifyEnquiryEventRequest, Promise<NotifyEnquiryEventResult>>(
  { cors: true, region: "asia-south1", enforceAppCheck: false },
  async () => ({ queued: 0, skipped: "server" }),
);
