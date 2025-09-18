import 'dart:convert';
import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:we_decor_enquiries/firebase_options.dart';
import 'package:we_decor_enquiries/core/services/schema_verification_service.dart';

/// Firebase Data Manager for export/import operations
class FirebaseDataManager {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final SchemaVerificationService _schemaService = SchemaVerificationService();

  /// Export all data from Firebase to local files
  Future<void> exportAllData({String? outputDir}) async {
    final dir = outputDir ?? 'firebase_export_${DateTime.now().millisecondsSinceEpoch}';
    await Directory(dir).create(recursive: true);

    print('🚀 Starting Firebase data export...');
    print('📁 Export directory: $dir');

    try {
      // Export users collection
      await _exportCollection('users', dir);

      // Export enquiries collection with subcollections
      await _exportCollectionWithSubcollections('enquiries', dir);

      // Export dropdowns collection
      await _exportDropdowns(dir);

      // Export schema verification report
      await _exportSchemaReport(dir);

      print('✅ Export completed successfully!');
      print('📁 Data exported to: $dir');

    } catch (e) {
      print('❌ Export failed: $e');
      rethrow;
    }
  }

  /// Import data from local files to Firebase
  Future<void> importAllData({required String inputDir}) async {
    if (!await Directory(inputDir).exists()) {
      throw Exception('Import directory does not exist: $inputDir');
    }

    print('🚀 Starting Firebase data import...');
    print('📁 Import directory: $inputDir');

    try {
      // Import users collection
      await _importCollection('users', inputDir);

      // Import enquiries collection with subcollections
      await _importCollectionWithSubcollections('enquiries', inputDir);

      // Import dropdowns collection
      await _importDropdowns(inputDir);

      print('✅ Import completed successfully!');

    } catch (e) {
      print('❌ Import failed: $e');
      rethrow;
    }
  }

  /// Export a single collection
  Future<void> _exportCollection(String collectionName, String outputDir) async {
    print('📤 Exporting collection: $collectionName');

    final snapshot = await _firestore.collection(collectionName).get();
    final documents = <String, dynamic>{};

    for (final doc in snapshot.docs) {
      documents[doc.id] = doc.data();
    }

    final file = File('$outputDir/${collectionName}.json');
    await file.writeAsString(jsonEncode(documents, toEncodable: _jsonEncoder));

    print('   ✅ Exported ${documents.length} documents');
  }

  /// Export collection with subcollections
  Future<void> _exportCollectionWithSubcollections(String collectionName, String outputDir) async {
    print('📤 Exporting collection with subcollections: $collectionName');

    final snapshot = await _firestore.collection(collectionName).get();
    final documents = <String, dynamic>{};

    for (final doc in snapshot.docs) {
      final docData = doc.data();
      final subcollections = <String, dynamic>{};

      // Export financial subcollection
      try {
        final financialSnapshot = await doc.reference.collection('financial').get();
        final financialDocs = <String, dynamic>{};
        for (final financialDoc in financialSnapshot.docs) {
          financialDocs[financialDoc.id] = financialDoc.data();
        }
        subcollections['financial'] = financialDocs;
      } catch (e) {
        print('   ⚠️  Could not export financial subcollection for ${doc.id}: $e');
      }

      // Export history subcollection
      try {
        final historySnapshot = await doc.reference.collection('history').get();
        final historyDocs = <String, dynamic>{};
        for (final historyDoc in historySnapshot.docs) {
          historyDocs[historyDoc.id] = historyDoc.data();
        }
        subcollections['history'] = historyDocs;
      } catch (e) {
        print('   ⚠️  Could not export history subcollection for ${doc.id}: $e');
      }

      docData['_subcollections'] = subcollections;
      documents[doc.id] = docData;
    }

    final file = File('$outputDir/${collectionName}_with_subcollections.json');
    await file.writeAsString(jsonEncode(documents, toEncodable: _jsonEncoder));

    print('   ✅ Exported ${documents.length} documents with subcollections');
  }

