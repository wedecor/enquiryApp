import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:we_decor_enquiries/firebase_options.dart';

/// Simple test script to verify database structure
void main() async {
  try {
    print('🚀 Testing We Decor Enquiries Database Structure...');

    // Initialize Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Connect to Firestore emulator if running locally
    if (const bool.fromEnvironment('USE_FIRESTORE_EMULATOR')) {
      FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080);
      print('📡 Connected to Firestore emulator');
    }

    final firestore = FirebaseFirestore.instance;

    // Test 1: Check if collections exist
    print('\n📋 Testing Collection Structure...');

    try {
      await firestore
          .collection('enquiries')
          .limit(1)
          .get();
      print('✅ enquiries/ collection exists');
    } catch (e) {
      print('❌ enquiries/ collection not found: $e');
    }

    try {
      await firestore
          .collection('dropdowns')
          .limit(1)
          .get();
      print('✅ dropdowns/ collection exists');
    } catch (e) {
      print('❌ dropdowns/ collection not found: $e');
    }

    // Test 2: Check dropdown subcollections
    print('\n📊 Testing Dropdown Subcollections...');

    try {
      await firestore
          .collection('dropdowns')
          .doc('event_types')
          .collection('items')
          .limit(1)
          .get();
      print('✅ dropdowns/event_types/items/ subcollection exists');
    } catch (e) {
      print('❌ dropdowns/event_types/items/ subcollection not found: $e');
    }

    try {
      await firestore
          .collection('dropdowns')
          .doc('statuses')
          .collection('items')
          .limit(1)
          .get();
      print('✅ dropdowns/statuses/items/ subcollection exists');
    } catch (e) {
      print('❌ dropdowns/statuses/items/ subcollection not found: $e');
    }

    try {
      await firestore
          .collection('dropdowns')
          .doc('payment_statuses')
          .collection('items')
          .limit(1)
          .get();
      print('✅ dropdowns/payment_statuses/items/ subcollection exists');
    } catch (e) {
      print('❌ dropdowns/payment_statuses/items/ subcollection not found: $e');
    }

    // Test 3: Check if dropdowns have data
    print('\n📝 Testing Dropdown Data...');

    try {
      final eventTypesCount = await firestore
          .collection('dropdowns')
          .doc('event_types')
          .collection('items')
          .count()
          .get();
      print('✅ Event types count: ${eventTypesCount.count}');
    } catch (e) {
      print('❌ Error counting event types: $e');
    }

    try {
      final statusesCount = await firestore
          .collection('dropdowns')
          .doc('statuses')
          .collection('items')
          .count()
          .get();
      print('✅ Statuses count: ${statusesCount.count}');
    } catch (e) {
      print('❌ Error counting statuses: $e');
    }

    try {
      final paymentStatusesCount = await firestore
          .collection('dropdowns')
          .doc('payment_statuses')
          .collection('items')
          .count()
          .get();
      print('✅ Payment statuses count: ${paymentStatusesCount.count}');
    } catch (e) {
      print('❌ Error counting payment statuses: $e');
    }

    // Test 4: Create a test enquiry
    print('\n🧪 Creating Test Enquiry...');

    try {
      final testEnquiry = {
        'customerName': 'Test Customer',
        'customerPhone': '+1234567890',
        'location': 'Test Location',
        'eventDate': DateTime.now().add(const Duration(days: 30)),
        'eventType': 'Wedding',
        'eventStatus': 'Enquired',
        'notes': 'Test enquiry for database verification',
        'referenceImages': [],
        'createdBy': 'test-user',
        'assignedTo': null,
        'createdAt': FieldValue.serverTimestamp(),
      };

      final docRef = await firestore.collection('enquiries').add(testEnquiry);
      print('✅ Test enquiry created with ID: ${docRef.id}');

      // Create financial subcollection
      await firestore
          .collection('enquiries')
          .doc(docRef.id)
          .collection('financial')
          .add({
            'totalCost': 5000.0,
            'advancePaid': 1000.0,
            'paymentStatus': 'Partial',
          });
      print('✅ Financial subcollection created');

      // Create history subcollection
      await firestore
          .collection('enquiries')
          .doc(docRef.id)
          .collection('history')
          .add({
            'fieldChanged': 'eventStatus',
            'oldValue': '',
            'newValue': 'Enquired',
            'changedBy': 'test-user',
            'timestamp': FieldValue.serverTimestamp(),
          });
      print('✅ History subcollection created');

      // Clean up test data
      await firestore.collection('enquiries').doc(docRef.id).delete();
      print('✅ Test enquiry cleaned up');
    } catch (e) {
      print('❌ Error creating test enquiry: $e');
    }

    print('\n🎉 Database structure test completed!');
    print('\n📋 Expected Database Structure:');
    print('   • users/ collection (for user data)');
    print('   • enquiries/ collection (for enquiry data)');
    print('   • enquiries/{id}/financial/ subcollection (for financial data)');
    print('   • enquiries/{id}/history/ subcollection (for audit trail)');
    print('   • dropdowns/event_types/items/ (for event type options)');
    print('   • dropdowns/statuses/items/ (for status options)');
    print(
      '   • dropdowns/payment_statuses/items/ (for payment status options)',
    );
  } catch (e) {
    print('❌ Error during database test: $e');
    exit(1);
  }
}
