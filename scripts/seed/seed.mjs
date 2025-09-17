import { initializeApp, cert } from 'firebase-admin/app';
import { getAuth } from 'firebase-admin/auth';
import { getFirestore, Timestamp } from 'firebase-admin/firestore';
import fs from 'node:fs';
import path from 'node:path';

const KEY_FILE = process.env.GOOGLE_APPLICATION_CREDENTIALS || './serviceAccountKey.json';
const keyPath = path.isAbsolute(KEY_FILE) ? KEY_FILE : path.resolve(process.cwd(), KEY_FILE);
if (!fs.existsSync(keyPath)) {
  console.error(`Missing service account key at: ${keyPath}
- Firebase Console → Project settings → Service accounts → "Generate new private key"
- Save as ./serviceAccountKey.json (gitignored) OR set GOOGLE_APPLICATION_CREDENTIALS to its absolute path.`);
  process.exit(1);
}

initializeApp({ credential: cert(keyPath) });
const auth = getAuth();
const db = getFirestore();

// --- Admin bootstrap (change password after first login) ---
const ADMIN_EMAIL = 'admin@wedecorevents.com';
const ADMIN_PASSWORD = 'admin12';

// --- Dropdown data ---
const EVENT_TYPES = [
  { label: 'Birthday', value: 'birthday', order: 1 },
  { label: 'Anniversary', value: 'anniversary', order: 2 },
  { label: 'Haldi', value: 'haldi', order: 3 },
  { label: 'Mehendi', value: 'mehendi', order: 4 },
  { label: 'Sangeet', value: 'sangeet', order: 5 },
  { label: 'Wedding', value: 'wedding', order: 6 },
  { label: 'Reception', value: 'reception', order: 7 },
  { label: 'Engagement', value: 'engagement', order: 8 },
  { label: 'Proposal', value: 'proposal', order: 9 },
  { label: 'Baby Shower', value: 'baby_shower', order: 10 },
  { label: 'Naming Ceremony', value: 'naming_ceremony', order: 11 },
  { label: 'Housewarming', value: 'housewarming', order: 12 },
  { label: 'Corporate Event', value: 'corporate', order: 13 },
  { label: 'Romantic Surprise', value: 'romantic_surprise', order: 14 }
];

const STATUSES = [
  { label: 'New', value: 'new', order: 1 },
  { label: 'Contacted', value: 'contacted', order: 2 },
  { label: 'In Progress', value: 'in_progress', order: 3 },
  { label: 'Quote Sent', value: 'quote_sent', order: 4 },
  { label: 'Approved', value: 'approved', order: 5 },
  { label: 'Scheduled', value: 'scheduled', order: 6 },
  { label: 'Completed', value: 'completed', order: 7 },
  { label: 'Closed - Lost', value: 'closed_lost', order: 8 },
  { label: 'Cancelled', value: 'cancelled', order: 9 }
];

const PAYMENT_STATUSES = [
  { label: 'Unpaid', value: 'unpaid', order: 1 },
  { label: 'Advance Paid', value: 'advance_paid', order: 2 },
  { label: 'Partially Paid', value: 'partially_paid', order: 3 },
  { label: 'Paid', value: 'paid', order: 4 },
  { label: 'Refunded', value: 'refunded', order: 5 }
];

async function ensureAdminUser() {
  let user;
  try {
    user = await auth.getUserByEmail(ADMIN_EMAIL);
    console.log(`Admin user exists: ${user.uid}`);
  } catch {
    console.log('Creating admin user…');
    user = await auth.createUser({
      email: ADMIN_EMAIL,
      password: ADMIN_PASSWORD,
      displayName: 'We Decor Admin',
      emailVerified: true,
      disabled: false
    });
    console.log(`Created admin user: ${user.uid}`);
  }

  await auth.setCustomUserClaims(user.uid, { admin: true });
  console.log('Custom claim set: { admin: true }');

  const now = Timestamp.now();
  await db.collection('users').doc(user.uid).set({
    name: 'We Decor Admin',
    email: ADMIN_EMAIL,
    role: 'admin',
    isActive: true,
    updatedAt: now
  }, { merge: true });

  console.log('Firestore users/{uid} upserted.');
  return user.uid;
}

async function upsertDropdown(category, items) {
  const catRef = db.collection('dropdowns').doc(category);
  await catRef.set({ updatedAt: Timestamp.now() }, { merge: true });

  const batch = db.batch();
  const now = Timestamp.now();
  for (const it of items) {
    const ref = catRef.collection('items').doc(it.value);
    batch.set(ref, { ...it, active: true, updatedAt: now }, { merge: true });
  }
  await batch.commit();
  console.log(`Dropdown "${category}" populated (${items.length} items).`);
}

async function main() {
  let adminUid = null;
  try {
    adminUid = await ensureAdminUser();
  } catch (e) {
    const msg = (e && (e.code || e.message)) ? `${e.code || ''} ${e.message || ''}` : String(e);
    if (msg.includes('auth/configuration-not-found')) {
      console.warn('⚠️ Firebase Auth not initialized yet. Skipping admin creation for now.');
    } else {
      throw e;
    }
  }
  await upsertDropdown('event_types', EVENT_TYPES);
  await upsertDropdown('statuses', STATUSES);
  await upsertDropdown('payment_statuses', PAYMENT_STATUSES);

  // Read-back counts (sanity)
  const counts = {};
  for (const cat of ['event_types', 'statuses', 'payment_statuses']) {
    const snap = await db.collection('dropdowns').doc(cat).collection('items').count().get();
    counts[cat] = snap.data().count;
  }
  console.log('✅ Seeding complete.', { adminUid, counts });
}

main().then(() => process.exit(0)).catch(err => {
  console.error(err);
  process.exit(1);
});


