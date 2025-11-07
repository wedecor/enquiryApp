// Script to update admin user email to the correct one
import admin from 'firebase-admin';

// Initialize Firebase Admin
if (!admin.apps.length) {
  admin.initializeApp({
    credential: admin.credential.applicationDefault(),
    projectId: 'wedecorenquries'
  });
}

const db = admin.firestore();

async function updateAdminEmail() {
  try {
    const currentUid = 'SstmjrY2bkbG3vv1ufeWUU0rMgl1';
    const newEmail = 'admin@wedecorevents.com';
    
    console.log('🔧 Updating admin user email...');
    console.log(`📧 New Email: ${newEmail}`);
    
    // Update Firestore user document
    await db.collection('users').doc(currentUid).update({
      email: newEmail,
      updatedAt: admin.firestore.FieldValue.serverTimestamp()
    });
    
    console.log('✅ Firestore user document updated');
    
    // Verify the update
    const userDoc = await db.collection('users').doc(currentUid).get();
    const userDocData = userDoc.data();
    
    console.log('\n📋 Updated admin user:');
    console.log(`   🆔 UID: ${currentUid}`);
    console.log(`   👤 Name: ${userDocData.name}`);
    console.log(`   📧 Email: ${userDocData.email}`);
    console.log(`   🎭 Role: ${userDocData.role}`);
    console.log(`   ✅ Active: ${userDocData.active}`);
    
    console.log('\n🎯 Login Instructions:');
    console.log(`   📧 Email: ${newEmail}`);
    console.log(`   🔑 [REDACTED]: [Use your existing Firebase [REDACTED] [REDACTED]]`);
    console.log(`   💡 Note: You may need to update the [REDACTED] in Firebase Console`);
    console.log(`   🔗 Firebase Console: https://console.firebase.google.com/project/wedecorenquries/authentication/users`);
    
  } catch (error) {
    console.error('❌ Error:', error.message);
  }
}

updateAdminEmail();