  /// Export dropdowns collection
  Future<void> _exportDropdowns(String outputDir) async {
    print('📤 Exporting dropdowns collection');

    final dropdownTypes = ['event_types', 'statuses', 'payment_statuses'];
    final dropdowns = <String, dynamic>{};

    for (final dropdownType in dropdownTypes) {
      try {
        final itemsSnapshot = await _firestore
            .collection('dropdowns')
            .doc(dropdownType)
            .collection('items')
            .get();

        final items = <String, dynamic>{};
        for (final doc in itemsSnapshot.docs) {
          items[doc.id] = doc.data();
        }
        dropdowns[dropdownType] = items;
      } catch (e) {
        print('   ⚠️  Could not export dropdown type $dropdownType: $e');
      }
    }

    final file = File('$outputDir/dropdowns.json');
    await file.writeAsString(jsonEncode(dropdowns, toEncodable: _jsonEncoder));

    print('   ✅ Exported dropdowns data');
  }

  /// Export schema verification report
  Future<void> _exportSchemaReport(String outputDir) async {
    print('📤 Exporting schema verification report');

    final report = await _schemaService.generateSchemaReport();
    final file = File('$outputDir/schema_report.txt');
    await file.writeAsString(report);

    print('   ✅ Exported schema report');
  }

  /// Import a single collection
  Future<void> _importCollection(String collectionName, String inputDir) async {
    print('📥 Importing collection: $collectionName');

    final file = File('$inputDir/${collectionName}.json');
    if (!await file.exists()) {
      print('   ⚠️  File not found: ${file.path}');
      return;
    }

    final content = await file.readAsString();
    final documents = jsonDecode(content) as Map<String, dynamic>;

    int importedCount = 0;
    for (final entry in documents.entries) {
      try {
        await _firestore.collection(collectionName).doc(entry.key).set(Map<String, dynamic>.from(entry.value as Map));
        importedCount++;
      } catch (e) {
        // TODO: Replace with safeLog - print('   ❌ Failed to import document ${entry.key}: $e');
      }
    }

    print('   ✅ Imported $importedCount documents');
  }

  /// Import collection with subcollections
  Future<void> _importCollectionWithSubcollections(String collectionName, String inputDir) async {
    print('📥 Importing collection with subcollections: $collectionName');

    final file = File('$inputDir/${collectionName}_with_subcollections.json');
    if (!await file.exists()) {
      print('   ⚠️  File not found: ${file.path}');
      return;
    }

    final content = await file.readAsString();
    final documents = jsonDecode(content) as Map<String, dynamic>;

    int importedCount = 0;
    for (final entry in documents.entries) {
      try {
        final docData = Map<String, dynamic>.from(entry.value as Map);
        final subcollections = docData.remove('_subcollections') as Map<dynamic, dynamic>?;

        // Import main document
        await _firestore.collection(collectionName).doc(entry.key).set(docData);

        // Import subcollections
        if (subcollections != null) {
          // Import financial subcollection
          if (subcollections.containsKey('financial')) {
            final financialDocs = subcollections['financial'] as Map<String, dynamic>;
            for (final financialEntry in financialDocs.entries) {
              await _firestore
                  .collection(collectionName)
                  .doc(entry.key)
                  .collection('financial')
                  .doc(financialEntry.key)
                  .set(Map<String, dynamic>.from(financialEntry.value as Map));
            }
          }

          // Import history subcollection
          if (subcollections.containsKey('history')) {
            final historyDocs = subcollections['history'] as Map<dynamic, dynamic>;
            for (final historyEntry in historyDocs.entries) {
              await _firestore
                  .collection(collectionName)
                  .doc(entry.key)
                  .collection('history')
                  .doc(historyEntry.key)
                  .set(Map<String, dynamic>.from(historyEntry.value as Map));
            }
          }
        }

        importedCount++;
      } catch (e) {
        // TODO: Replace with safeLog - print('   ❌ Failed to import document ${entry.key}: $e');
      }
    }

    print('   ✅ Imported $importedCount documents with subcollections');
  }

