"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
exports.onEnquiryUpdate = exports.onEnquiryCreate = exports.deactivateUser = exports.approveUser = exports.onUserWrite = exports.onAuthCreate = void 0;
const admin = __importStar(require("firebase-admin"));
const functions = __importStar(require("firebase-functions"));
const firestore_1 = require("firebase-functions/v2/firestore");
const firestore_2 = require("firebase-admin/firestore");
admin.initializeApp();
const db = admin.firestore();
const ADMIN_EMAIL = process.env.ADMIN_EMAIL || 'ilyas@wedecorevents.com';
const FCM_TOPIC_PREFIX = process.env.FCM_TOPIC_PREFIX || 'wedecor';
function roleTopic(role, prefix = FCM_TOPIC_PREFIX) {
    return `${prefix}-role-${role}`;
}
function userTopic(uid, prefix = FCM_TOPIC_PREFIX) {
    return `${prefix}-user-${uid}`;
}
async function getSettings() {
    const doc = await db.collection('SystemSettings').doc('app').get();
    return doc.exists ? doc.data() : { fcmTopicPrefix: FCM_TOPIC_PREFIX, financeVisibleToAssignee: true };
}
async function notifyTopic(topic, title, body, data) {
    try {
        await admin.messaging().sendToTopic(topic, {
            notification: { title, body },
            data: { ...data, topic },
        });
    }
    catch (e) {
        console.error('Notify topic error:', e);
    }
}
exports.onAuthCreate = functions.auth.user().onCreate(async (user) => {
    const uid = user.uid;
    const userDoc = db.collection('users').doc(uid);
    const now = firestore_2.FieldValue.serverTimestamp();
    // Check if this is an admin user (email ends with @wedecor.com and contains 'admin')
    const isAdmin = user.email?.includes('admin') && user.email?.endsWith('@wedecor.com');
    await userDoc.set({
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
    }, { merge: true });
    // Notify admins of new signup
    const settings = await getSettings();
    const fcmTopicPrefix = settings?.fcmTopicPrefix || FCM_TOPIC_PREFIX;
    await notifyTopic(roleTopic('admin', fcmTopicPrefix), 'New signup awaiting approval', user.email || uid, { type: 'new_signup', uid });
});
exports.onUserWrite = functions.firestore
    .document('users/{uid}')
    .onWrite(async (change, context) => {
    const after = change.after.exists ? change.after.data() : null;
    const before = change.before.exists ? change.before.data() : null;
    if (!after || !before)
        return;
    // On role change, manage topic subscriptions based on fcmTokens
    if (after.role !== before.role) {
        const tokens = Array.isArray(after.fcmTokens) ? after.fcmTokens : [];
        const prevTokens = Array.isArray(before.fcmTokens) ? before.fcmTokens : [];
        const toUnsub = prevTokens;
        const toSub = tokens;
        const settings = await getSettings();
        const fcmTopicPrefix = settings?.fcmTopicPrefix || FCM_TOPIC_PREFIX;
        try {
            if (toUnsub.length)
                await admin.messaging().unsubscribeFromTopic(toUnsub, roleTopic(before.role, fcmTopicPrefix));
            if (toSub.length)
                await admin.messaging().subscribeToTopic(toSub, roleTopic(after.role, fcmTopicPrefix));
        }
        catch (e) {
            console.error('Topic subscription error', e);
        }
    }
});
exports.approveUser = functions.https.onCall(async (data, context) => {
    if (!context.auth)
        throw new functions.https.HttpsError('unauthenticated', 'Auth required');
    const callerClaims = context.auth.token;
    if (callerClaims.role !== 'admin')
        throw new functions.https.HttpsError('permission-denied', 'Admin only');
    const uid = data?.uid;
    const role = data?.role;
    if (!uid || !['admin', 'partner', 'staff'].includes(role)) {
        throw new functions.https.HttpsError('invalid-argument', 'uid and role required');
    }
    await admin.auth().setCustomUserClaims(uid, { role, isApproved: true, isActive: true });
    const now = firestore_2.FieldValue.serverTimestamp();
    await db.collection('users').doc(uid).set({
        role,
        isApproved: true,
        isActive: true,
        updatedAt: now,
    }, { merge: true });
    // Notify the user via topic
    const settings = await getSettings();
    const fcmTopicPrefix = settings?.fcmTopicPrefix || FCM_TOPIC_PREFIX;
    await notifyTopic(roleTopic(role, fcmTopicPrefix), 'Account approved', 'Your access is now active', { type: 'account_approved', uid });
    return { ok: true };
});
exports.deactivateUser = functions.https.onCall(async (data, context) => {
    if (!context.auth)
        throw new functions.https.HttpsError('unauthenticated', 'Auth required');
    const callerClaims = context.auth.token;
    if (callerClaims.role !== 'admin')
        throw new functions.https.HttpsError('permission-denied', 'Admin only');
    const uid = data?.uid;
    if (!uid)
        throw new functions.https.HttpsError('invalid-argument', 'uid required');
    await admin.auth().setCustomUserClaims(uid, { role: 'pending', isApproved: false, isActive: false });
    const now = firestore_2.FieldValue.serverTimestamp();
    await db.collection('users').doc(uid).set({ isApproved: false, isActive: false, updatedAt: now }, { merge: true });
    return { ok: true };
});
exports.onEnquiryCreate = (0, firestore_1.onDocumentCreated)("enquiries/{id}", async (event) => {
    const after = event.data?.data();
    if (!after)
        return;
    const ref = event.data.ref;
    const now = firestore_2.FieldValue.serverTimestamp();
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
    await notifyTopic(roleTopic("partner", fcmTopicPrefix), `New Enquiry: ${after.customerName ?? ""}`, `${after.eventTypeLabel ?? ""} • ${new Date((after.eventDate?.toDate?.() ?? new Date())).toDateString()} • ${after.locationText ?? ""}`, { type: "enquiry_create", enquiryId: ref.id });
});
exports.onEnquiryUpdate = (0, firestore_1.onDocumentUpdated)("enquiries/{id}", async (event) => {
    const before = event.data?.before.data() || {};
    const after = event.data?.after.data() || {};
    const ref = event.data.after.ref;
    const now = firestore_2.FieldValue.serverTimestamp();
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
