// Script to create admin user with correct credentials
import admin from 'firebase-admin';

// Initialize Firebase Admin
if (!admin.apps.length) {
  admin.initializeApp({
    credential: admin.credential.applicationDefault(),
    projectId: 'wedecorenquries'
  });
}

const db = admin.firestore();

async function createAdminUser() {
  try {
    const adminEmail = 'admin@wedecorevents.com';
    const adminPassword = process.env.ADMIN_PASSWORD || 'CHANGE_THIS_PASSWORD';
    
    console.log('🔧 Creating admin user...');
    console.log(`📧 Email: ${adminEmail}`);
    console.log(`🔑 [REDACTED]: [ADMINPASSWORD_REDACTED]`);
    
    // Create user in Firebase Auth
    const userRecord = await admin.auth().createUser({
      email: adminEmail,
      password: adminPassword,
      emailVerified: true,
      displayName: 'Admin User'
    });
    
    console.log('✅ Firebase [REDACTED] user created:');
    
    // Create user document in Firestore
    const userData = {
      uid: userRecord.uid,
      name: 'Admin User',
      email: adminEmail,
      phone: '+91 9591232166',
      role: 'admin',
      active: true,
      fcmToken: null,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp()
    };
    
    await db.collection('users').doc(userRecord.uid).set(userData);
    
    console.log('✅ Firestore user document created');
    
    // Verify the user was created
    const userDoc = await db.collection('users').doc(userRecord.uid).get();
    const userDocData = userDoc.data();
    
    console.log('\n📋 Admin user created successfully:');
    console.log(`   🆔 UID: ${userRecord.uid}`);
    console.log(`   👤 Name: ${userDocData.name}`);
    console.log(`   📧 Email: ${userDocData.email}`);
    console.log(`   🎭 Role: ${userDocData.role}`);
    console.log(`   ✅ Active: ${userDocData.active}`);
    console.log(`   📞 Phone: ${userDocData.phone}`);
    
    console.log('\n🎯 Login Credentials:');
    console.log(`   Email: ${adminEmail}`);
    console.log(`   [REDACTED]: [ADMINPASSWORD_REDACTED]`);
    
  } catch (error) {
    if (error.code === 'auth/email-already-exists') {
      console.log('⚠️  User already exists. Updating existing user...');
      
      try {
        const userRecord = await admin.auth().getUserByEmail('admin@wedecorevents.com');
        
        // Update password
        await admin.auth().updateUser(userRecord.uid, {
          password: adminPassword
        });
        
        // Update Firestore document
        await db.collection('users').doc(userRecord.uid).update({
          role: 'admin',
          active: true,
          updatedAt: admin.firestore.FieldValue.serverTimestamp()
        });
        
        console.log('✅ Existing user updated to admin');
        console.log('\n🎯 Login Credentials:');
        console.log(`   Email: admin@wedecorevents.com`);
        console.log(`   [REDACTED]: admin12`);
        
      } catch (updateError) {
        console.error('❌ Error updating user:', updateError.message);
      }
    } else {
      console.error('❌ Error:', error.message);
    }
  }
}

createAdminUser();

