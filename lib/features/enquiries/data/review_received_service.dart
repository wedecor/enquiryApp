import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/firestore_schema.dart';
import '../../../core/services/firestore_service.dart';

final reviewReceivedServiceProvider = Provider<ReviewReceivedService>((ref) {
  return ReviewReceivedService(ref.watch(firestoreServiceProvider));
});

/// Toggle "Review received" on a completed enquiry (`reviewReceivedAt` / `By`).
class ReviewReceivedService {
  ReviewReceivedService(this._firestoreService);

  final FirestoreService _firestoreService;

  /// Fields written when [userId] marks the Google review as received.
  static Map<String, dynamic> markFields(String userId) => {
    EnquiryFields.reviewReceivedAt: FieldValue.serverTimestamp(),
    EnquiryFields.reviewReceivedBy: userId,
    EnquiryFields.updatedAt: FieldValue.serverTimestamp(),
    'updatedBy': userId,
  };

  /// Fields written when clearing the toggle.
  static Map<String, dynamic> clearFields(String userId) => {
    EnquiryFields.reviewReceivedAt: FieldValue.delete(),
    EnquiryFields.reviewReceivedBy: FieldValue.delete(),
    EnquiryFields.updatedAt: FieldValue.serverTimestamp(),
    'updatedBy': userId,
  };

  Future<void> setReceived({
    required String enquiryId,
    required String userId,
    required bool received,
  }) {
    return _firestoreService.enquiriesCollection
        .doc(enquiryId)
        .update(received ? markFields(userId) : clearFields(userId));
  }
}
