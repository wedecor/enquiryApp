const admin = require('firebase-admin');

// Initialize Firebase Admin with default credentials
admin.initializeApp({
  projectId: 'wedecorenquries'
});

const db = admin.firestore();

async function checkStatuses() {
  try {
    console.log('🔍 Checking statuses in Firebase database...\n');
    
    // Check statuses collection
    const statusesRef = db.collection('dropdowns').doc('statuses').collection('items');
    const statusesSnapshot = await statusesRef.get();
    
    if (statusesSnapshot.empty) {
      console.log('❌ No statuses found in dropdowns/statuses/items collection');
    } else {
      console.log('✅ Found statuses in dropdowns/statuses/items:');
      statusesSnapshot.forEach(doc => {
        const data = doc.data();
        console.log(`  - Value: "${data.value || 'N/A'}", Label: "${data.label || 'N/A'}"`);
        console.log(`    Order: ${data.order || 'N/A'}, Active: ${data.active !== false}`);
        console.log(`    Doc ID: ${doc.id}`);
        console.log('');
      });
    }
    
    console.log('🔍 Checking enquiries for current status values...\n');
    const enquiriesRef = db.collection('enquiries');
    const enquiriesSnapshot = await enquiriesRef.limit(20).get();
    
    if (enquiriesSnapshot.empty) {
      console.log('❌ No enquiries found');
    } else {
      console.log('✅ Found enquiries with these status values:');
      const statusValues = new Set();
      enquiriesSnapshot.forEach(doc => {
        const data = doc.data();
        if (data.eventStatus) {
          statusValues.add(data.eventStatus);
        }
        if (data.status) {
          statusValues.add(data.status);
        }
      });
      
      if (statusValues.size === 0) {
        console.log('  - No status values found in enquiries');
      } else {
        statusValues.forEach(status => {
          console.log(`  - "${status}"`);
        });
      }
    }
    
    console.log('\n🔍 Checking what the app expects...\n');
    console.log('✅ Code fallback statuses:');
    const codeStatuses = [
      'new', 'in_talks', 'quotation_sent', 'confirmed', 'completed', 'cancelled', 'not_interested'
    ];
    codeStatuses.forEach(status => {
      console.log(`  - "${status}"`);
    });
    
    console.log('\n✅ Seed script statuses:');
    const seedStatuses = [
      'new', 'contacted', 'in_progress', 'quote_sent', 'approved', 'scheduled', 'completed', 'closed_lost', 'cancelled'
    ];
    seedStatuses.forEach(status => {
      console.log(`  - "${status}"`);
    });
    
    process.exit(0);
  } catch (error) {
    console.error('❌ Error:', error.message);
    process.exit(1);
  }
}

checkStatuses();
