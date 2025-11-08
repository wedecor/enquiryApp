// Script to check Firestore users and their roles
import admin from 'firebase-admin';

// Initialize Firebase Admin
if (!admin.apps.length) {
  admin.initializeApp({
    credential: admin.credential.applicationDefault(),
    projectId: 'wedecorenquries'
  });
}

const db = admin.firestore();

async function checkFirestoreUsers() {
  try {
    console.log('🔍 Checking Firestore users collection...');
    
    // Get all users from Firestore
    const firestoreUsers = await db.collection('users').get();
    
    console.log(`\n📋 Found ${firestoreUsers.size} users in Firestore:`);
    console.log('=' .repeat(80));
    
    if (firestoreUsers.empty) {
      console.log('❌ No users found in Firestore!');
      console.log('💡 Run the seeding script to create users: npm run seed:local');
      return;
    }
    
    const adminUsers = [];
    const staffUsers = [];
    
    for (const doc of firestoreUsers.docs) {
      const data = doc.data();
      const userInfo = {
        uid: doc.id,
        name: data.name || 'No Name',
        email: data.email || 'No Email',
        role: data.role || 'NOT SET',
        active: data.active,
        phone: data.phone || 'Not set',
        createdAt: data.createdAt?.toDate?.() || 'Not set',
        updatedAt: data.updatedAt?.toDate?.() || 'Not set'
      };
      
      console.log(`\n📄 User Document: ${doc.id}`);
      console.log(`   👤 Name: ${userInfo.name}`);
      console.log(`   📧 Email: ${userInfo.email}`);
      console.log(`   🎭 Role: ${userInfo.role}`);
      console.log(`   ✅ Active: ${userInfo.active}`);
      console.log(`   📞 Phone: ${userInfo.phone}`);
      console.log(`   📅 Created: ${userInfo.createdAt}`);
      console.log(`   🔄 Updated: ${userInfo.updatedAt}`);
      
      if (userInfo.role === 'admin') {
        adminUsers.push(userInfo);
      } else if (userInfo.role === 'staff') {
        staffUsers.push(userInfo);
      }
    }
    
    console.log('\n' + '=' .repeat(80));
    console.log('\n🎯 SUMMARY:');
    console.log(`📊 Total Users: ${firestoreUsers.size}`);
    console.log(`👑 Admin Users: ${adminUsers.length}`);
    console.log(`👥 Staff Users: ${staffUsers.length}`);
    console.log(`❓ Unknown Role: ${firestoreUsers.size - adminUsers.length - staffUsers.length}`);
    
    if (adminUsers.length === 0) {
      console.log('\n❌ NO ADMIN USERS FOUND!');
      console.log('💡 To create an admin user, run:');
      console.log('   node scripts/make_current_user_admin.js');
    } else {
      console.log('\n✅ ADMIN USERS:');
      adminUsers.forEach((admin, index) => {
        console.log(`   ${index + 1}. ${admin.name} (${admin.email})`);
        console.log(`      UID: ${admin.uid}`);
        console.log(`      Active: ${admin.active}`);
        console.log(`      Created: ${admin.createdAt}`);
      });
    }
    
    if (staffUsers.length > 0) {
      console.log('\n👥 STAFF USERS:');
      staffUsers.forEach((staff, index) => {
        console.log(`   ${index + 1}. ${staff.name} (${staff.email})`);
        console.log(`      UID: ${staff.uid}`);
        console.log(`      Active: ${staff.active}`);
      });
    }
    
    console.log('\n' + '=' .repeat(80));
    console.log('\n💡 QUICK COMMANDS:');
    console.log('   Make any user admin: node scripts/make_admin.js USER_UID');
    console.log('   Run seeding script: npm run seed:local');
    console.log('   Check current user: node scripts/make_current_user_admin.js');
    
  } catch (error) {
    console.error('❌ Error:', error.message);
  }
}

checkFirestoreUsers();








