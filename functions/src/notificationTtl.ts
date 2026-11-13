import { Timestamp } from "firebase-admin/firestore";

/** Notifications expire 30 days after creation (Firestore TTL on `expireAt`). */
export const NOTIFICATION_TTL_DAYS = 30;
export const NOTIFICATION_TTL_MS = NOTIFICATION_TTL_DAYS * 24 * 60 * 60 * 1000;

export function notificationExpireAt(now: Date = new Date()): Timestamp {
  return Timestamp.fromMillis(now.getTime() + NOTIFICATION_TTL_MS);
}
