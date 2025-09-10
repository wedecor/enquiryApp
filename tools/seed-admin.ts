#!/usr/bin/env -S node --env-file
import admin from 'firebase-admin';

// Initialize for emulator
if (!admin.apps.length) {
  admin.initializeApp({
    projectId: 'wedecorenquiries',
  });
}

const email = 'ilyas@wedecorevents.com';
const password = 'Wedecorevents';

async function main() {
  const auth = admin.auth();
  const db = admin.firestore();

  // Create admin user
  let user;
  try {
    user = await auth.getUserByEmail(email);
  } catch (e) {
    user = await auth.createUser({ email, password, emailVerified: true, disabled: false });
  }

  await auth.setCustomUserClaims(user.uid, { role: 'admin', isApproved: true, isActive: true });
  const now = admin.firestore.FieldValue.serverTimestamp();
  await db.collection('users').doc(user.uid).set({
    uid: user.uid,
    email,
    role: 'admin',
    isApproved: true,
    isActive: true,
    fcmTokens: [],
    createdAt: now,
    updatedAt: now,
  }, { merge: true });

  // Seed StatusOptions
  const statuses = [
    { id: 'enquired', label: 'Enquired', active: true },
    { id: 'in_talks', label: 'In Talks', active: true },
    { id: 'confirmed', label: 'Confirmed', active: true },
    { id: 'not_interested', label: 'Not Interested', active: true },
    { id: 'completed', label: 'Completed', active: true },
  ];

  for (const status of statuses) {
    await db.collection('StatusOptions').doc(status.id).set(status, { merge: true });
  }

  // Seed EventTypeOptions
  const eventTypes = [
    { id: 'wedding', label: 'Wedding', active: true },
    { id: 'corporate', label: 'Corporate Event', active: true },
    { id: 'birthday', label: 'Birthday Party', active: true },
    { id: 'anniversary', label: 'Anniversary', active: true },
    { id: 'other', label: 'Other', active: true },
  ];

  for (const eventType of eventTypes) {
    await db.collection('EventTypeOptions').doc(eventType.id).set(eventType, { merge: true });
  }

  // Seed SystemSettings
  await db.collection('SystemSettings').doc('app').set({
    financeVisibleToAssignee: true,
    fcmTopicPrefix: 'wedecor',
  }, { merge: true });

  console.log('Seeded admin:', email, user.uid);
  console.log('Seeded StatusOptions:', statuses.length);
  console.log('Seeded EventTypeOptions:', eventTypes.length);
  console.log('Seeded SystemSettings');
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});