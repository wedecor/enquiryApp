import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

import '../lib/firebase_options.dart';
import '../lib/services/dropdown_lookup.dart';

Future<void> main() async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final db = FirebaseFirestore.instance;
  final lookup = DropdownLookup(db);
  await lookup.ensureLoaded();

  DocumentSnapshot? lastDoc;
  const pageSize = 400;
  var totalUpdated = 0;

  while (true) {
    Query<Map<String, dynamic>> query =
        db.collection('enquiries').orderBy(FieldPath.documentId).limit(pageSize);
    if (lastDoc != null) {
      query = query.startAfterDocument(lastDoc);
    }

    final snapshot = await query.get();
    if (snapshot.docs.isEmpty) {
      break;
    }

    var batch = db.batch();
    var writesInBatch = 0;

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final updates = <String, dynamic>{};

      final statusValue =
          (data['statusValue'] ?? data['eventStatus']) as String?;
      final eventTypeValue =
          (data['eventTypeValue'] ?? data['eventType']) as String?;
      final priorityValue =
          (data['priorityValue'] ?? data['priority']) as String?;
      final paymentStatusValue =
          (data['paymentStatusValue'] ?? data['paymentStatus']) as String?;
      final sourceValue =
          (data['sourceValue'] ?? data['source']) as String?;

      if (statusValue != null) {
        if (data['statusValue'] == null) {
          updates['statusValue'] = statusValue;
        }
        if (data['statusLabel'] == null) {
          updates['statusLabel'] = lookup.labelForStatus(statusValue);
        }
        if (data['status'] == null) {
          updates['status'] = statusValue;
        }
      }

      if (eventTypeValue != null) {
        if (data['eventTypeValue'] == null) {
          updates['eventTypeValue'] = eventTypeValue;
        }
        if (data['eventTypeLabel'] == null) {
          updates['eventTypeLabel'] = lookup.labelForEventType(eventTypeValue);
        }
      }

      if (priorityValue != null) {
        if (data['priorityValue'] == null) {
          updates['priorityValue'] = priorityValue;
        }
        if (data['priorityLabel'] == null) {
          updates['priorityLabel'] = lookup.labelForPriority(priorityValue);
        }
      }

      if (paymentStatusValue != null) {
        if (data['paymentStatusValue'] == null) {
          updates['paymentStatusValue'] = paymentStatusValue;
        }
        if (data['paymentStatusLabel'] == null) {
          updates['paymentStatusLabel'] =
              lookup.labelForPaymentStatus(paymentStatusValue);
        }
        if (data['paymentStatus'] == null) {
          updates['paymentStatus'] = paymentStatusValue;
        }
      }

      if (sourceValue != null) {
        if (data['sourceValue'] == null) {
          updates['sourceValue'] = sourceValue;
        }
        if (data['sourceLabel'] == null) {
          updates['sourceLabel'] = lookup.labelForSource(sourceValue);
        }
      }

      if (updates.isEmpty) {
        continue;
      }

      batch.update(doc.reference, updates);
      writesInBatch += 1;
      totalUpdated += 1;

      if (writesInBatch >= 450) {
        await batch.commit();
        batch = db.batch();
        writesInBatch = 0;
      }
    }

    if (writesInBatch > 0) {
      await batch.commit();
    }

    lastDoc = snapshot.docs.last;
  }

  print('Backfill complete. Updated $totalUpdated enquiry documents.');
}

