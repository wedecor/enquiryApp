import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
  print('🌱 Starting dropdown seeding...');

  try {
    // Seed event types
    await _seedEventTypes(firestore);

    // Seed statuses
    await _seedStatuses(firestore);

    // Seed payment statuses
    await _seedPaymentStatuses(firestore);

    print('✅ Dropdown seeding completed successfully!');
  } catch (e) {
    print('❌ Error during dropdown seeding: $e');
    rethrow;
  }
}

/// Seeds the event types dropdown collection
Future<void> _seedEventTypes(FirebaseFirestore firestore) async {
  print('📝 Seeding event types...');

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
  print('✅ Event types seeded: ${eventTypes.length} items');
}

/// Seeds the statuses dropdown collection
Future<void> _seedStatuses(FirebaseFirestore firestore) async {
  print('📝 Seeding statuses...');

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
  print('✅ Statuses seeded: ${statuses.length} items');
}

/// Seeds the payment statuses dropdown collection
Future<void> _seedPaymentStatuses(FirebaseFirestore firestore) async {
  print('📝 Seeding payment statuses...');

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
  print('✅ Payment statuses seeded: ${paymentStatuses.length} items');
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
Future<void> seedAdminUser(
  FirebaseAuth auth,
  FirebaseFirestore firestore,
) async {
  print('👤 Starting admin user seeding...');

  const email = 'ilyas.prime@gmail.com';
  const password = String.fromEnvironment(
    'ADMIN_PASSWORD',
    defaultValue: 'CHANGE_THIS_PASSWORD',
  ); // ⚠️ SECURITY: Set via --dart-define
  const name = 'Ilyas';
  const phone = 'N/A';
  const role = 'admin';

  try {
    // Check if user already exists in Auth
    User? existingUser;
    try {
      existingUser = auth.currentUser;
      if (existingUser == null) {
        // Try to sign in to check if user exists
        await auth.signInWithEmailAndPassword(email: email, password: password);
        existingUser = auth.currentUser;
        // Sign out after checking
        await auth.signOut();
      }
    } catch (e) {
      // User doesn't exist, we'll create it
      print('ℹ️ User does not exist in [REDACTED], will create new user');
    }

    User? user;

    if (existingUser == null) {
      // Create new user in Firebase Auth
      print('📝 Creating new user in Firebase [REDACTED]...');
      final userCredential = await auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      user = userCredential.user;
      // TODO: Replace with safeLog - print('✅ User created in Firebase Auth: ${user?.uid}');
    } else {
      user = existingUser;
      // TODO: Replace with safeLog - print('ℹ️ User already exists in Firebase Auth: ${user.uid}');
    }

    if (user == null) {
      throw Exception('Failed to get user after creation');
    }

    // Check if user document already exists in Firestore
    final userDoc = await firestore.collection('users').doc(user.uid).get();

    if (userDoc.exists) {
      print('ℹ️ User document already exists in Firestore');
      return;
    }

    // Create user document in Firestore
    print('📝 Creating user document in Firestore...');
    await firestore.collection('users').doc(user.uid).set({
      'uid': user.uid,
      'name': name,
      'email': email,
      'phone': phone,
      'role': role,
      // fcmToken removed for security - stored in private subcollection
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    print('✅ Admin user seeded successfully!');
    print('📧 Email: $email');
    // TODO: Replace with safeLog - print('🔑 Password: $password');
    print('👑 Role: $role');
    print('🆔 UID: ${user.uid}');
  } catch (e) {
    print('❌ Error during admin user seeding: $e');
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
Future<void> seedAllData(
  FirebaseFirestore firestore, {
  FirebaseAuth? auth,
}) async {
  print('🚀 Starting complete data seeding...');

  final authInstance = auth ?? FirebaseAuth.instance;

  try {
    // Seed dropdowns first
    await seedDropdowns(firestore);

    // Then seed admin user
    await seedAdminUser(authInstance, firestore);

    print('🎉 Complete data seeding finished successfully!');
  } catch (e) {
    print('❌ Error during complete data seeding: $e');
    rethrow;
  }
}
