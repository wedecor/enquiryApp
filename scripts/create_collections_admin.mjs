import admin from 'firebase-admin';

// Initialize Firebase Admin SDK
// Using the default credentials from Firebase CLI login
const app = admin.initializeApp({
  projectId: 'wedecorenquries'
});

const db = admin.firestore(app);

console.log('🚀 Starting Firestore collections setup with Admin SDK...');

try {
  // Create dropdown collections
  await createStatusesCollection(db);
  await createEventTypesCollection(db);
  await createPrioritiesCollection(db);
  await createPaymentStatusesCollection(db);
  await createBudgetRangesCollection(db);
  
  console.log('🎉 All Firestore collections created successfully!');
  console.log('📝 Next steps:');
  console.log('   1. Restart your Flutter app');
  console.log('   2. Loading symbols should be eliminated');
  console.log('   3. Dropdowns should work perfectly');
  
} catch (error) {
  console.error('❌ Error setting up Firestore collections:', error);
  process.exit(1);
} finally {
  await app.delete();
}

async function createStatusesCollection(db) {
  console.log('📋 Creating statuses collection...');
  
  const statuses = [
    {value: 'new', label: 'New', order: 1, active: true, color: '#FF9800'},
    {value: 'in_progress', label: 'In Progress', order: 2, active: true, color: '#2196F3'},
    {value: 'quote_sent', label: 'Quote Sent', order: 3, active: true, color: '#009688'},
    {value: 'approved', label: 'Approved', order: 4, active: true, color: '#3F51B5'},
    {value: 'scheduled', label: 'Scheduled', order: 5, active: true, color: '#9C27B0'},
    {value: 'completed', label: 'Completed', order: 6, active: true, color: '#4CAF50'},
    {value: 'cancelled', label: 'Cancelled', order: 7, active: true, color: '#F44336'},
    {value: 'closed_lost', label: 'Closed Lost', order: 8, active: true, color: '#607D8B'},
  ];
  
  const batch = db.batch();
  statuses.forEach(status => {
    const docRef = db.collection('dropdowns').doc('statuses').collection('items').doc(status.value);
    batch.set(docRef, {
      ...status,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  });
  
  await batch.commit();
  console.log(`✅ Statuses collection created with ${statuses.length} items`);
}

async function createEventTypesCollection(db) {
  console.log('🎉 Creating event types collection...');
  
  const eventTypes = [
    {value: 'wedding', label: 'Wedding', order: 1, active: true, category: 'celebration'},
    {value: 'birthday', label: 'Birthday Party', order: 2, active: true, category: 'celebration'},
    {value: 'anniversary', label: 'Anniversary', order: 3, active: true, category: 'celebration'},
    {value: 'engagement', label: 'Engagement', order: 4, active: true, category: 'celebration'},
    {value: 'baby_shower', label: 'Baby Shower', order: 5, active: true, category: 'celebration'},
    {value: 'corporate_event', label: 'Corporate Event', order: 6, active: true, category: 'business'},
    {value: 'conference', label: 'Conference', order: 7, active: true, category: 'business'},
    {value: 'product_launch', label: 'Product Launch', order: 8, active: true, category: 'business'},
    {value: 'graduation', label: 'Graduation', order: 9, active: true, category: 'celebration'},
    {value: 'housewarming', label: 'Housewarming', order: 10, active: true, category: 'celebration'},
    {value: 'festival', label: 'Festival', order: 11, active: true, category: 'cultural'},
    {value: 'religious_ceremony', label: 'Religious Ceremony', order: 12, active: true, category: 'cultural'},
    {value: 'other', label: 'Other', order: 99, active: true, category: 'general'},
  ];
  
  const batch = db.batch();
  eventTypes.forEach(eventType => {
    const docRef = db.collection('dropdowns').doc('event_types').collection('items').doc(eventType.value);
    batch.set(docRef, {
      ...eventType,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  });
  
  await batch.commit();
  console.log(`✅ Event types collection created with ${eventTypes.length} items`);
}

async function createPrioritiesCollection(db) {
  console.log('⚡ Creating priorities collection...');
  
  const priorities = [
    {value: 'low', label: 'Low', order: 1, active: true, color: '#4CAF50'},
    {value: 'medium', label: 'Medium', order: 2, active: true, color: '#FF9800'},
    {value: 'high', label: 'High', order: 3, active: true, color: '#F44336'},
    {value: 'urgent', label: 'Urgent', order: 4, active: true, color: '#9C27B0'},
  ];
  
  const batch = db.batch();
  priorities.forEach(priority => {
    const docRef = db.collection('dropdowns').doc('priorities').collection('items').doc(priority.value);
    batch.set(docRef, {
      ...priority,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  });
  
  await batch.commit();
  console.log(`✅ Priorities collection created with ${priorities.length} items`);
}

async function createPaymentStatusesCollection(db) {
  console.log('💰 Creating payment statuses collection...');
  
  const paymentStatuses = [
    {value: 'pending', label: 'Pending', order: 1, active: true, color: '#FF9800'},
    {value: 'partial', label: 'Partial Payment', order: 2, active: true, color: '#2196F3'},
    {value: 'paid', label: 'Fully Paid', order: 3, active: true, color: '#4CAF50'},
    {value: 'overdue', label: 'Overdue', order: 4, active: true, color: '#F44336'},
    {value: 'refunded', label: 'Refunded', order: 5, active: true, color: '#607D8B'},
  ];
  
  const batch = db.batch();
  paymentStatuses.forEach(paymentStatus => {
    const docRef = db.collection('dropdowns').doc('payment_statuses').collection('items').doc(paymentStatus.value);
    batch.set(docRef, {
      ...paymentStatus,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  });
  
  await batch.commit();
  console.log(`✅ Payment statuses collection created with ${paymentStatuses.length} items`);
}

async function createBudgetRangesCollection(db) {
  console.log('💵 Creating budget ranges collection...');
  
  const budgetRanges = [
    {value: '0-1000', label: 'Under ₹1,000', order: 1, active: true, minValue: 0, maxValue: 1000},
    {value: '1000-5000', label: '₹1,000 - ₹5,000', order: 2, active: true, minValue: 1000, maxValue: 5000},
    {value: '5000-10000', label: '₹5,000 - ₹10,000', order: 3, active: true, minValue: 5000, maxValue: 10000},
    {value: '10000-25000', label: '₹10,000 - ₹25,000', order: 4, active: true, minValue: 10000, maxValue: 25000},
    {value: '25000-50000', label: '₹25,000 - ₹50,000', order: 5, active: true, minValue: 25000, maxValue: 50000},
    {value: '50000-100000', label: '₹50,000 - ₹1,00,000', order: 6, active: true, minValue: 50000, maxValue: 100000},
    {value: '100000-250000', label: '₹1,00,000 - ₹2,50,000', order: 7, active: true, minValue: 100000, maxValue: 250000},
    {value: '250000+', label: 'Above ₹2,50,000', order: 8, active: true, minValue: 250000, maxValue: null},
  ];
  
  const batch = db.batch();
  budgetRanges.forEach(budgetRange => {
    const docRef = db.collection('dropdowns').doc('budget_ranges').collection('items').doc(budgetRange.value);
    batch.set(docRef, {
      ...budgetRange,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  });
  
  await batch.commit();
  console.log(`✅ Budget ranges collection created with ${budgetRanges.length} items`);
}

