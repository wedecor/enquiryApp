// Usage:
//   export GOOGLE_APPLICATION_CREDENTIALS="$PWD/serviceAccountKey.json"
//   export ADMIN_UID="your_uid"
//   node scripts/smoke_notify.mjs

import { initializeApp, applicationDefault } from 'firebase-admin/app';
import { getFirestore, FieldValue } from 'firebase-admin/firestore';

if (!process.env.GOOGLE_APPLICATION_CREDENTIALS) {
  console.error('❌ Set GOOGLE_APPLICATION_CREDENTIALS to your serviceAccountKey.json');
  process.exit(1);
}
if (!process.env.ADMIN_UID) {
  console.error('❌ Set ADMIN_UID to the uid that should receive the push');
  process.exit(1);
}

initializeApp({ credential: applicationDefault() });
const db = getFirestore();

const uid = process.env.ADMIN_UID;
const ref = db.collection('enquiries').doc();
await ref.set({
  assignedTo: uid,
  customerName: 'Test Customer',
  eventStatus: 'new',
  paymentStatus: 'pending',
  createdAt: FieldValue.serverTimestamp(),
});
console.log('✅ Created test enquiry:', ref.id);

await new Promise(r => setTimeout(r, 2000));

await ref.update({
  eventStatus: 'in_progress',
  paymentStatus: 'paid',
  updatedAt: FieldValue.serverTimestamp(),
});
console.log('🔔 Updated enquiry to trigger notification');
