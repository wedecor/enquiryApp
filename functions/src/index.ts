import * as admin from 'firebase-admin';
import * as functions from 'firebase-functions';
import { onDocumentCreated, onDocumentUpdated } from 'firebase-functions/v2/firestore';
import { FieldValue } from 'firebase-admin/firestore';

admin.initializeApp();
const db = admin.firestore();

const ADMIN_EMAIL = process.env.ADMIN_EMAIL || 'ilyas@wedecorevents.com';
const FCM_TOPIC_PREFIX = process.env.FCM_TOPIC_PREFIX || 'wedecor';

function roleTopic(role: string, prefix: string = FCM_TOPIC_PREFIX) {
  return `${prefix}-role-${role}`;
}

function userTopic(uid: string, prefix: string = FCM_TOPIC_PREFIX) {
  return `${prefix}-user-${uid}`;
}

async function getSettings() {
  const doc = await db.collection('SystemSettings').doc('app').get();
  return doc.exists ? doc.data() : { fcmTopicPrefix: FCM_TOPIC_PREFIX, financeVisibleToAssignee: true };
}

async function notifyTopic(topic: string, title: string, body: string, data: any) {
  try {
    await admin.messaging().sendToTopic(topic, {
      notification: { title, body },
      data: { ...data, topic },
    });
  } catch (e) {
    console.error('Notify topic error:', e);
  }
}

export const onAuthCreate = functions.auth.user().onCreate(async (user) => {
  const uid = user.uid;
  const userDoc = db.collection('users').doc(uid);
  const now = FieldValue.serverTimestamp();
  
  // Check if this is an admin user (email ends with @wedecor.com and contains 'admin')
  const isAdmin = user.email?.includes('admin') && user.email?.endsWith('@wedecor.com');
  
  console.log(`🔐 Creating user document for: ${user.email}`);
  console.log(`👑 Is admin: ${isAdmin}`);
  console.log(`📧 Email: ${user.email}`);
  
  const userData = {
    uid,
    email: user.email,
    displayName: user.displayName ?? null,
    phone: user.phoneNumber ?? null,
    role: isAdmin ? 'admin' : 'pending',
    isApproved: isAdmin,
    isActive: isAdmin,
    fcmTokens: [],
    createdAt: now,
    updatedAt: now,
  };
  
  console.log(`📝 User data to save:`, JSON.stringify(userData, null, 2));
  
  await userDoc.set(userData, { merge: true });
  
  console.log(`✅ User document created successfully for: ${user.email}`);

  // Skip notification for now to avoid messaging errors
  try {
    const settings = await getSettings();
    const fcmTopicPrefix = settings?.fcmTopicPrefix || FCM_TOPIC_PREFIX;
    await notifyTopic(
      roleTopic('admin', fcmTopicPrefix),
      'New signup awaiting approval',
      user.email || uid,
      { type: 'new_signup', uid }
    );
  } catch (error) {
    console.log(`⚠️ Notification failed (expected in emulator): ${error}`);
  }
});

// Temporary debug function to read user document
export const debugGetUser = functions.https.onCall(async (data, context) => {
  const { uid } = data;
  if (!uid) {
    throw new functions.https.HttpsError('invalid-argument', 'UID is required');
  }
  
  const userDoc = await db.collection('users').doc(uid).get();
  if (!userDoc.exists) {
    return { exists: false };
  }
  
  return { exists: true, data: userDoc.data() };
});

export const onUserWrite = functions.firestore
  .document('users/{uid}')
  .onWrite(async (change, context) => {
    const after = change.after.exists ? change.after.data() : null;
    const before = change.before.exists ? change.before.data() : null;
    if (!after || !before) return;

    // On role change, manage topic subscriptions based on fcmTokens
    if (after.role !== before.role) {
      const tokens: string[] = Array.isArray(after.fcmTokens) ? after.fcmTokens : [];
      const prevTokens: string[] = Array.isArray(before.fcmTokens) ? before.fcmTokens : [];
      const toUnsub = prevTokens;
      const toSub = tokens;
      const settings = await getSettings();
      const fcmTopicPrefix = settings?.fcmTopicPrefix || FCM_TOPIC_PREFIX;
      
      try {
        if (toUnsub.length) await admin.messaging().unsubscribeFromTopic(toUnsub, roleTopic(before.role, fcmTopicPrefix));
        if (toSub.length) await admin.messaging().subscribeToTopic(toSub, roleTopic(after.role, fcmTopicPrefix));
      } catch (e) {
        console.error('Topic subscription error', e);
      }
    }
  });

