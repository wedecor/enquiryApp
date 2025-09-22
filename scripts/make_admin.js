// Quick script to make current user admin
// Run with: node scripts/make_admin.js YOUR_UID

const admin = require('firebase-admin');

// Initialize Firebase Admin
if (!admin.apps.length) {
  admin.initializeApp({
    credential: admin.credential.applicationDefault(),
    projectId: 'wedecorenquries'
  });
}

const db = admin.firestore();

async function makeAdmin(uid) {
  try {
    await db.collection('users').doc(uid).update({
      role: 'admin',
      updatedAt: admin.firestore.FieldValue.serverTimestamp()
    });
    console.log(`✅ User ${uid} is now an admin!`);
  } catch (error) {
    console.error('❌ Error:', error.message);
  }
}

const uid = process.argv[2];
if (!uid) {
  console.log('Usage: node scripts/make_admin.js YOUR_UID');
  console.log('To find your UID, check Firebase Console > Authentication > Users');
  process.exit(1);
}

makeAdmin(uid);






