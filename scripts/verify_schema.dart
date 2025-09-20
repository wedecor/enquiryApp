import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:we_decor_enquiries/core/services/schema_verification_service.dart';
import 'package:we_decor_enquiries/firebase_options.dart';

/// Standalone script for schema verification
void main(List<String> args) async {
  try {
    print('🔍 We Decor Enquiries - Schema Verification Tool');
    print('================================================');

    // Initialize Firebase
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

    // Connect to Firestore emulator if running locally
    if (const bool.fromEnvironment('USE_FIRESTORE_EMULATOR')) {
      FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080);
      print('📡 Connected to Firestore emulator');
    }

    final schemaService = SchemaVerificationService();

    if (args.isEmpty) {
      await _runFullVerification(schemaService);
    } else {
      final command = args[0];
      switch (command) {
        case 'verify':
          await _runFullVerification(schemaService);
          break;
        case 'report':
          await _generateReport(schemaService, args.length > 1 ? args[1] : null);
          break;
        case 'quick':
          await _runQuickVerification(schemaService);
          break;
        case 'help':
          _printUsage();
          break;
        default:
          print('❌ Unknown command: $command');
          _printUsage();
      }
    }
  } catch (e) {
    print('❌ Error during schema verification: $e');
    exit(1);
  }
}

/// Run full schema verification
Future<void> _runFullVerification(SchemaVerificationService schemaService) async {
  print('\n🚀 Starting full schema verification...');
  print('⏳ This may take a few moments...\n');

  final startTime = DateTime.now();
  final results = await schemaService.verifyAllSchemas();
  final endTime = DateTime.now();
  final duration = endTime.difference(startTime);

  print('\n📊 Schema Verification Results');
  print('==============================');
  print('⏱️  Duration: ${duration.inMilliseconds}ms\n');

  int totalErrors = 0;
  int totalWarnings = 0;
  int validCollections = 0;

  for (final entry in results.entries) {
    final collectionName = entry.key;
    final result = entry.value;

    final status = result.isValid ? '✅ Valid' : '❌ Invalid';
    print('📋 $collectionName: $status');

    if (result.isValid) {
      validCollections++;
    }

    // Display details
    if (result.details.isNotEmpty) {
      final details = result.details;
      if (details.containsKey('totalDocuments')) {
        print(
          '   📄 Documents: ${details['totalDocuments']} total, ${details['validDocuments']} valid, ${details['invalidDocuments']} invalid',
        );
      }
    }

    // Display errors
    if (result.errors.isNotEmpty) {
      totalErrors += result.errors.length;
      print('   ❌ Errors: ${result.errors.length}');
      for (final error in result.errors.take(3)) {
        print('      • $error');
      }
      if (result.errors.length > 3) {
        print('      ... and ${result.errors.length - 3} more errors');
      }
    }

    // Display warnings
    if (result.warnings.isNotEmpty) {
      totalWarnings += result.warnings.length;
      print('   ⚠️  Warnings: ${result.warnings.length}');
      for (final warning in result.warnings.take(2)) {
        print('      • $warning');
      }
      if (result.warnings.length > 2) {
        print('      ... and ${result.warnings.length - 2} more warnings');
      }
    }

    print('');
  }

  // Summary
  print('📈 Summary');
  print('==========');
  print('✅ Valid Collections: $validCollections/${results.length}');
  print('❌ Total Errors: $totalErrors');
  print('⚠️  Total Warnings: $totalWarnings');
  print('');

  if (totalErrors == 0) {
    print('🎉 All collections passed schema verification!');
  } else {
    print('🔧 Please fix the errors above before proceeding.');
  }
}

/// Run quick schema verification
Future<void> _runQuickVerification(SchemaVerificationService schemaService) async {
  print('\n⚡ Starting quick schema verification...');
  print('⏳ Checking collection structure only...\n');

  final startTime = DateTime.now();

  try {
    final firestore = FirebaseFirestore.instance;
    final collections = ['users', 'enquiries', 'dropdowns'];
    int validCollections = 0;

    for (final collectionName in collections) {
      try {
        final snapshot = await firestore.collection(collectionName).limit(1).get();
        print('✅ $collectionName: Collection exists (${snapshot.docs.length} sample documents)');
        validCollections++;
      } catch (e) {
        print('❌ $collectionName: Error accessing collection - $e');
      }
    }

    final endTime = DateTime.now();
    final duration = endTime.difference(startTime);

    print('\n📊 Quick Verification Summary');
    print('============================');
    print('✅ Valid Collections: $validCollections/${collections.length}');
    print('⏱️  Duration: ${duration.inMilliseconds}ms');

    if (validCollections == collections.length) {
      print('\n🎉 All collections are accessible!');
    } else {
      print('\n🔧 Some collections may have issues.');
    }
  } catch (e) {
    print('❌ Quick verification failed: $e');
  }
}

/// Generate detailed report
Future<void> _generateReport(SchemaVerificationService schemaService, String? outputFile) async {
  print('\n📝 Generating detailed schema report...');

  final report = await schemaService.generateSchemaReport();

  if (outputFile != null) {
    final file = File(outputFile);
    await file.writeAsString(report);
    print('✅ Report saved to: $outputFile');
  } else {
    print('\n$report');
  }
}

/// Print usage information
void _printUsage() {
  print('\n📖 Schema Verification Tool Usage:');
  print('  dart run scripts/verify_schema.dart              - Run full verification');
  print('  dart run scripts/verify_schema.dart verify        - Run full verification');
  print('  dart run scripts/verify_schema.dart quick         - Run quick verification');
  print('  dart run scripts/verify_schema.dart report [file] - Generate detailed report');
  print('  dart run scripts/verify_schema.dart help          - Show this help');
  print('\n🔧 Commands:');
  print('  verify - Run complete schema verification (default)');
  print('  quick  - Run quick collection accessibility check');
  print('  report - Generate detailed verification report');
  print('  help   - Display usage information');
  print('\n💡 Examples:');
  print('  dart run scripts/verify_schema.dart');
  print('  dart run scripts/verify_schema.dart quick');
  print('  dart run scripts/verify_schema.dart report schema_report.txt');
  print('\n🔍 What gets verified:');
  print('  • Users collection schema compliance');
  print('  • Enquiries collection schema compliance');
  print('  • Financial subcollection schema compliance');
  print('  • History subcollection schema compliance');
  print('  • Dropdowns collection schema compliance');
  print('  • Field types and required fields');
  print('  • Data validation rules');
}