export const approveUser = functions.https.onCall(async (data, context) => {
  if (!context.auth) throw new functions.https.HttpsError('unauthenticated', 'Auth required');
  const callerClaims = context.auth.token as any;
  if (callerClaims.role !== 'admin') throw new functions.https.HttpsError('permission-denied', 'Admin only');

  const uid: string = data?.uid;
  const role: string = data?.role;
  if (!uid || !['admin', 'partner', 'staff'].includes(role)) {
    throw new functions.https.HttpsError('invalid-argument', 'uid and role required');
  }

  await admin.auth().setCustomUserClaims(uid, { role, isApproved: true, isActive: true });
  const now = FieldValue.serverTimestamp();
  await db.collection('users').doc(uid).set({
    role,
    isApproved: true,
    isActive: true,
    updatedAt: now,
  }, { merge: true });

  // Notify the user via topic
  const settings = await getSettings();
  const fcmTopicPrefix = settings?.fcmTopicPrefix || FCM_TOPIC_PREFIX;
  await notifyTopic(
    roleTopic(role, fcmTopicPrefix),
    'Account approved',
    'Your access is now active',
    { type: 'account_approved', uid }
  );

  return { ok: true };
});

export const deactivateUser = functions.https.onCall(async (data, context) => {
  if (!context.auth) throw new functions.https.HttpsError('unauthenticated', 'Auth required');
  const callerClaims = context.auth.token as any;
  if (callerClaims.role !== 'admin') throw new functions.https.HttpsError('permission-denied', 'Admin only');
  const uid: string = data?.uid;
  if (!uid) throw new functions.https.HttpsError('invalid-argument', 'uid required');

  await admin.auth().setCustomUserClaims(uid, { role: 'pending', isApproved: false, isActive: false });
  const now = FieldValue.serverTimestamp();
  await db.collection('users').doc(uid).set({ isApproved: false, isActive: false, updatedAt: now }, { merge: true });
  return { ok: true };
});

export const onEnquiryCreate = onDocumentCreated("enquiries/{id}", async (event) => {
  const after = event.data?.data();
  if (!after) return;
  const ref = event.data!.ref;

  const now = FieldValue.serverTimestamp();

  // derive balance
  const p = after.payment || {};
  const total = Number(p.totalAmount || 0);
  const advance = Number(p.advanceAmount || 0);
  const expected = Math.max(0, total - advance);

  await ref.set({ createdAt: now, updatedAt: now, "payment.balance": expected }, { merge: true });

  await ref.collection("EnquiryHistory").add({
    action: "create",
    actorUid: after.createdByUid ?? null,
    at: now,
    diff: { after },
  });

  const settings = await getSettings();
  const fcmTopicPrefix = settings?.fcmTopicPrefix || FCM_TOPIC_PREFIX;
  await notifyTopic(
    roleTopic("partner", fcmTopicPrefix),
    `New Enquiry: ${after.customerName ?? ""}`,
    `${after.eventTypeLabel ?? ""} • ${new Date((after.eventDate?.toDate?.() ?? new Date())).toDateString()} • ${after.locationText ?? ""}`,
    { type: "enquiry_create", enquiryId: ref.id }
  );
});

export const onEnquiryUpdate = onDocumentUpdated("enquiries/{id}", async (event) => {
  const before = event.data?.before.data() || {};
  const after  = event.data?.after.data()  || {};
  const ref = event.data!.after.ref;

  const now = FieldValue.serverTimestamp();
  await ref.set({ updatedAt: now }, { merge: true });

  // write history
  await ref.collection("EnquiryHistory").add({
    action: "update",
    actorUid: after.updatedByUid ?? null,
    at: now,
    diff: { before, after },
  });

  const settings = await getSettings();
  const fcmTopicPrefix = settings?.fcmTopicPrefix || FCM_TOPIC_PREFIX;

  // notify on assignment change
  if (before.assignedToUid !== after.assignedToUid && after.assignedToUid) {
    const assigneeUid = String(after.assignedToUid);
    await notifyTopic(userTopic(assigneeUid, fcmTopicPrefix), "New assignment", `You were assigned: ${after.customerName ?? ""}`, {
      type: "assignment",
      enquiryId: ref.id,
    });
    await notifyTopic(roleTopic("partner", fcmTopicPrefix), "Enquiry assigned", `Assigned to ${assigneeUid}`, {
      type: "assignment",
      enquiryId: ref.id,
    });
  }

  // simple update notifications
  await notifyTopic(roleTopic("partner", fcmTopicPrefix), "Enquiry updated", `${after.customerName ?? ""} • ${after.status ?? ""}`, {
    type: "enquiry_update",
    enquiryId: ref.id,
  });
  await notifyTopic(roleTopic("admin", fcmTopicPrefix), "Enquiry updated", `${after.customerName ?? ""} • ${after.status ?? ""}`, {
    type: "enquiry_update",
    enquiryId: ref.id,
  });

  // confirmedAt when moving to confirmed
  if (before.status !== "confirmed" && after.status === "confirmed") {
    await ref.set({ "payment.confirmedAt": now }, { merge: true });
  }

  // enforce balance derivation
  const p = after.payment || {};
  const total = Number(p.totalAmount || 0);
  const advance = Number(p.advanceAmount || 0);
  const expected = Math.max(0, total - advance);
  if (Number(p.balance || 0) !== expected) {
    await ref.set({ "payment.balance": expected }, { merge: true });
  }
});