import '../../../core/constants/status_vocabulary.dart';

/// Why an enquiry was lost. The `value` is stored in `lostReason`.
enum LostReason {
  priceTooHigh('price_too_high', 'Price too high'),
  bookedOtherVendor('booked_other_vendor', 'Booked another vendor'),
  dateUnavailable('date_unavailable', 'Date not available'),
  noResponse('no_response', 'No response'),
  eventCancelled('event_cancelled', 'Event cancelled / postponed'),
  outOfScope('out_of_scope', 'Not something we do'),
  other('other', 'Other');

  const LostReason(this.value, this.label);

  final String value;
  final String label;

  static LostReason? fromValue(String? raw) {
    if (raw == null) return null;
    for (final r in LostReason.values) {
      if (r.value == raw.trim()) return r;
    }
    return null;
  }

  /// Display label for a stored value; unknown values are title-cased.
  static String labelOf(String? raw) {
    final reason = fromValue(raw);
    if (reason != null) return reason.label;
    if (raw == null || raw.trim().isEmpty) return 'Not recorded';
    return raw.replaceAll('_', ' ');
  }
}

/// A lost reason chosen by the user (optionally with a free-text note).
class LostReasonChoice {
  const LostReasonChoice(this.reason, {this.note});

  final LostReason reason;
  final String? note;

  /// Firestore fields to write alongside the lost status.
  Map<String, Object?> toFields() => {
    'lostReason': reason.value,
    'lostReasonNote': (note == null || note!.trim().isEmpty) ? null : note!.trim(),
  };
}

/// Firestore field that records when an enquiry first reached each stage.
/// `new` is covered by `createdAt`.
class EnquiryStageFields {
  EnquiryStageFields._();

  static const String inTalksAt = 'inTalksAt';
  static const String approvedAt = 'approvedAt';
  static const String completedAt = 'completedAt';
  static const String lostAt = 'lostAt';

  /// The stage-timestamp field for a canonical status, or null for `new`/unknown.
  static String? fieldFor(String? status) {
    final s = EnquiryStatus.fromValue(status);
    if (s == null) return null;
    switch (s) {
      case EnquiryStatus.newEnquiry:
        return null;
      case EnquiryStatus.inTalks:
        return inTalksAt;
      case EnquiryStatus.approved:
        return approvedAt;
      case EnquiryStatus.completed:
        return completedAt;
      case EnquiryStatus.notInterested:
      case EnquiryStatus.closedLost:
      case EnquiryStatus.cancelled:
        return lostAt;
    }
  }

  /// Lost-only fields. They are deleted when an enquiry moves to a non-lost status
  /// (reopen), so a reopened enquiry doesn't keep a stale reason / lost timestamp.
  static const List<String> lostOnlyFields = ['lostReason', 'lostReasonNote', lostAt];

  /// True when moving to [nextStatus] should delete [lostOnlyFields].
  static bool clearsLostFields(String nextStatus) {
    final canonical = EnquiryStatus.canonicalValue(nextStatus) ?? nextStatus;
    return !EnquiryStatus.isLost(canonical);
  }

  /// Stage fields that should be stamped when moving to [nextStatus], given the
  /// enquiry's current data. Only fields not already set are returned, so the
  /// first time a stage is reached is preserved. Intermediate stages that were
  /// skipped are NOT invented.
  static List<String> fieldsToStamp(Map<String, dynamic> currentData, String nextStatus) {
    final field = fieldFor(nextStatus);
    if (field == null) return const [];
    if (currentData[field] != null) return const [];
    return [field];
  }
}
