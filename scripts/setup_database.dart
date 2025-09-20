import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:we_decor_enquiries/core/services/database_setup_service.dart';
import 'package:we_decor_enquiries/firebase_options.dart';

/// Standalone script to set up the Firestore database structure
/// Run this script to reset and initialize the database with the correct schema
void main() async {
  try {
    print('🚀 Starting We Decor Enquiries Database Setup...');

    // Initialize Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Connect to Firestore emulator if running locally
    if (const bool.fromEnvironment('USE_FIRESTORE_EMULATOR')) {
      FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080);
      print('📡 Connected to Firestore emulator');
    }

    // Initialize the database setup service
    final setupService = DatabaseSetupService();

    // Reset and initialize the database
    print('🔄 Resetting and initializing database...');
    await setupService.resetAndInitializeDatabase();

    // Verify the database structure
    print('✅ Verifying database structure...');
    final verificationResults = await setupService.verifyDatabaseStructure();

    // Print verification results
    print('\n📊 Database Structure Verification Results:');
    verificationResults.forEach((key, value) {
      final status = value ? '✅' : '❌';
      print('$status $key: ${value ? 'PASS' : 'FAIL'}');
    });

    // Create a sample enquiry for testing
    print('\n🧪 Creating sample enquiry for testing...');
    final sampleEnquiryId = await setupService.createSampleEnquiry();
    print('✅ Sample enquiry created with ID: $sampleEnquiryId');

    print('\n🎉 Database setup completed successfully!');
    print('📝 The database now contains:');
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
    print('❌ Error during database setup: $e');
    exit(1);
  }
}
