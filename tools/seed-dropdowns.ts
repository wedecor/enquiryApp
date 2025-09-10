#!/usr/bin/env -S node --env-file
import admin from 'firebase-admin';

if (!admin.apps.length) {
  admin.initializeApp({
    projectId: 'wedecorenquiries',
  });
}

async function main() {
  const db = admin.firestore();
  const statuses = [
    { value: 'enquired', label: 'Enquired', order: 1, isActive: true },
    { value: 'in_talks', label: 'In Talks', order: 2, isActive: true },
    { value: 'confirmed', label: 'Confirmed', order: 3, isActive: true },
    { value: 'completed', label: 'Completed', order: 4, isActive: true },
    { value: 'not_interested', label: 'Not Interested', order: 99, isActive: true },
  ];

  await db.collection('dropdowns').doc('statuses').set({ items: statuses }, { merge: true });
  console.log('Seeded dropdowns.statuses');
}

main().catch((e) => { console.error(e); process.exit(1); });
