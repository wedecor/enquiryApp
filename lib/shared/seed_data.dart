import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../utils/logger.dart';

/// Seed data utilities for populating Firestore collections with initial data
///
/// This file contains functions to populate dropdown collections and create
/// initial admin users for the We Decor Enquiries application.
///
/// Usage:
/// ```dart
/// // Seed dropdowns
/// await seedDropdowns(FirebaseFirestore.instance);
///
/// // Seed admin user
/// await seedAdminUser(FirebaseAuth.instance, FirebaseFirestore.instance);
/// ```

/// Seeds the dropdown collections with predefined values
///
/// This function populates three dropdown collections:
/// - `dropdowns/event_types/` - Event type options
/// - `dropdowns/statuses/` - Enquiry status options
/// - `dropdowns/payment_statuses/` - Payment status options
///
/// Each document uses `set()` for upsert behavior (overwrites existing).
/// All operations are wrapped in try-catch blocks with detailed logging.
///
/// Parameters:
/// - [firestore]: FirebaseFirestore instance
///
/// Example:
/// ```dart
/// await seedDropdowns(FirebaseFirestore.instance);
/// ```
Future<void> seedDropdowns(FirebaseFirestore firestore) async {
  Log.i('Dropdown seeding started');

  try {
    // Seed event types
    await _seedEventTypes(firestore);

    // Seed statuses
    await _seedStatuses(firestore);

    // Seed payment statuses
    await _seedPaymentStatuses(firestore);

    Log.i('Dropdown seeding completed');
  } catch (e) {
    Log.e('Dropdown seeding failed', error: e);
    rethrow;
  }
}

