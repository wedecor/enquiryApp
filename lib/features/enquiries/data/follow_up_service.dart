import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/providers/audit_provider.dart';
import '../../../core/services/audit_service.dart';
import '../../../core/services/firestore_service.dart';

final followUpServiceProvider = Provider<FollowUpService>((ref) {
  return FollowUpService(ref.watch(firestoreServiceProvider), ref.watch(auditServiceProvider));
});

/// Staff/admin actions on an enquiry's automatic follow-up.
///
/// Each action bumps `followUpSeq` and clears `followUpNotifiedStage` in the same
/// write (required by firestore.rules), so a reminder for the old schedule can
/// never fire. After a completion the `onEnquiryWrittenFollowUp` function
/// schedules the next follow-up while the enquiry is still open.
class FollowUpService {
  FollowUpService(this._firestoreService, this._auditService);

  final FirestoreService _firestoreService;
  final AuditService _auditService;

  static const int maxNoteLength = 300;

  /// Callback notes longer than [maxNoteLength] are rejected by the rules.
  static String? cleanNote(String? note) {
    final trimmed = note?.trim() ?? '';
    if (trimmed.isEmpty) return null;
    return trimmed.length <= maxNoteLength ? trimmed : trimmed.substring(0, maxNoteLength);
  }

  /// Fields written when [userId] completes the open follow-up.
  static Map<String, dynamic> completionFields(String userId) => {
    'followUpDueAt': null,
    'followUpSeq': FieldValue.increment(1),
    'followUpNotifiedStage': null,
    'followUpLastCompletedAt': FieldValue.serverTimestamp(),
    'followUpLastCompletedBy': userId,
    'updatedAt': FieldValue.serverTimestamp(),
    'updatedBy': userId,
  };

  /// Fields written when [userId] moves the follow-up to [dueAt].
  static Map<String, dynamic> rescheduleFields({
    required String userId,
    required DateTime dueAt,
    String? note,
    String reason = 'callback',
  }) => {
    'followUpDueAt': Timestamp.fromDate(dueAt),
    'followUpSeq': FieldValue.increment(1),
    'followUpNotifiedStage': null,
    'followUpReason': reason,
    'followUpScheduledBy': userId,
    'followUpNote': cleanNote(note),
    'updatedAt': FieldValue.serverTimestamp(),
    'updatedBy': userId,
  };

  static String _describe(DateTime? dueAt) =>
      dueAt == null ? 'none' : 'due ${DateFormat('d MMM yyyy, h:mm a').format(dueAt)}';

  /// Marks the open follow-up done (call made / customer reached).
  Future<void> complete({
    required String enquiryId,
    required String userId,
    DateTime? previousDueAt,
  }) async {
    final ref = _firestoreService.enquiriesCollection.doc(enquiryId);
    final batch = _firestoreService.firestore.batch()
      ..update(ref, completionFields(userId))
      ..set(
        _auditService.newHistoryRef(enquiryId),
        _auditService.buildHistoryEntry(
          fieldChanged: 'followUp',
          oldValue: _describe(previousDueAt),
          newValue: 'completed',
        ),
      );
    await batch.commit();
  }

  /// Moves the follow-up to [dueAt] (customer asked for a later callback).
  Future<void> reschedule({
    required String enquiryId,
    required String userId,
    required DateTime dueAt,
    DateTime? previousDueAt,
    String? note,
    String reason = 'callback',
  }) async {
    if (!dueAt.isAfter(DateTime.now())) {
      throw ArgumentError('Pick a time in the future');
    }
    final ref = _firestoreService.enquiriesCollection.doc(enquiryId);
    final cleaned = cleanNote(note);
    final batch = _firestoreService.firestore.batch()
      ..update(ref, rescheduleFields(userId: userId, dueAt: dueAt, note: cleaned, reason: reason))
      ..set(
        _auditService.newHistoryRef(enquiryId),
        _auditService.buildHistoryEntry(
          fieldChanged: 'followUp',
          oldValue: _describe(previousDueAt),
          newValue:
              'rescheduled ($reason): ${_describe(dueAt)}${cleaned == null ? '' : ' — $cleaned'}',
        ),
      );
    await batch.commit();
  }
}
