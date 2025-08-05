import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:we_decor_enquiries/firebase_options.dart';

/// Script to manage and verify Firestore indexes
void main(List<String> args) async {
  try {
    print('🚀 Firestore Index Management Tool');
    
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
    
    if (args.isEmpty) {
      printUsage();
      return;
    }
    
    final command = args[0];
    
    switch (command) {
      case 'verify':
        await verifyIndexes(firestore);
        break;
      case 'test-queries':
        await testQueries(firestore);
        break;
      case 'help':
        printUsage();
        break;
      default:
        print('❌ Unknown command: $command');
        printUsage();
    }
    
  } catch (e) {
    print('❌ Error: $e');
    exit(1);
  }
}

void printUsage() {
  print('\n📖 Usage:');
  print('  dart run scripts/manage_indexes.dart verify     - Verify index status');
  print('  dart run scripts/manage_indexes.dart test-queries - Test queries that require indexes');
  print('  dart run scripts/manage_indexes.dart help        - Show this help');
  print('\n🔧 Commands:');
  print('  verify      - Check if required indexes exist and are ready');
  print('  test-queries - Test queries that require composite indexes');
  print('  help        - Display usage information');
}

Future<void> verifyIndexes(FirebaseFirestore firestore) async {
  print('\n🔍 Verifying Firestore Indexes...');
  
  // Note: Firestore doesn't provide a direct API to check index status
  // This is a simulation of what would be checked
  print('📋 Required Indexes:');
  print('  1. enquiries: eventStatus + assignedTo (for filtering)');
  print('  2. enquiries: eventType + createdAt (for ordering)');
  print('  3. enquiries: assignedTo + createdAt (for filtering and ordering)');
  print('  4. enquiries: eventStatus + createdAt (for filtering and ordering)');
  print('  5. enquiries: createdBy + createdAt (for filtering and ordering)');
  print('  6. enquiries: eventType + createdAt (for filtering and ordering)');
  
  print('\n💡 To check index status:');
  print('  1. Go to Firebase Console → Firestore → Indexes');
  print('  2. Look for indexes with status "Enabled"');
  print('  3. If any show "Building", wait for them to complete');
  
  print('\n🚀 To deploy indexes:');
  print('  firebase deploy --only firestore:indexes');
}

Future<void> testQueries(FirebaseFirestore firestore) async {
  print('\n🧪 Testing Queries That Require Indexes...');
  
  try {
    // Test 1: Filter by eventStatus + assignedTo
    print('\n📊 Test 1: Filter by eventStatus + assignedTo');
    try {
      final query1 = await firestore
          .collection('enquiries')
          .where('eventStatus', isEqualTo: 'Enquired')
          .where('assignedTo', isEqualTo: 'test-user')
          .limit(5)
          .get();
      print('✅ Query 1 successful: ${query1.docs.length} results');
    } catch (e) {
      print('❌ Query 1 failed: $e');
      print('   This query requires an index on eventStatus + assignedTo');
    }
    
    // Test 2: Order by createdAt + filter by eventType
    print('\n📊 Test 2: Order by createdAt + filter by eventType');
    try {
      final query2 = await firestore
          .collection('enquiries')
          .where('eventType', isEqualTo: 'Wedding')
          .orderBy('createdAt', descending: true)
          .limit(5)
          .get();
      print('✅ Query 2 successful: ${query2.docs.length} results');
    } catch (e) {
      print('❌ Query 2 failed: $e');
      print('   This query requires an index on eventType + createdAt');
    }
    
    // Test 3: Filter by assignedTo + order by createdAt
    print('\n📊 Test 3: Filter by assignedTo + order by createdAt');
    try {
      final query3 = await firestore
          .collection('enquiries')
          .where('assignedTo', isEqualTo: 'test-user')
          .orderBy('createdAt', descending: true)
          .limit(5)
          .get();
      print('✅ Query 3 successful: ${query3.docs.length} results');
    } catch (e) {
      print('❌ Query 3 failed: $e');
      print('   This query requires an index on assignedTo + createdAt');
    }
    
    // Test 4: Filter by eventStatus + order by createdAt
    print('\n📊 Test 4: Filter by eventStatus + order by createdAt');
    try {
      final query4 = await firestore
          .collection('enquiries')
          .where('eventStatus', isEqualTo: 'In Progress')
          .orderBy('createdAt', descending: true)
          .limit(5)
          .get();
      print('✅ Query 4 successful: ${query4.docs.length} results');
    } catch (e) {
      print('❌ Query 4 failed: $e');
      print('   This query requires an index on eventStatus + createdAt');
    }
    
    // Test 5: Filter by createdBy + order by createdAt
    print('\n📊 Test 5: Filter by createdBy + order by createdAt');
    try {
      final query5 = await firestore
          .collection('enquiries')
          .where('createdBy', isEqualTo: 'test-user')
          .orderBy('createdAt', descending: true)
          .limit(5)
          .get();
      print('✅ Query 5 successful: ${query5.docs.length} results');
    } catch (e) {
      print('❌ Query 5 failed: $e');
      print('   This query requires an index on createdBy + createdAt');
    }
    
  } catch (e) {
    print('❌ Error during query testing: $e');
  }
  
  print('\n💡 If any queries failed, you need to:');
  print('  1. Deploy the indexes: firebase deploy --only firestore:indexes');
  print('  2. Wait for indexes to build (check Firebase Console)');
  print('  3. Re-run this test');
} 