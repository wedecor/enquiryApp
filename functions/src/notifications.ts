import { logger } from "firebase-functions/v2";
import { onCall, HttpsError } from "firebase-functions/v2/https";
import { getFirestore, FieldValue } from "firebase-admin/firestore";
import { canonicalStatus, statusLabel } from "./statusVocabulary";
import { notificationExpireAt } from "./notificationTtl";
import { isActiveUserData } from "./auth";

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

/** Callable core, exported for tests. */
export async function handleNotifyEnquiryEvent(
  db: FirebaseFirestore.Firestore,
  callerUid: string | undefined,
  input: NotifyEnquiryEventRequest,
  now: Date = new Date(),
): Promise<NotifyEnquiryEventResult> {
  if (!callerUid) {
    throw new HttpsError("unauthenticated", "Must be signed in");
  }
  const enquiryId = str(input.enquiryId);
  if (!enquiryId || enquiryId.length > 200 || enquiryId.includes("/")) {
    throw new HttpsError("invalid-argument", "enquiryId is required");
  }
  if (typeof input.event !== "string" || !EVENT_KINDS.has(input.event)) {
    throw new HttpsError("invalid-argument", "event must be created, assigned, status_changed or updated");
  }
  const event = input.event as EnquiryEventKind;
  if (input.oldStatus !== undefined && input.oldStatus !== null && typeof input.oldStatus !== "string") {
    throw new HttpsError("invalid-argument", "oldStatus must be a string");
  }

  const [callerSnap, enquirySnap] = await Promise.all([
    db.collection("users").doc(callerUid).get(),
    db.collection("enquiries").doc(enquiryId).get(),
  ]);
  const actor = toActiveUser(callerSnap);
  if (!actor) {
    throw new HttpsError("permission-denied", "Active account required");
  }
  if (!enquirySnap.exists) {
    throw new HttpsError("not-found", "Enquiry not found");
  }
  const enquiry = enquirySnap.data() ?? {};
  if (!canAnnounce(event, actor, enquiry)) {
    throw new HttpsError("permission-denied", "Not allowed to announce this enquiry");
  }
  if (!isRecentEvent(event, enquiry, now)) {
    logger.info("notifyEnquiryEvent: stale event ignored", { enquiryId, event, by: callerUid });
    return { queued: 0, skipped: "stale" };
  }

  const assigneeUid = str(enquiry.assignedTo);
  const [adminSnap, assigneeSnap] = await Promise.all([
    db.collection("users").where("role", "==", "admin").get(),
    assigneeUid ? db.collection("users").doc(assigneeUid).get() : Promise.resolve(null),
  ]);
  const admins = adminSnap.docs.map(toActiveUser).filter((u): u is ActiveUser => u !== null && u.role === "admin");
  const assignee = assigneeSnap ? toActiveUser(assigneeSnap) : null;

  const planned = planEnquiryNotifications({
    event,
    actorUid: callerUid,
    enquiryId,
    enquiry,
    admins,
    assignee,
    oldStatus: typeof input.oldStatus === "string" ? input.oldStatus : null,
    notifyAdmins: boolOr(input.notifyAdmins, true),
    notifyAssignee: boolOr(input.notifyAssignee, true),
  });
  if (planned.length === 0) return { queued: 0 };

  const notificationId = eventNotificationId(event, enquiryId, callerUid, enquiry, now);
  let queued = 0;
  await Promise.all(
    planned.map(async (n) => {
      try {
        await db.collection("users").doc(n.uid).collection("notifications").doc(notificationId).create({
          title: n.title,
          body: n.body,
          type: n.type,
          enquiryId,
          data: n.data,
          read: false,
          createdBy: callerUid,
          createdAt: FieldValue.serverTimestamp(),
          expireAt: notificationExpireAt(now),
        });
        queued += 1;
      } catch (error: any) {
        // gRPC 6 = ALREADY_EXISTS: same event already announced (client retry).
        if (error?.code !== 6) throw error;
      }
    }),
  );
  logger.info("notifyEnquiryEvent", { enquiryId, event, by: callerUid, queued });
  return { queued };
}

export const notifyEnquiryEvent = onCall<NotifyEnquiryEventRequest, Promise<NotifyEnquiryEventResult>>(
  { cors: true, region: "asia-south1", enforceAppCheck: false },
  async (request) => handleNotifyEnquiryEvent(getFirestore(), request.auth?.uid, request.data ?? {}),
);
