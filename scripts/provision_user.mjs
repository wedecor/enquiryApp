#!/usr/bin/env node
/**
 * Create or update Firestore users/{uid} for an existing Firebase Auth account.
 *
 * Requires serviceAccountKey.json in project root OR GOOGLE_APPLICATION_CREDENTIALS.
 *
 * Usage:
 *   node scripts/provision_user.mjs ilyas.prime@gmail.com admin
 *   node scripts/provision_user.mjs user@example.com staff "Display Name"
 */
import admin from 'firebase-admin';
import { existsSync } from 'fs';
import { resolve } from 'path';

const projectId = 'wedecorenquries';
const keyPath = process.env.GOOGLE_APPLICATION_CREDENTIALS
  ?? resolve(process.cwd(), 'serviceAccountKey.json');

if (!admin.apps.length) {
  if (!existsSync(keyPath)) {
    console.error(`❌ Service account key not found: ${keyPath}`);
    console.error('   Download from Firebase Console → Project settings → Service accounts');
    console.error('   Save as serviceAccountKey.json or set GOOGLE_APPLICATION_CREDENTIALS');
    process.exit(1);
  }
  admin.initializeApp({
    credential: admin.credential.cert(keyPath),
    projectId,
  });
}

const email = process.argv[2];
const role = (process.argv[3] ?? 'staff').toLowerCase();
const name = process.argv[4] ?? email.split('@')[0];

if (!email?.includes('@')) {
  console.error('Usage: node scripts/provision_user.mjs <email> [admin|staff] [displayName]');
  process.exit(1);
}

if (role !== 'admin' && role !== 'staff') {
  console.error('Role must be admin or staff');
  process.exit(1);
}

const auth = admin.auth();
const db = admin.firestore();

const user = await auth.getUserByEmail(email);
const ref = db.collection('users').doc(user.uid);
const snap = await ref.get();

const payload = {
  uid: user.uid,
  name,
  email,
  phone: snap.data()?.phone ?? 'N/A',
  role,
  active: true,
  updatedAt: admin.firestore.FieldValue.serverTimestamp(),
};

if (!snap.exists) {
  payload.createdAt = admin.firestore.FieldValue.serverTimestamp();
  await ref.set(payload);
  console.log(`✅ Created users/${user.uid} for ${email} (${role})`);
} else {
  await ref.update(payload);
  console.log(`✅ Updated users/${user.uid} for ${email} (${role})`);
}

await db.collection('userRoles').doc(user.uid).set(
  {
    uid: user.uid,
    role,
    assignedAt: admin.firestore.FieldValue.serverTimestamp(),
  },
  { merge: true },
);

console.log('   Sign out and sign in again in the app.');
