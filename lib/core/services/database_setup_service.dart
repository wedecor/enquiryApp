import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../utils/logger.dart';
import '../constants/firestore_schema.dart';

/// Service for setting up and managing Firestore database structure
class DatabaseSetupService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Reset and initialize the database with the correct schema
  Future<void> resetAndInitializeDatabase() async {
    try {
      Log.i('DatabaseSetupService reset started');

      // Delete existing collections if they exist
      await _deleteExistingCollections();

      // Create new collections with correct structure
      await _createCollections();

      // Initialize dropdowns with default values
      await _initializeDropdowns();

      Log.i('DatabaseSetupService reset completed');
    } catch (e) {
      Log.e('DatabaseSetupService reset failed', error: e);
      rethrow;
    }
  }

  /// Delete existing collections to ensure clean slate
  Future<void> _deleteExistingCollections() async {
    Log.i('DatabaseSetupService deleting existing collections');

    try {
      // Delete enquiries collection (this will also delete subcollections)
      await _deleteCollection('enquiries');

      // Delete dropdowns collection
      await _deleteCollection('dropdowns');

      // Note: We don't delete users collection as it contains user data
      Log.i('DatabaseSetupService collections deleted');
    } catch (e) {
      Log.w('DatabaseSetupService delete collections warning', data: {'error': e.toString()});
      // Continue even if deletion fails (collections might not exist)
    }
  }

  /// Recursively delete a collection and its subcollections
  Future<void> _deleteCollection(String collectionPath) async {
    final collectionRef = _firestore.collection(collectionPath);
    final query = collectionRef.limit(500);

    final querySnapshot = await query.get();
    final batch = _firestore.batch();

    for (final doc in querySnapshot.docs) {
      // Delete subcollections first (financial and history)
      await _deleteCollection('$collectionPath/${doc.id}/financial');
      await _deleteCollection('$collectionPath/${doc.id}/history');

      // Delete the document
      batch.delete(doc.reference);
    }

    await batch.commit();

    // If there are more documents, delete them in batches
    if (querySnapshot.docs.length == 500) {
      await _deleteCollection(collectionPath);
    }
  }

  /// Create the basic collection structure
  Future<void> _createCollections() async {
    Log.i('DatabaseSetupService creating collection structure');

    // Create a dummy document in each collection to ensure they exist
    // These will be deleted after initialization

    // Create enquiries collection
    final enquiryRef = _firestore.collection('enquiries').doc('_temp');
    await enquiryRef.set({'temp': true, 'createdAt': FieldValue.serverTimestamp()});

    // Create dropdowns collection structure
    final dropdownsRef = _firestore.collection('dropdowns').doc('_temp');
    await dropdownsRef.set({'temp': true, 'createdAt': FieldValue.serverTimestamp()});

    // Create subcollections
    await _firestore
        .collection('dropdowns')
        .doc('event_types')
        .collection('items')
        .doc('_temp')
        .set({'temp': true});

    await _firestore.collection('dropdowns').doc('statuses').collection('items').doc('_temp').set({
      'temp': true,
    });

    await _firestore
        .collection('dropdowns')
        .doc('payment_statuses')
        .collection('items')
        .doc('_temp')
        .set({'temp': true});

    // Clean up temp documents
    await enquiryRef.delete();
    await dropdownsRef.delete();
    await _firestore
        .collection('dropdowns')
        .doc('event_types')
        .collection('items')
        .doc('_temp')
        .delete();
    await _firestore
        .collection('dropdowns')
        .doc('statuses')
        .collection('items')
        .doc('_temp')
        .delete();
    await _firestore
        .collection('dropdowns')
        .doc('payment_statuses')
        .collection('items')
        .doc('_temp')
        .delete();

    Log.i('DatabaseSetupService collection structure created');
  }

  /// Initialize dropdowns with default values
  Future<void> _initializeDropdowns() async {
    Log.i('DatabaseSetupService initializing dropdowns');

    // Initialize event types
    await _initializeEventTypes();

    // Initialize statuses
    await _initializeStatuses();

    // Initialize payment statuses
    await _initializePaymentStatuses();

    Log.i('DatabaseSetupService dropdowns initialized');
  }

  /// Initialize event types dropdown
  Future<void> _initializeEventTypes() async {
    final batch = _firestore.batch();
    final collectionRef = _firestore.collection('dropdowns').doc('event_types').collection('items');

    for (final eventType in DefaultDropdownValues.eventTypes) {
      final docRef = collectionRef.doc(eventType.toLowerCase().replaceAll(' ', '_'));
      batch.set(docRef, EventTypeDocument(value: eventType).toMap());
    }

    await batch.commit();
    Log.d('DatabaseSetupService event types initialized');
  }

  /// Initialize statuses dropdown
  Future<void> _initializeStatuses() async {
    final batch = _firestore.batch();
    final collectionRef = _firestore.collection('dropdowns').doc('statuses').collection('items');

    for (final status in DefaultDropdownValues.statuses) {
      final docRef = collectionRef.doc(status.toLowerCase().replaceAll(' ', '_'));
      batch.set(docRef, StatusDocument(value: status).toMap());
    }

    await batch.commit();
    Log.d('DatabaseSetupService statuses initialized');
  }

  /// Initialize payment statuses dropdown
  Future<void> _initializePaymentStatuses() async {
    final batch = _firestore.batch();
    final collectionRef = _firestore
        .collection('dropdowns')
        .doc('payment_statuses')
        .collection('items');

    for (final paymentStatus in DefaultDropdownValues.paymentStatuses) {
      final docRef = collectionRef.doc(paymentStatus.toLowerCase().replaceAll(' ', '_'));
      batch.set(docRef, PaymentStatusDocument(value: paymentStatus).toMap());
    }

    await batch.commit();
    Log.d('DatabaseSetupService payment statuses initialized');
  }

  /// Create a sample enquiry for testing
  Future<String> createSampleEnquiry() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('No authenticated user found');
      }

      final enquiryData = EnquiryDocument(
        customerName: 'John Doe',
        customerPhone: '+1234567890',
        location: '123 Main Street, City',
        eventDate: DateTime.now().add(const Duration(days: 30)),
        eventType: 'Wedding',
        eventStatus: 'Enquired',
        notes: 'Sample enquiry for testing purposes',
        referenceImages: [],
        createdBy: currentUser.uid,
        assignedTo: null,
        createdAt: DateTime.now(),
      );

      final docRef = await _firestore.collection('enquiries').add(enquiryData.toMap());

      // Create financial subcollection
      await _firestore
          .collection('enquiries')
          .doc(docRef.id)
          .collection('financial')
          .add(
            const FinancialDocument(
              totalCost: 5000.0,
              advancePaid: 1000.0,
              paymentStatus: 'Partial',
            ).toMap(),
          );

      // Create history subcollection
      await _firestore
          .collection('enquiries')
          .doc(docRef.id)
          .collection('history')
          .add(
            HistoryDocument(
              fieldChanged: 'eventStatus',
              oldValue: '',
              newValue: 'Enquired',
              changedBy: currentUser.uid,
              timestamp: DateTime.now(),
            ).toMap(),
          );

      Log.d('DatabaseSetupService sample enquiry created', data: {'enquiryId': docRef.id});
      return docRef.id;
    } catch (e) {
      Log.e('DatabaseSetupService sample enquiry failed', error: e);
      rethrow;
    }
  }

  /// Verify database structure
  Future<Map<String, bool>> verifyDatabaseStructure() async {
    final results = <String, bool>{};

    try {
      // Check if collections exist
      await _firestore.collection('enquiries').limit(1).get();
      results['enquiries_collection'] = true;

      await _firestore.collection('dropdowns').limit(1).get();
      results['dropdowns_collection'] = true;

      // Check dropdown subcollections
      await _firestore
          .collection('dropdowns')
          .doc('event_types')
          .collection('items')
          .limit(1)
          .get();
      results['event_types_subcollection'] = true;

      await _firestore.collection('dropdowns').doc('statuses').collection('items').limit(1).get();
      results['statuses_subcollection'] = true;

      await _firestore
          .collection('dropdowns')
          .doc('payment_statuses')
          .collection('items')
          .limit(1)
          .get();
      results['payment_statuses_subcollection'] = true;

      // Check if dropdowns have data
      final eventTypesCount = await _firestore
          .collection('dropdowns')
          .doc('event_types')
          .collection('items')
          .count()
          .get();
      results['event_types_has_data'] = (eventTypesCount.count ?? 0) > 0;

      final statusesCount = await _firestore
          .collection('dropdowns')
          .doc('statuses')
          .collection('items')
          .count()
          .get();
      results['statuses_has_data'] = (statusesCount.count ?? 0) > 0;

      final paymentStatusesCount = await _firestore
          .collection('dropdowns')
          .doc('payment_statuses')
          .collection('items')
          .count()
          .get();
      results['payment_statuses_has_data'] = (paymentStatusesCount.count ?? 0) > 0;
    } catch (e) {
      Log.e('DatabaseSetupService verification failed', error: e);
      results['verification_error'] = true;
    }

    return results;
  }
}
