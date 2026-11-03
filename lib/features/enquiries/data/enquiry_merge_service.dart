import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/status_vocabulary.dart';
import '../../../core/providers/audit_provider.dart';
import '../../../core/services/audit_service.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/utils/enquiry_fields.dart';
import '../domain/enquiry_lifecycle.dart';
import '../domain/event_functions.dart';

final enquiryMergeServiceProvider = Provider<EnquiryMergeService>((ref) {
  return EnquiryMergeService(ref.watch(firestoreServiceProvider), ref.watch(auditServiceProvider));
});

/// Admin-only "Mark as duplicate of…": closes one enquiry as a duplicate of another.
class EnquiryMergeService {
  EnquiryMergeService(this._firestoreService, this._auditService);

  final FirestoreService _firestoreService;
  final AuditService _auditService;

  /// Note appended to the target when the duplicate had notes.
  static String mergeNote({
    required String customerName,
    required DateTime? sourceCreatedAt,
    required String notes,
  }) {
    final date = sourceCreatedAt == null
        ? ''
        : ' ${DateFormat('d MMM yyyy').format(sourceCreatedAt)}';
    return 'Merged from duplicate enquiry $customerName$date: $notes';
  }

  /// In one transaction: [sourceId] → Closed Lost (reason `duplicate`, `mergedInto`),
  /// [targetId] gets the source's notes appended and its images added, and both get
  /// history entries (attributed to the signed-in admin, as the rules require).
  Future<void> markAsDuplicate({
    required String sourceId,
    required String targetId,
    required String userId,
  }) async {
    if (sourceId == targetId) {
      throw ArgumentError('An enquiry cannot be a duplicate of itself');
    }
    final enquiries = _firestoreService.enquiriesCollection;
    final sourceRef = enquiries.doc(sourceId);
    final targetRef = enquiries.doc(targetId);
    const closedLost = EnquiryStatus.closedLost;

    await _firestoreService.firestore.runTransaction<void>((tx) async {
      final sourceSnap = await tx.get(sourceRef);
      final targetSnap = await tx.get(targetRef);
      if (!sourceSnap.exists) throw StateError('This enquiry no longer exists');
      if (!targetSnap.exists) throw StateError('The selected enquiry no longer exists');
      final source = sourceSnap.data()!;
      final target = targetSnap.data()!;
      if (target['mergedInto'] != null) {
        throw StateError('The selected enquiry was itself merged into another one');
      }

      final oldStatus =
          EnquiryStatus.canonicalValue(source['statusValue'] as String?) ??
          (source['statusValue'] as String? ?? 'new');

      tx.update(sourceRef, {
        'statusValue': closedLost.value,
        'statusLabel': closedLost.label,
        'statusUpdatedAt': FieldValue.serverTimestamp(),
        'statusUpdatedBy': userId,
        'eventStatus': FieldValue.delete(),
        'status': FieldValue.delete(),
        'status_slug': FieldValue.delete(),
        for (final field in EnquiryStageFields.fieldsToStamp(source, closedLost.value))
          field: FieldValue.serverTimestamp(),
        ...const LostReasonChoice(LostReason.duplicate).toFields(),
        'mergedInto': targetId,
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': userId,
      });

      // Target: append the duplicate's notes (if any) and add its images.
      final sourceNotes = enquiryNotesFrom(source);
      final targetNotes = enquiryNotesFrom(target);
      final sourceImages = ((source['images'] as List?) ?? const [])
          .map((e) => e.toString())
          .where((url) => url.isNotEmpty)
          .toList();
      final targetUpdate = <String, Object?>{};
      String? newTargetNotes;
      if (sourceNotes != null) {
        final createdAt = source['createdAt'];
        final note = mergeNote(
          customerName: (source['customerName'] as String?)?.trim() ?? 'Customer',
          sourceCreatedAt: createdAt is Timestamp ? createdAt.toDate() : null,
          notes: sourceNotes,
        );
        newTargetNotes = targetNotes == null ? note : '$targetNotes\n\n$note';
        final targetName = (target['customerName'] as String?) ?? '';
        targetUpdate.addAll({
          ...enquiryNotesFields(newTargetNotes),
          ...FirestoreService.searchIndexFieldsFor(
            customerName: targetName,
            customerPhone: target['customerPhone'] as String?,
            customerEmail: target['customerEmail'] as String?,
            notes: newTargetNotes,
            eventTypes: functionTypeLabels(functionsOf(target)),
          ),
        });
      }
      if (sourceImages.isNotEmpty) {
        targetUpdate['images'] = FieldValue.arrayUnion(sourceImages);
      }
      targetUpdate['updatedAt'] = FieldValue.serverTimestamp();
      targetUpdate['updatedBy'] = userId;
      tx.update(targetRef, targetUpdate);

      void history(String enquiryId, String field, Object? oldValue, Object? newValue) {
        tx.set(
          _auditService.newHistoryRef(enquiryId),
          _auditService.buildHistoryEntry(
            fieldChanged: field,
            oldValue: oldValue,
            newValue: newValue,
          ),
        );
      }

      if (oldStatus != closedLost.value) {
        history(sourceId, 'statusValue', oldStatus, closedLost.value);
      }
      history(sourceId, 'lostReason', source['lostReason'], LostReason.duplicate.value);
      history(sourceId, 'mergedInto', null, targetId);
      history(targetId, 'mergedFrom', null, sourceId);
      if (newTargetNotes != null) {
        history(targetId, 'notes', targetNotes, newTargetNotes);
      }
      if (sourceImages.isNotEmpty) {
        final before = (target['images'] as List?)?.length ?? 0;
        final after = {
          ...((target['images'] as List?) ?? const []).map((e) => e.toString()),
          ...sourceImages,
        }.length;
        if (after != before) history(targetId, 'images', before, after);
      }
    });
  }
}
