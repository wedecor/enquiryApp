import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:we_decor_enquiries/firebase_options.dart';

/// Script to properly set up Firestore collections and data
/// This will eliminate the loading symbols by creating the required collections
void main() async {
  print('🚀 Starting Firestore collections setup...');

  try {
    // Initialize Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    final firestore = FirebaseFirestore.instance;
    print('✅ Firebase initialized successfully');

    // Create dropdown collections
    await _createStatusesCollection(firestore);
    await _createEventTypesCollection(firestore);
    await _createPrioritiesCollection(firestore);
    await _createPaymentStatusesCollection(firestore);
    await _createBudgetRangesCollection(firestore);

    print('🎉 All Firestore collections created successfully!');
    print('📝 Next steps:');
    print('   1. Create the composite indexes in Firebase Console');
    print('   2. Restart your Flutter app');
    print('   3. Loading symbols should be eliminated');
  } catch (e) {
    print('❌ Error setting up Firestore collections: $e');
    exit(1);
  }
}

/// Create statuses collection for enquiry status dropdown
Future<void> _createStatusesCollection(FirebaseFirestore firestore) async {
  print('📋 Creating statuses collection...');

  final statusesRef = firestore
      .collection('dropdowns')
      .doc('statuses')
      .collection('items');

  final statuses = [
    {
      'value': 'new',
      'label': 'New',
      'order': 1,
      'active': true,
      'color': '#FF9800',
    },
    {
      'value': 'in_progress',
      'label': 'In Progress',
      'order': 2,
      'active': true,
      'color': '#2196F3',
    },
    {
      'value': 'quote_sent',
      'label': 'Quote Sent',
      'order': 3,
      'active': true,
      'color': '#009688',
    },
    {
      'value': 'approved',
      'label': 'Approved',
      'order': 4,
      'active': true,
      'color': '#3F51B5',
    },
    {
      'value': 'scheduled',
      'label': 'Scheduled',
      'order': 5,
      'active': true,
      'color': '#9C27B0',
    },
    {
      'value': 'completed',
      'label': 'Completed',
      'order': 6,
      'active': true,
      'color': '#4CAF50',
    },
    {
      'value': 'cancelled',
      'label': 'Cancelled',
      'order': 7,
      'active': true,
      'color': '#F44336',
    },
    {
      'value': 'closed_lost',
      'label': 'Closed Lost',
      'order': 8,
      'active': true,
      'color': '#607D8B',
    },
  ];

  final batch = firestore.batch();
  for (final status in statuses) {
    final docRef = statusesRef.doc(status['value'] as String);
    batch.set(docRef, {
      ...status,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  await batch.commit();
  print('✅ Statuses collection created with ${statuses.length} items');
}

/// Create event types collection for event type dropdown
Future<void> _createEventTypesCollection(FirebaseFirestore firestore) async {
  print('🎉 Creating event types collection...');

  final eventTypesRef = firestore
      .collection('dropdowns')
      .doc('event_types')
      .collection('items');

  final eventTypes = [
    {
      'value': 'wedding',
      'label': 'Wedding',
      'order': 1,
      'active': true,
      'category': 'celebration',
    },
    {
      'value': 'birthday',
      'label': 'Birthday Party',
      'order': 2,
      'active': true,
      'category': 'celebration',
    },
    {
      'value': 'anniversary',
      'label': 'Anniversary',
      'order': 3,
      'active': true,
      'category': 'celebration',
    },
    {
      'value': 'engagement',
      'label': 'Engagement',
      'order': 4,
      'active': true,
      'category': 'celebration',
    },
    {
      'value': 'baby_shower',
      'label': 'Baby Shower',
      'order': 5,
      'active': true,
      'category': 'celebration',
    },
    {
      'value': 'corporate_event',
      'label': 'Corporate Event',
      'order': 6,
      'active': true,
      'category': 'business',
    },
    {
      'value': 'conference',
      'label': 'Conference',
      'order': 7,
      'active': true,
      'category': 'business',
    },
    {
      'value': 'product_launch',
      'label': 'Product Launch',
      'order': 8,
      'active': true,
      'category': 'business',
    },
    {
      'value': 'graduation',
      'label': 'Graduation',
      'order': 9,
      'active': true,
      'category': 'celebration',
    },
    {
      'value': 'housewarming',
      'label': 'Housewarming',
      'order': 10,
      'active': true,
      'category': 'celebration',
    },
    {
      'value': 'festival',
      'label': 'Festival',
      'order': 11,
      'active': true,
      'category': 'cultural',
    },
    {
      'value': 'religious_ceremony',
      'label': 'Religious Ceremony',
      'order': 12,
      'active': true,
      'category': 'cultural',
    },
    {
      'value': 'other',
      'label': 'Other',
      'order': 99,
      'active': true,
      'category': 'general',
    },
  ];

  final batch = firestore.batch();
  for (final eventType in eventTypes) {
    final docRef = eventTypesRef.doc(eventType['value'] as String);
    batch.set(docRef, {
      ...eventType,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  await batch.commit();
  print('✅ Event types collection created with ${eventTypes.length} items');
}

/// Create priorities collection for priority dropdown
Future<void> _createPrioritiesCollection(FirebaseFirestore firestore) async {
  print('⚡ Creating priorities collection...');

  final prioritiesRef = firestore
      .collection('dropdowns')
      .doc('priorities')
      .collection('items');

  final priorities = [
    {
      'value': 'low',
      'label': 'Low',
      'order': 1,
      'active': true,
      'color': '#4CAF50',
    },
    {
      'value': 'medium',
      'label': 'Medium',
      'order': 2,
      'active': true,
      'color': '#FF9800',
    },
    {
      'value': 'high',
      'label': 'High',
      'order': 3,
      'active': true,
      'color': '#F44336',
    },
    {
      'value': 'urgent',
      'label': 'Urgent',
      'order': 4,
      'active': true,
      'color': '#9C27B0',
    },
  ];

  final batch = firestore.batch();
  for (final priority in priorities) {
    final docRef = prioritiesRef.doc(priority['value'] as String);
    batch.set(docRef, {
      ...priority,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  await batch.commit();
  print('✅ Priorities collection created with ${priorities.length} items');
}

/// Create payment statuses collection for payment status dropdown
Future<void> _createPaymentStatusesCollection(
  FirebaseFirestore firestore,
) async {
  print('💰 Creating payment statuses collection...');

  final paymentStatusesRef = firestore
      .collection('dropdowns')
      .doc('payment_statuses')
      .collection('items');

  final paymentStatuses = [
    {
      'value': 'pending',
      'label': 'Pending',
      'order': 1,
      'active': true,
      'color': '#FF9800',
    },
    {
      'value': 'partial',
      'label': 'Partial Payment',
      'order': 2,
      'active': true,
      'color': '#2196F3',
    },
    {
      'value': 'paid',
      'label': 'Fully Paid',
      'order': 3,
      'active': true,
      'color': '#4CAF50',
    },
    {
      'value': 'overdue',
      'label': 'Overdue',
      'order': 4,
      'active': true,
      'color': '#F44336',
    },
    {
      'value': 'refunded',
      'label': 'Refunded',
      'order': 5,
      'active': true,
      'color': '#607D8B',
    },
  ];

  final batch = firestore.batch();
  for (final paymentStatus in paymentStatuses) {
    final docRef = paymentStatusesRef.doc(paymentStatus['value'] as String);
    batch.set(docRef, {
      ...paymentStatus,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  await batch.commit();
  print(
    '✅ Payment statuses collection created with ${paymentStatuses.length} items',
  );
}

/// Create budget ranges collection for budget dropdown
Future<void> _createBudgetRangesCollection(FirebaseFirestore firestore) async {
  print('💵 Creating budget ranges collection...');

  final budgetRangesRef = firestore
      .collection('dropdowns')
      .doc('budget_ranges')
      .collection('items');

  final budgetRanges = [
    {
      'value': '0-1000',
      'label': 'Under ₹1,000',
      'order': 1,
      'active': true,
      'minValue': 0,
      'maxValue': 1000,
    },
    {
      'value': '1000-5000',
      'label': '₹1,000 - ₹5,000',
      'order': 2,
      'active': true,
      'minValue': 1000,
      'maxValue': 5000,
    },
    {
      'value': '5000-10000',
      'label': '₹5,000 - ₹10,000',
      'order': 3,
      'active': true,
      'minValue': 5000,
      'maxValue': 10000,
    },
    {
      'value': '10000-25000',
      'label': '₹10,000 - ₹25,000',
      'order': 4,
      'active': true,
      'minValue': 10000,
      'maxValue': 25000,
    },
    {
      'value': '25000-50000',
      'label': '₹25,000 - ₹50,000',
      'order': 5,
      'active': true,
      'minValue': 25000,
      'maxValue': 50000,
    },
    {
      'value': '50000-100000',
      'label': '₹50,000 - ₹1,00,000',
      'order': 6,
      'active': true,
      'minValue': 50000,
      'maxValue': 100000,
    },
    {
      'value': '100000-250000',
      'label': '₹1,00,000 - ₹2,50,000',
      'order': 7,
      'active': true,
      'minValue': 100000,
      'maxValue': 250000,
    },
    {
      'value': '250000+',
      'label': 'Above ₹2,50,000',
      'order': 8,
      'active': true,
      'minValue': 250000,
      'maxValue': null,
    },
  ];

  final batch = firestore.batch();
  for (final budgetRange in budgetRanges) {
    final docRef = budgetRangesRef.doc(budgetRange['value'] as String);
    batch.set(docRef, {
      ...budgetRange,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  await batch.commit();
  print('✅ Budget ranges collection created with ${budgetRanges.length} items');
}
