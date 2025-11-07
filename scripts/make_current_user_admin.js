// Quick script to make the current signed-in user an admin
// This helps with testing the admin role gating

const admin = require('firebase-admin');

// Initialize Firebase Admin
if (!admin.apps.length) {
  admin.initializeApp({
    credential: admin.credential.applicationDefault(),
    projectId: 'wedecorenquries'
  });
}

const db = admin.firestore();

async function makeCurrentUserAdmin() {
  try {
    console.log('🔍 Looking for users in Firestore...');
    
    // Get all users from Firestore
    const usersSnapshot = await db.collection('users').get();
    
    if (usersSnapshot.empty) {
      console.log('❌ No users found in Firestore. Make sure you have users in the users collection.');
      return;
    }
    
    console.log(`📋 Found ${usersSnapshot.size} users:`);
    usersSnapshot.forEach((doc) => {
      const data = doc.data();
      console.log(`  - ${data.name} (${data.email}) - Role: ${data.role} - UID: ${doc.id}`);
    });
    
    // Find the admin user or ask which one to make admin
    const adminUser = usersSnapshot.docs.find(doc => {
      const data = doc.data();
      return data.email === 'admin@wedecorevents.com';
    });
    
    if (adminUser) {
      console.log(`\n✅ Found admin user: ${adminUser.data().name} (${adminUser.data().email})`);
      console.log(`   UID: ${adminUser.id}`);
      console.log(`   Current role: ${adminUser.data().role}`);
      
      if (adminUser.data().role !== 'admin') {
        await adminUser.ref.update({
          role: 'admin',
          active: true,
          updatedAt: admin.firestore.FieldValue.serverTimestamp()
        });
        console.log('✅ Updated user to admin role!');
      } else {
        console.log('✅ User is already an admin.');
      }
    } else {
      console.log('\n⚠️  Admin user (admin@wedecorevents.com) not found.');
      console.log('   You can manually update any user to admin by running:');
      console.log('   node scripts/make_admin.js YOUR_UID');
    }
    
  } catch (error) {
    console.error('❌ Error:', error.message);
  }
}

makeCurrentUserAdmin();