/// Seeds the event types dropdown collection
Future<void> _seedEventTypes(FirebaseFirestore firestore) async {
  Log.i('Seeding event types');

  final eventTypes = {
    'birthday': 'Birthday',
    'wedding': 'Wedding',
    'haldi': 'Haldi',
    'mehendi': 'Mehendi',
    'anniversary': 'Anniversary',
    'engagement': 'Engagement',
    'naming': 'Naming',
    'aqiqah': 'Aqiqah',
    'cradle_ceremony': 'Cradle Ceremony',
    'baby_shower': 'Baby Shower',
    'welcome_baby': 'Welcome Baby',
    'corporate': 'Corporate',
    'farewell': 'Farewell',
    'retirement': 'Retirement',
    'house_warming': 'House Warming',
    'reception': 'Reception',
    'romantic_surprise': 'Romantic Surprise',
    'proposal': 'Proposal',
    'nikkah': 'Nikkah',
    'other': 'Other',
  };

  final batch = firestore.batch();

  for (final entry in eventTypes.entries) {
    final docRef = firestore
        .collection('dropdowns')
        .doc('event_types')
        .collection('items')
        .doc(entry.key);

    batch.set(docRef, {
      'value': entry.value,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  await batch.commit();
  Log.i('Event types seeded', data: {'count': eventTypes.length});
}

/// Seeds the statuses dropdown collection
Future<void> _seedStatuses(FirebaseFirestore firestore) async {
  Log.i('Seeding statuses');

  final statuses = {
    'enquired': 'Enquired',
    'confirmed': 'Confirmed',
    'assigned': 'Assigned',
    'not_interested': 'Not Interested',
    'completed': 'Completed',
  };

  final batch = firestore.batch();

  for (final entry in statuses.entries) {
    final docRef = firestore
        .collection('dropdowns')
        .doc('statuses')
        .collection('items')
        .doc(entry.key);

    batch.set(docRef, {
      'value': entry.value,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  await batch.commit();
  Log.i('Statuses seeded', data: {'count': statuses.length});
}

/// Seeds the payment statuses dropdown collection
Future<void> _seedPaymentStatuses(FirebaseFirestore firestore) async {
  Log.i('Seeding payment statuses');

  final paymentStatuses = {
    'no_payment': 'No Payment',
    'advance_paid': 'Advance Paid',
    'full_payment': 'Full Payment',
    'refund': 'Refund',
  };

  final batch = firestore.batch();

  for (final entry in paymentStatuses.entries) {
    final docRef = firestore
        .collection('dropdowns')
        .doc('payment_statuses')
        .collection('items')
        .doc(entry.key);

    batch.set(docRef, {
      'value': entry.value,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  await batch.commit();
  Log.i('Payment statuses seeded', data: {'count': paymentStatuses.length});
}

/// Creates an admin user in Firebase Auth and Firestore
///
/// This function creates a user account with admin privileges:
/// - Creates Firebase Auth user with email/password
/// - Creates corresponding Firestore document in users/ collection
/// - Sets role to "admin" for full system access
///
/// The function is idempotent - if the user already exists, it skips creation.
///
/// Parameters:
/// - [auth]: FirebaseAuth instance
/// - [firestore]: FirebaseFirestore instance
///
/// Example:
/// ```dart
/// await seedAdminUser(FirebaseAuth.instance, FirebaseFirestore.instance);
/// ```
Future<void> seedAdminUser(FirebaseAuth auth, FirebaseFirestore firestore) async {
  const email = 'ilyas.prime@gmail.com';
  const password = String.fromEnvironment(
    'ADMIN_PASSWORD',
    defaultValue: 'CHANGE_THIS_PASSWORD',
  ); // ⚠️ SECURITY: Set via --dart-define
  const name = 'Ilyas';
  const phone = 'N/A';
  const role = 'admin';

  Log.i('Admin user seeding started', data: {'email': email});

  try {
    User? existingUser;
    try {
      existingUser = auth.currentUser;
      if (existingUser == null) {
        await auth.signInWithEmailAndPassword(email: email, password: password);
        existingUser = auth.currentUser;
        await auth.signOut();
      }
    } catch (_) {
      Log.i('Admin seeding: user not found, will create');
    }

    User? user;

    if (existingUser == null) {
      Log.i('Admin seeding: creating Firebase Auth user');
      final userCredential = await auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      user = userCredential.user;
    } else {
      user = existingUser;
      Log.i('Admin seeding: user already exists in Firebase Auth');
    }

    if (user == null) {
      throw Exception('Failed to get user after creation');
    }

    final userDoc = await firestore.collection('users').doc(user.uid).get();

    if (userDoc.exists) {
      Log.i('Admin seeding: user document already exists in Firestore', data: {'uid': user.uid});
      return;
    }

    Log.i('Admin seeding: creating Firestore user document');
    await firestore.collection('users').doc(user.uid).set({
      'uid': user.uid,
      'name': name,
      'email': email,
      'phone': phone,
      'role': role,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await firestore.collection('userRoles').doc(user.uid).set({
      'uid': user.uid,
      'role': role,
      'assignedAt': FieldValue.serverTimestamp(),
    });

    Log.i('Admin user seeded successfully', data: {'email': email, 'role': role, 'uid': user.uid});
  } catch (e) {
    Log.e('Admin user seeding failed', error: e);
    rethrow;
  }
}

/// Convenience function to seed all data at once
///
/// This function calls both [seedDropdowns] and [seedAdminUser]
/// in sequence, providing a complete initial setup for the application.
///
/// Parameters:
/// - [firestore]: FirebaseFirestore instance
/// - [auth]: FirebaseAuth instance (optional, defaults to FirebaseAuth.instance)
///
/// Example:
/// ```dart
/// await seedAllData(FirebaseFirestore.instance);
/// ```
Future<void> seedAll(FirebaseAuth auth, FirebaseFirestore firestore) async {
  Log.i('Complete data seeding started');

  try {
    await seedDropdowns(firestore);
    await seedAdminUser(auth, firestore);

    Log.i('Complete data seeding finished');
  } catch (e) {
    Log.e('Complete data seeding failed', error: e);
    rethrow;
  }
}

@Deprecated('Use seedAll with explicit auth and firestore instances')
Future<void> seedAllData(FirebaseFirestore firestore, {FirebaseAuth? auth}) {
  final resolvedAuth = auth ?? FirebaseAuth.instance;
  return seedAll(resolvedAuth, firestore);
}
