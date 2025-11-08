import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import '../firebase_options.dart';
import '../utils/logger.dart';
import 'seed_data.dart';

void _info(String message, {Object? data}) => Log.i(message, data: data);
void _error(String message, Object error, {StackTrace? stackTrace}) =>
    Log.e(message, error: error, stackTrace: stackTrace);

/// One-time seeding script for We Decor Enquiries application
///
/// This script ensures that initial data (dropdowns and admin user) is seeded
/// only once by using a flag document in Firestore. It prevents duplicate
/// seeding operations and handles the seeding process independently.
///
/// Usage:
/// ```bash
/// flutter run -d chrome --target=lib/shared/one_time_seed.dart
/// ```
///
/// The script will:
/// 1. Check if data has already been seeded
/// 2. If not seeded, populate dropdowns and create admin user
/// 3. Set a flag to prevent future seeding
/// 4. Provide detailed logging throughout the process

/// Main entry point for the one-time seeding script
///
/// This function initializes Flutter and Firebase, then runs the seeding
/// process if it hasn't been completed before.
///
/// The script is designed to be run independently from the main application
/// to avoid authentication and permission issues during app startup.
void main() async {
  _info('🚀 Starting one-time seeding script');

  // Initialize Flutter bindings
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase with platform-specific options
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  _info('✅ Firebase initialized successfully');

  // Uncomment the next line to reset the seed flag and force re-seeding
  await resetSeedFlag();

  // Run the seeding process
  await runSeedIfNeeded();

  _info('🎉 Seeding script completed');

  // Keep the app running for a moment to see the output
  await Future.delayed(const Duration(seconds: 3));
}

/// Checks if data has already been seeded and runs seeding if needed
///
/// This function:
/// 1. Checks the `meta/seed_status` document in Firestore
/// 2. If `isSeeded` is true, logs and exits
/// 3. If not seeded, runs the complete seeding process
/// 4. Sets the seed flag after successful completion
///
/// The function handles all errors gracefully and provides detailed logging.
Future<void> runSeedIfNeeded() async {
  final firestore = FirebaseFirestore.instance;
  final auth = FirebaseAuth.instance;

  try {
    _info('🔍 Checking if data has already been seeded');

    // Check if seeding has already been completed
    final seedStatusDoc = await firestore.collection('meta').doc('seed_status').get();

    if (seedStatusDoc.exists && seedStatusDoc.data()?['isSeeded'] == true) {
      final timestamp = seedStatusDoc.data()?['timestamp'];
      _info('✅ Data already seeded', data: {'timestamp': timestamp});
      _info('🔄 Skipping seeding process');
      return;
    }

    _info('🌱 Data not seeded yet. Starting seeding process');

    // Run the complete seeding process
    await seedAllData(firestore, auth: auth);

    // Set the seed flag to prevent future seeding
    _info('📝 Setting seed completion flag');
    await firestore.collection('meta').doc('seed_status').set({
      'isSeeded': true,
      'timestamp': FieldValue.serverTimestamp(),
      'seededBy': 'one_time_seed.dart',
      'version': '1.0.0',
    });

    _info('✅ Seed completion flag set successfully');
    _info('🎉 One-time seeding completed successfully');
  } catch (e, st) {
    _error('❌ Error during seeding process', e, stackTrace: st);
    _info('💡 Please check your Firebase configuration and permissions');
    rethrow;
  }
}

/// Alternative function to reset the seed flag (for development/testing)
///
/// This function can be used to reset the seeding flag, allowing the
/// seeding process to run again. Use with caution in production.
///
/// Example usage:
/// ```dart
/// await resetSeedFlag();
/// ```
Future<void> resetSeedFlag() async {
  final firestore = FirebaseFirestore.instance;

  try {
    _info('🔄 Resetting seed flag');

    await firestore.collection('meta').doc('seed_status').delete();

    _info('✅ Seed flag reset successfully');
    _info('💡 You can now run the seeding process again');
  } catch (e, st) {
    _error('❌ Error resetting seed flag', e, stackTrace: st);
    rethrow;
  }
}

/// Function to check the current seeding status
///
/// This function retrieves and displays the current seeding status
/// without modifying anything.
///
/// Example usage:
/// ```dart
/// await checkSeedStatus();
/// ```
Future<void> checkSeedStatus() async {
  final firestore = FirebaseFirestore.instance;

  try {
    _info('🔍 Checking current seeding status');

    final seedStatusDoc = await firestore.collection('meta').doc('seed_status').get();

    if (seedStatusDoc.exists) {
      final data = seedStatusDoc.data()!;
      _info(
        '📊 Current seeding status',
        data: {
          'isSeeded': data['isSeeded'],
          'timestamp': data['timestamp'],
          'seededBy': data['seededBy'],
          'version': data['version'],
        },
      );
    } else {
      _info('📊 Current seeding status', data: {'status': 'NOT SEEDED'});
    }
  } catch (e, st) {
    _error('❌ Error checking seed status', e, stackTrace: st);
    rethrow;
  }
}
