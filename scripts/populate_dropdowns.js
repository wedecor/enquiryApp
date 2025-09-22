#!/usr/bin/env node

import admin from 'firebase-admin';

// Initialize Firebase Admin
if (!admin.apps.length) {
  admin.initializeApp({
    projectId: 'wedecorenquries',
  });
}

// Use emulator if running locally
if (process.env.NODE_ENV !== 'production') {
  process.env.FIRESTORE_EMULATOR_HOST = 'localhost:8080';
}

const db = admin.firestore();

const STATUSES = [
  { value: "new", label: "New", order: 1, active: true, color: "#9E9E9E" },
  { value: "in_talks", label: "In Talks", order: 2, active: true, color: "#2196F3" },
  { value: "confirmed", label: "Confirmed", order: 3, active: true, color: "#4CAF50" },
  { value: "completed", label: "Completed", order: 4, active: true, color: "#607D8B" },
  { value: "cancelled", label: "Cancelled", order: 5, active: true, color: "#F44336" },
  { value: "not_interested", label: "Not Interested", order: 6, active: true, color: "#FF9800" },
  { value: "quotation_sent", label: "Quotation Sent", order: 7, active: true, color: "#9C27B0" },
];

async function populateDropdowns() {
  console.log('🚀 Populating dropdown data...');
  
  try {
    // Create statuses
    console.log('📋 Creating statuses...');
    for (const status of STATUSES) {
      const docRef = db.collection('dropdowns').doc('statuses').collection('items').doc(status.value);
      await docRef.set({
        ...status,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      console.log(`✅ Created status: ${status.label} (${status.value})`);
    }
    
    console.log('🎉 Dropdown data populated successfully!');
  } catch (error) {
    console.error('❌ Error populating dropdowns:', error);
    process.exit(1);
  }
}

populateDropdowns();
