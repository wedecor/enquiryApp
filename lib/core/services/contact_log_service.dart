import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/firestore_schema.dart';
import '../logging/logger.dart';
import 'firestore_service.dart';

/// Kind of customer contact made from the app.
enum ContactType {
  call('call'),
  whatsapp('whatsapp'),
  reminder('reminder'),
  reviewRequest('review_request'),

  /// Yearly re-engagement wish ("same time next year").
  reengagement('reengagement');

  const ContactType(this.value);

  /// Value stored in `enquiries/{id}/contacts/{cid}.type`.
  final String value;
}

/// Provider for [ContactLogService].
final contactLogServiceProvider = Provider<ContactLogService>((ref) {
  final firestore = ref.watch(firestoreServiceProvider).firestore;
  return ContactLogService(firestore, () => FirebaseAuth.instance.currentUser?.uid);
});

/// Latest thank-you / review request send time for an enquiry, or null if never sent.
/// Prefers denorm [EnquiryFields.lastReviewRequestedAt], falls back to contacts scan.
final lastReviewRequestAtProvider = StreamProvider.autoDispose.family<DateTime?, String>((
  ref,
  enquiryId,
) {
  if (enquiryId.trim().isEmpty) return Stream.value(null);
  final firestore = ref.watch(firestoreServiceProvider).firestore;
  return firestore.collection('enquiries').doc(enquiryId).snapshots().map((snap) {
    final raw = snap.data()?[EnquiryFields.lastReviewRequestedAt];
    if (raw is Timestamp) return raw.toDate();
    return null;
  });
});

/// Persists every successful call / WhatsApp launched from the app so analytics
/// can measure speed-to-lead and follow-up discipline.
///
/// Writes in one transaction:
/// * `enquiries/{id}/contacts/{auto}` → `{type, at, by}`
/// * on the enquiry: `lastContactAt`, `contactCount` (+1), `firstContactAt`
///   (first time), and for review asks `reviewAskedAt` / `lastReviewRequestedAt`.
class ContactLogService {
  ContactLogService(this._firestore, this._currentUid);

  final FirebaseFirestore _firestore;
  final String? Function() _currentUid;

  /// Returns false when there is no signed-in uid or the write failed.
  Future<bool> record({required String enquiryId, required ContactType type}) async {
    if (enquiryId.trim().isEmpty) return false;
    final uid = _currentUid();
    if (uid == null || uid.isEmpty) {
      Log.w('ContactLogService: skip record — no signed-in user');
      return false;
    }
    final enquiryRef = _firestore.collection('enquiries').doc(enquiryId);

    try {
      await _firestore.runTransaction<void>((tx) async {
        final snap = await tx.get(enquiryRef);
        if (!snap.exists) return;
        final data = snap.data() ?? const <String, dynamic>{};
        final contactRef = enquiryRef.collection('contacts').doc();
        tx.set(contactRef, {'type': type.value, 'at': FieldValue.serverTimestamp(), 'by': uid});
        tx.update(enquiryRef, contactUpdateFields(data, type: type));
      });
      return true;
    } catch (e, st) {
      Log.e('ContactLogService: failed to record contact', error: e, stackTrace: st);
      return false;
    }
  }

  /// One-shot latest review-request time (denorm first, then contacts).
  Future<DateTime?> latestAt({required String enquiryId, required ContactType type}) async {
    if (enquiryId.trim().isEmpty) return null;
    try {
      final enquiry = await _firestore.collection('enquiries').doc(enquiryId).get();
      if (type == ContactType.reviewRequest) {
        final denorm = enquiry.data()?[EnquiryFields.lastReviewRequestedAt];
        if (denorm is Timestamp) return denorm.toDate();
      }
      final snap = await _firestore
          .collection('enquiries')
          .doc(enquiryId)
          .collection('contacts')
          .where('type', isEqualTo: type.value)
          .get();
      DateTime? latest;
      for (final doc in snap.docs) {
        final raw = doc.data()['at'];
        final at = raw is Timestamp ? raw.toDate() : null;
        if (at == null) continue;
        if (latest == null || at.isAfter(latest)) latest = at;
      }
      return latest;
    } catch (e, st) {
      Log.e('ContactLogService: failed to read latest contact', error: e, stackTrace: st);
      return null;
    }
  }

  /// Fields to write on the enquiry for one new contact.
  static Map<String, Object> contactUpdateFields(
    Map<String, dynamic> enquiryData, {
    ContactType? type,
  }) {
    final alreadyContacted = enquiryData['firstContactAt'] != null;
    final isReview = type == ContactType.reviewRequest;
    final firstAsk = isReview && enquiryData['reviewAskedAt'] == null;
    return {
      'lastContactAt': FieldValue.serverTimestamp(),
      'contactCount': FieldValue.increment(1),
      if (!alreadyContacted) ...{
        'firstContactAt': FieldValue.serverTimestamp(),
        'firstContactEstimated': false,
      },
      if (firstAsk) EnquiryFields.reviewAskedAt: FieldValue.serverTimestamp(),
      if (isReview) EnquiryFields.lastReviewRequestedAt: FieldValue.serverTimestamp(),
    };
  }
}