  /// Import dropdowns collection
  Future<void> _importDropdowns(String inputDir) async {
    print('📥 Importing dropdowns collection');

    final file = File('$inputDir/dropdowns.json');
    if (!await file.exists()) {
      print('   ⚠️  File not found: ${file.path}');
      return;
    }

    final content = await file.readAsString();
    final dropdowns = jsonDecode(content) as Map<String, dynamic>;

    int importedCount = 0;
    for (final dropdownType in dropdowns.keys) {
      final items = dropdowns[dropdownType] as Map<String, dynamic>;
      for (final itemEntry in items.entries) {
        try {
          await _firestore
              .collection('dropdowns')
              .doc(dropdownType)
              .collection('items')
              .doc(itemEntry.key)
              .set(Map<String, dynamic>.from(itemEntry.value as Map));
          importedCount++;
        } catch (e) {
          // TODO: Replace with safeLog - print('   ❌ Failed to import dropdown item ${itemEntry.key}: $e');
        }
      }
    }

    print('   ✅ Imported $importedCount dropdown items');
  }

  /// Custom JSON encoder for Firestore data
  dynamic _jsonEncoder(dynamic obj) {
    if (obj is Timestamp) {
      return {
        '_type': 'timestamp',
        'seconds': obj.seconds,
        'nanoseconds': obj.nanoseconds,
      };
    }
    if (obj is DateTime) {
      return {
        '_type': 'datetime',
        'iso8601': obj.toIso8601String(),
      };
    }
    return obj;
  }

  /// Generate backup summary
  Future<String> generateBackupSummary(String backupDir) async {
    final summary = StringBuffer();

    summary.writeln('📊 Firebase Backup Summary');
    summary.writeln('Generated: ${DateTime.now().toIso8601String()}');
    summary.writeln('Backup Directory: $backupDir');
    summary.writeln('');

    final files = [
      'users.json',
      'enquiries_with_subcollections.json',
      'dropdowns.json',
      'schema_report.txt',
    ];

    for (final file in files) {
      final filePath = '$backupDir/$file';
      if (await File(filePath).exists()) {
        final fileSize = await File(filePath).length();
        summary.writeln('✅ $file (${_formatFileSize(fileSize)})');
      } else {
        summary.writeln('❌ $file (not found)');
      }
    }

    return summary.toString();
  }

  /// Format file size for display
  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
  }
}

/// Main function for CLI usage
void main(List<String> args) async {
  try {
    // Initialize Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Connect to Firestore emulator if running locally
    if (const bool.fromEnvironment('USE_FIRESTORE_EMULATOR')) {
      FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080);
      print('📡 Connected to Firestore emulator');
    }

    final dataManager = FirebaseDataManager();

    if (args.isEmpty) {
      printUsage();
      return;
    }

    final command = args[0];

    switch (command) {
      case 'export':
        final outputDir = args.length > 1 ? args[1] : null;
        await dataManager.exportAllData(outputDir: outputDir);
        break;

      case 'import':
        if (args.length < 2) {
          print('❌ Import command requires input directory');
          printUsage();
          return;
        }
        await dataManager.importAllData(inputDir: args[1]);
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
  print('\n📖 Firebase Data Manager Usage:');
  print('  dart run scripts/firebase_data_manager.dart export [output_dir] - Export all data');
  print('  dart run scripts/firebase_data_manager.dart import <input_dir>   - Import all data');
  print('  dart run scripts/firebase_data_manager.dart help                 - Show this help');
  print('\n🔧 Commands:');
  print('  export - Export all Firebase data to local files');
  print('  import - Import data from local files to Firebase');
  print('  help   - Display usage information');
  print('\n💡 Examples:');
  print('  dart run scripts/firebase_data_manager.dart export');
  print('  dart run scripts/firebase_data_manager.dart export ./my_backup');
  print('  dart run scripts/firebase_data_manager.dart import ./my_backup');
} 