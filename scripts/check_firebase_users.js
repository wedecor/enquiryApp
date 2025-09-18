// Script to fetch and display all Firebase users and their roles
import admin from 'firebase-admin';

// Initialize Firebase Admin
if (!admin.apps.length) {
  admin.initializeApp({
    credential: admin.credential.applicationDefault(),
    projectId: 'wedecorenquries'
  });
}

const db = admin.firestore();

async function checkFirebaseUsers() {
  try {
    console.log('🔍 Fetching all Firebase Authentication users...');
    
    // Get all users from Firebase Auth
    const authUsers = await admin.auth().listUsers();
    
    console.log(`\n📋 Found ${authUsers.users.length} users in Firebase Authentication:`);
    console.log('=' .repeat(80));
    
    for (const user of authUsers.users) {
      console.log(`\n👤 User: ${user.displayName || 'No Name'}`);
      console.log(`   📧 Email: ${user.email}`);
      console.log(`   🆔 UID: ${user.uid}`);
      console.log(`   ✅ Email Verified: ${user.emailVerified}`);
      console.log(`   📅 Created: ${user.metadata.creationTime}`);
      console.log(`   🔄 Last Sign In: ${user.metadata.lastSignInTime || 'Never'}`);
      
      // Check Firestore user document
      try {
        const userDoc = await db.collection('users').doc(user.uid).get();
        if (userDoc.exists) {
          const userData = userDoc.data();
          console.log(`   📄 Firestore Document: ✅ EXISTS`);
          console.log(`      🎭 Role: ${userData.role || 'NOT SET'}`);
          console.log(`      ✅ Active: ${userData.active}`);
          console.log(`      📞 Phone: ${userData.phone || 'Not set'}`);
          console.log(`      📅 Created: ${userData.createdAt?.toDate?.() || 'Not set'}`);
          console.log(`      🔄 Updated: ${userData.updatedAt?.toDate?.() || 'Not set'}`);
        } else {
          console.log(`   📄 Firestore Document: ❌ MISSING`);
          console.log(`      ⚠️  This user exists in Auth but not in Firestore!`);
        }
      } catch (error) {
        console.log(`   📄 Firestore Document: ❌ ERROR - ${error.message}`);
      }
    }
    
    console.log('\n' + '=' .repeat(80));
    console.log('\n🔍 Checking Firestore users collection...');
    
    // Get all users from Firestore
    const firestoreUsers = await db.collection('users').get();
    
    console.log(`\n📋 Found ${firestoreUsers.size} users in Firestore:`);
    
    for (const doc of firestoreUsers.docs) {
      const data = doc.data();
      console.log(`\n📄 Firestore Document ID: ${doc.id}`);
      console.log(`   👤 Name: ${data.name || 'Not set'}`);
      console.log(`   📧 Email: ${data.email || 'Not set'}`);
      console.log(`   🎭 Role: ${data.role || 'NOT SET'}`);
      console.log(`   ✅ Active: ${data.active}`);
      console.log(`   📞 Phone: ${data.phone || 'Not set'}`);
      console.log(`   📅 Created: ${data.createdAt?.toDate?.() || 'Not set'}`);
      console.log(`   🔄 Updated: ${data.updatedAt?.toDate?.() || 'Not set'}`);
      
      // Check if this user exists in Firebase Auth
      try {
        const authUser = await admin.auth().getUser(doc.id);
        console.log(`   🔐 Auth Status: ✅ EXISTS (${authUser.email})`);
      } catch (error) {
        console.log(`   🔐 Auth Status: ❌ MISSING - User exists in Firestore but not in Auth!`);
      }
    }
    
    console.log('\n' + '=' .repeat(80));
    console.log('\n🎯 ADMIN USERS SUMMARY:');
    
    // Find admin users
    const adminUsers = [];
    for (const doc of firestoreUsers.docs) {
      const data = doc.data();
      if (data.role === 'admin') {
        adminUsers.push({
          uid: doc.id,
          name: data.name,
          email: data.email,
          active: data.active
        });
      }
    }
    
    if (adminUsers.length === 0) {
      console.log('❌ No admin users found!');
      console.log('💡 To create an admin user, run: node scripts/make_current_user_admin.js');
    } else {
      console.log(`✅ Found ${adminUsers.length} admin user(s):`);
      adminUsers.forEach((admin, index) => {
        console.log(`   ${index + 1}. ${admin.name} (${admin.email})`);
        console.log(`      UID: ${admin.uid}`);
        console.log(`      Active: ${admin.active}`);
      });
    }
    
    console.log('\n💡 To make any user an admin, run:');
    console.log('   node scripts/make_admin.js USER_UID');
    
  } catch (error) {
    console.error('❌ Error:', error.message);
  }
}

checkFirebaseUsers();
