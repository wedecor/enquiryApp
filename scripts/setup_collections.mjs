import { initializeApp } from 'firebase/app';
import { getFirestore, collection, doc, setDoc, serverTimestamp } from 'firebase/firestore';

// Firebase configuration - replace with your actual config
const firebaseConfig = {
  apiKey: process.env.FIREBASE_API_KEY || "AIzaSyDZQj7TxQGBKpPQlJd_H2tEZvEGbTXl4nQ",
  authDomain: process.env.FIREBASE_AUTH_DOMAIN || "wedecorenquries.firebaseapp.com",
  projectId: process.env.FIREBASE_PROJECT_ID || "wedecorenquries",
  storageBucket: process.env.FIREBASE_STORAGE_BUCKET || "wedecorenquries.firebasestorage.app",
  messagingSenderId: process.env.FIREBASE_MESSAGING_SENDER_ID || "747327664982",
  appId: process.env.FIREBASE_APP_ID || "1:747327664982:web:2e3f4a5b6c7d8e9f0a1b2c"
};

// Initialize Firebase
const app = initializeApp(firebaseConfig);
const db = getFirestore(app);

console.log('🚀 Starting Firestore collections setup...');

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
}

/// Create statuses collection for enquiry status dropdown
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
  
  const promises = statuses.map(status => 
    setDoc(doc(db, 'dropdowns', 'statuses', 'items', status.value), {
      ...status,
      createdAt: serverTimestamp(),
      updatedAt: serverTimestamp(),
    })
  );
  
  await Promise.all(promises);
  console.log(`✅ Statuses collection created with ${statuses.length} items`);
}

/// Create event types collection for event type dropdown
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
  
  const promises = eventTypes.map(eventType => 
    setDoc(doc(db, 'dropdowns', 'event_types', 'items', eventType.value), {
      ...eventType,
      createdAt: serverTimestamp(),
      updatedAt: serverTimestamp(),
    })
  );
  
  await Promise.all(promises);
  console.log(`✅ Event types collection created with ${eventTypes.length} items`);
}

/// Create priorities collection for priority dropdown
async function createPrioritiesCollection(db) {
  console.log('⚡ Creating priorities collection...');
  
  const priorities = [
    {value: 'low', label: 'Low', order: 1, active: true, color: '#4CAF50'},
    {value: 'medium', label: 'Medium', order: 2, active: true, color: '#FF9800'},
    {value: 'high', label: 'High', order: 3, active: true, color: '#F44336'},
    {value: 'urgent', label: 'Urgent', order: 4, active: true, color: '#9C27B0'},
  ];
  
  const promises = priorities.map(priority => 
    setDoc(doc(db, 'dropdowns', 'priorities', 'items', priority.value), {
      ...priority,
      createdAt: serverTimestamp(),
      updatedAt: serverTimestamp(),
    })
  );
  
  await Promise.all(promises);
  console.log(`✅ Priorities collection created with ${priorities.length} items`);
}

/// Create payment statuses collection for payment status dropdown
async function createPaymentStatusesCollection(db) {
  console.log('💰 Creating payment statuses collection...');
  
  const paymentStatuses = [
    {value: 'pending', label: 'Pending', order: 1, active: true, color: '#FF9800'},
    {value: 'partial', label: 'Partial Payment', order: 2, active: true, color: '#2196F3'},
    {value: 'paid', label: 'Fully Paid', order: 3, active: true, color: '#4CAF50'},
    {value: 'overdue', label: 'Overdue', order: 4, active: true, color: '#F44336'},
    {value: 'refunded', label: 'Refunded', order: 5, active: true, color: '#607D8B'},
  ];
  
  const promises = paymentStatuses.map(paymentStatus => 
    setDoc(doc(db, 'dropdowns', 'payment_statuses', 'items', paymentStatus.value), {
      ...paymentStatus,
      createdAt: serverTimestamp(),
      updatedAt: serverTimestamp(),
    })
  );
  
  await Promise.all(promises);
  console.log(`✅ Payment statuses collection created with ${paymentStatuses.length} items`);
}

/// Create budget ranges collection for budget dropdown
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
  
  const promises = budgetRanges.map(budgetRange => 
    setDoc(doc(db, 'dropdowns', 'budget_ranges', 'items', budgetRange.value), {
      ...budgetRange,
      createdAt: serverTimestamp(),
      updatedAt: serverTimestamp(),
    })
  );
  
  await Promise.all(promises);
  console.log(`✅ Budget ranges collection created with ${budgetRanges.length} items`);
}

