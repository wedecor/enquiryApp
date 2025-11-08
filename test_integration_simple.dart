// ignore_for_file: avoid_print

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Simple Integration Tests', () {
    setUpAll(() async {
      // Initialize Flutter binding
      TestWidgetsFlutterBinding.ensureInitialized();

      // Initialize Firebase
      await Firebase.initializeApp();

      // Connect to Firebase emulators
      await FirebaseAuth.instance.useAuthEmulator('localhost', 9099);
      FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080);
    });

    test('Complete enquiry workflow: Create → Assign → Complete', () async {
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
      expect(data['eventStatus'], 'Completed');
      expect(data['createdBy'], 'admin-test');
      expect(data['completedBy'], 'staff-test');

      print('✅ Complete workflow verified successfully');

      // Clean up
      await enquiryRef.delete();
    });

    test('Database operations with emulator', () async {
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
    });

    test('Authentication flow with emulator', () async {
      final auth = FirebaseAuth.instance;

      print('🧪 Testing authentication flow...');

      // Test that we can connect to the auth emulator
      expect(auth.app.name, isNotEmpty);

      // Test that we start with no current user
      expect(auth.currentUser, isNull);

      // Test that the auth instance is properly configured
      expect(auth.app, isNotNull);
      print('✅ Authentication flow test completed');
    });
  });
}
