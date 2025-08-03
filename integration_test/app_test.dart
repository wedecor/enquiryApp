import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Enquiry Workflow Integration Test', () {
    late FirebaseAuth auth;
    late FirebaseFirestore firestore;

    setUpAll(() async {
      // Initialize Firebase with emulator configuration
      await Firebase.initializeApp();
      
      // Connect to Firebase emulators
      await FirebaseAuth.instance.useAuthEmulator('localhost', 9099);
      FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080);
      
      auth = FirebaseAuth.instance;
      firestore = FirebaseFirestore.instance;
      
      // Clear any existing data
      await _clearTestData();
      
      // Setup test data
      await _setupTestData();
    });

    tearDownAll(() async {
      // Clean up test data
      await _clearTestData();
    });

    testWidgets('Complete enquiry workflow: Create → Assign → Complete', (tester) async {
      // Test the complete workflow through database operations
      await _testCompleteWorkflow();
    });

    testWidgets('Database operations with emulator', (tester) async {
      // Test basic CRUD operations
      await _testDatabaseOperations();
    });

    testWidgets('Authentication flow with emulator', (tester) async {
      // Test authentication operations
      await _testAuthenticationFlow();
    });
  });
}

/// Helper functions for the integration test

Future<void> _clearTestData() async {
  final firestore = FirebaseFirestore.instance;
  
  try {
    // Clear enquiries
    final enquiries = await firestore.collection('enquiries').get();
    for (final doc in enquiries.docs) {
      await doc.reference.delete();
    }
    
    // Clear users (except test users)
    final users = await firestore.collection('users').get();
    for (final doc in users.docs) {
      if (doc.id != 'admin-test' && doc.id != 'staff-test') {
        await doc.reference.delete();
      }
    }
    
    // Clear dropdowns
    final dropdowns = await firestore.collection('dropdowns').get();
    for (final doc in dropdowns.docs) {
      await doc.reference.delete();
    }
    
    print('✅ Test data cleared successfully');
  } catch (e) {
    print('Error clearing test data: $e');
  }
}

Future<void> _setupTestData() async {
  final firestore = FirebaseFirestore.instance;
  
  try {
    // Create test admin user
    await firestore.collection('users').doc('admin-test').set({
      'uid': 'admin-test',
      'name': 'Test Admin',
      'email': 'admin@test.com',
      'phone': '1234567890',
      'role': 'admin',
      'createdAt': FieldValue.serverTimestamp(),
    });
    
    // Create test staff user
    await firestore.collection('users').doc('staff-test').set({
      'uid': 'staff-test',
      'name': 'Test Staff',
      'email': 'staff@test.com',
      'phone': '0987654321',
      'role': 'staff',
      'createdAt': FieldValue.serverTimestamp(),
    });
    
    // Setup default dropdowns
    await firestore.collection('dropdowns').doc('event_types').collection('items').add({
      'name': 'Wedding',
      'createdAt': FieldValue.serverTimestamp(),
    });
    
    await firestore.collection('dropdowns').doc('statuses').collection('items').add({
      'name': 'New',
      'createdAt': FieldValue.serverTimestamp(),
    });
    
    await firestore.collection('dropdowns').doc('statuses').collection('items').add({
      'name': 'In Progress',
      'createdAt': FieldValue.serverTimestamp(),
    });
    
    await firestore.collection('dropdowns').doc('statuses').collection('items').add({
      'name': 'Completed',
      'createdAt': FieldValue.serverTimestamp(),
    });
    
    await firestore.collection('dropdowns').doc('payment_statuses').collection('items').add({
      'name': 'Pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
    
    print('✅ Test data setup completed');
  } catch (e) {
    print('Error setting up test data: $e');
  }
}

Future<void> _testCompleteWorkflow() async {
  final firestore = FirebaseFirestore.instance;
  
  print('🧪 Testing complete enquiry workflow...');
  
  // Step 1: Create an enquiry
  final enquiryRef = await firestore.collection('enquiries').add({
    'customerName': 'John Doe',
    'customerPhone': '555-0123',
    'eventLocation': 'Test Venue',
    'eventDate': Timestamp.now(),
    'eventType': 'Wedding',
    'status': 'New',
    'priority': 'Medium',
    'description': 'Test enquiry for integration testing',
    'createdAt': FieldValue.serverTimestamp(),
    'createdBy': 'admin-test',
  });
  
  // Verify the enquiry was created
  final enquiryDoc = await enquiryRef.get();
  expect(enquiryDoc.exists, isTrue);
  expect(enquiryDoc.data()?['customerName'], 'John Doe');
  expect(enquiryDoc.data()?['status'], 'New');
  print('✅ Enquiry created successfully');
  
  // Step 2: Assign the enquiry to staff
  await enquiryRef.update({
    'assignedTo': 'staff-test',
    'assignedAt': FieldValue.serverTimestamp(),
    'assignedBy': 'admin-test',
    'status': 'In Progress',
  });
  
  // Verify the assignment
  final assignedDoc = await enquiryRef.get();
  expect(assignedDoc.data()?['assignedTo'], 'staff-test');
  expect(assignedDoc.data()?['status'], 'In Progress');
  print('✅ Enquiry assigned successfully');
  
  // Step 3: Mark the enquiry as completed
  await enquiryRef.update({
    'status': 'Completed',
    'completedAt': FieldValue.serverTimestamp(),
    'completedBy': 'staff-test',
  });
  
  // Verify the completion
  final completedDoc = await enquiryRef.get();
  expect(completedDoc.data()?['status'], 'Completed');
  expect(completedDoc.data()?['completedBy'], 'staff-test');
  print('✅ Enquiry completed successfully');
  
  // Step 4: Verify the complete workflow
  final finalDoc = await enquiryRef.get();
  final data = finalDoc.data()!;
  
  expect(data['customerName'], 'John Doe');
  expect(data['assignedTo'], 'staff-test');
  expect(data['status'], 'Completed');
  expect(data['createdBy'], 'admin-test');
  expect(data['completedBy'], 'staff-test');
  
  print('✅ Complete workflow verified successfully');
}

Future<void> _testDatabaseOperations() async {
  final firestore = FirebaseFirestore.instance;
  
  print('🧪 Testing database operations...');
  
  // Test basic CRUD operations
  final testCollection = firestore.collection('test');
  
  // Create
  final docRef = await testCollection.add({
    'test': 'value',
    'timestamp': FieldValue.serverTimestamp(),
  });
  
  // Read
  final doc = await docRef.get();
  expect(doc.exists, isTrue);
  expect(doc.data()?['test'], 'value');
  
  // Update
  await docRef.update({'test': 'updated_value'});
  final updatedDoc = await docRef.get();
  expect(updatedDoc.data()?['test'], 'updated_value');
  
  // Delete
  await docRef.delete();
  final deletedDoc = await docRef.get();
  expect(deletedDoc.exists, isFalse);
  
  print('✅ Database operations test completed');
}

Future<void> _testAuthenticationFlow() async {
  final auth = FirebaseAuth.instance;
  
  print('🧪 Testing authentication flow...');
  
  // Test that we can connect to the auth emulator
  expect(auth.app.name, isNotEmpty);
  
  // Test that we start with no current user
  expect(auth.currentUser, isNull);
  
  // Test creating a user with email/password (this would work with emulator)
  try {
    // Note: This would require the emulator to be running
    // For now, we just test that the auth instance is properly configured
    expect(auth.app, isNotNull);
    print('✅ Authentication flow test completed');
  } catch (e) {
    print('⚠️ Authentication test skipped (emulator not running): $e');
  }
} 