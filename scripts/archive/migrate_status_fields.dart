import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:we_decor_enquiries/firebase_options.dart';

/// Migration script to consolidate all status fields to statusValue
///
/// This script:
/// 1. Finds all enquiries with eventStatus or status fields
/// 2. Copies their values to statusValue if statusValue is missing
/// 3. Removes eventStatus and status fields (keeps statusValue only)
///
/// Run with: flutter run scripts/migrate_status_fields.dart
Future<void> main() async {
  print('🚀 Starting status field migration...');

  try {
    // Initialize Firebase
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

    // Note: You may need to authenticate or use service account
    // For now, this assumes you're authenticated via Firebase CLI

    final firestore = FirebaseFirestore.instance;
    final enquiriesRef = firestore.collection('enquiries');

    print('📊 Fetching all enquiries...');
    final snapshot = await enquiriesRef.get();

    print('Found ${snapshot.docs.length} enquiries to process');

    int migrated = 0;
    int alreadyMigrated = 0;
    int errors = 0;

    final batch = firestore.batch();
    int batchCount = 0;
    const batchSize = 500; // Firestore batch limit

    for (final doc in snapshot.docs) {
      try {
        final data = doc.data();
        final docId = doc.id;

        // Get status from various fields
        final statusValue = data['statusValue'] as String?;
        final eventStatus = data['eventStatus'] as String?;
        final status = data['status'] as String?;
        final statusSlug = data['status_slug'] as String?;

        // Determine the actual status value
        final actualStatus = statusValue ?? eventStatus ?? status ?? statusSlug ?? 'new';

        // Check if migration is needed
        final needsMigration = eventStatus != null || status != null || statusSlug != null;
        final hasStatusValue = statusValue != null;

        if (!needsMigration && hasStatusValue) {
          alreadyMigrated++;
          continue;
        }

        // Prepare update
        final updateData = <String, dynamic>{};

        // Set statusValue if missing
        if (!hasStatusValue) {
          updateData['statusValue'] = actualStatus;
        }

        // Remove ALL old fields (regardless of their values)
        if (eventStatus != null) {
          updateData['eventStatus'] = FieldValue.delete();
        }
        if (status != null) {
          updateData['status'] = FieldValue.delete();
        }
        if (statusSlug != null) {
          updateData['status_slug'] = FieldValue.delete();
        }

        // Only update if there are changes
        if (updateData.isNotEmpty) {
          batch.update(enquiriesRef.doc(docId), updateData);
          batchCount++;
          migrated++;

          // Commit batch if it reaches the limit
          if (batchCount >= batchSize) {
            await batch.commit();
            print('✅ Committed batch of $batchCount enquiries');
            batchCount = 0;
          }
        } else {
          alreadyMigrated++;
        }
      } catch (e) {
        errors++;
        print('❌ Error processing ${doc.id}: $e');
      }
    }

    // Commit remaining batch
    if (batchCount > 0) {
      await batch.commit();
      print('✅ Committed final batch of $batchCount enquiries');
    }

    print('\n📊 Migration Summary:');
    print('   ✅ Migrated: $migrated enquiries');
    print('   ✓ Already migrated: $alreadyMigrated enquiries');
    print('   ❌ Errors: $errors enquiries');
    print('\n✨ Migration completed!');
  } catch (e) {
    print('❌ Migration failed: $e');
    exit(1);
  }
}
