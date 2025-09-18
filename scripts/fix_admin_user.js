// Script to fix the admin user's active field
import admin from 'firebase-admin';

// Initialize Firebase Admin
if (!admin.apps.length) {
  admin.initializeApp({
    credential: admin.credential.applicationDefault(),
    projectId: 'wedecorenquries'
  });
}

const db = admin.firestore();

async function fixAdminUser() {
  try {
    const adminUid = 'SstmjrY2bkbG3vv1ufeWUU0rMgl1';
    
    console.log('🔧 Fixing admin user...');
    
    await db.collection('users').doc(adminUid).update({
      active: true,
      updatedAt: admin.firestore.FieldValue.serverTimestamp()
    });
    
    console.log('✅ Admin user fixed!');
    console.log('   - Set active: true');
    console.log('   - Updated timestamp');
    
    // Verify the fix
    const userDoc = await db.collection('users').doc(adminUid).get();
    const userData = userDoc.data();
    
    console.log('\n📋 Updated user details:');
    console.log(`   👤 Name: ${userData.name}`);
    console.log(`   📧 Email: ${userData.email}`);
    console.log(`   🎭 Role: ${userData.role}`);
    console.log(`   ✅ Active: ${userData.active}`);
    console.log(`   📞 Phone: ${userData.phone}`);
    
  } catch (error) {
    console.error('❌ Error:', error.message);
  }
}

fixAdminUser();

