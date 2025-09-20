import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:we_decor_enquiries/firebase_options.dart';
import 'package:we_decor_enquiries/shared/seed_data.dart';

/// Test script for seeding data
///
/// This script can be run to test the seed data functions:
/// ```bash
/// dart run scripts/seed_data_test.dart
/// ```
void main() async {
  try {
    print('🚀 Starting seed data test...');

    // Initialize Firebase
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

    // Connect to Firestore emulator if running locally
    if (const bool.fromEnvironment('USE_FIRESTORE_EMULATOR')) {
      FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080);
      print('📡 Connected to Firestore emulator');
    }

    final firestore = FirebaseFirestore.instance;
    final auth = FirebaseAuth.instance;

    // Test seeding dropdowns
    print('\n🌱 Testing dropdown seeding...');
    await seedDropdowns(firestore);

    // Test seeding admin user
    print('\n👤 Testing admin user seeding...');
    await seedAdminUser(auth, firestore);

    // Test complete seeding
    print('\n🚀 Testing complete data seeding...');
    await seedAllData(firestore, auth: auth);

    print('\n✅ All seed data tests completed successfully!');
  } catch (e) {
    print('❌ Error during seed data test: $e');
    exit(1);
  }
}
