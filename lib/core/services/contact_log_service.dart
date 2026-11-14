import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
final lastReviewRequestAtProvider = StreamProvider.autoDispose.family<DateTime?, String>((
  ref,
  enquiryId,
) {
  return ref
      .watch(contactLogServiceProvider)
      .watchLatestAt(enquiryId: enquiryId, type: ContactType.reviewRequest);
});

/// Persists every successful call / WhatsApp launched from the app so analytics
/// can measure speed-to-lead and follow-up discipline.
///
/// Writes:
/// * `enquiries/{id}/contacts/{auto}` → `{type, at, by}`
/// * on the enquiry: `lastContactAt`, `contactCount` (+1) and `firstContactAt`
///   (only the first time).
///
/// Never throws: a failed write must not block opening the dialer / WhatsApp.
class ContactLogService {
  ContactLogService(this._firestore, this._currentUid);

  final FirebaseFirestore _firestore;
  final String? Function() _currentUid;

  Future<void> record({required String enquiryId, required ContactType type}) async {
    if (enquiryId.trim().isEmpty) return;
    final uid = _currentUid() ?? 'unknown';
    final enquiryRef = _firestore.collection('enquiries').doc(enquiryId);

    try {
      await enquiryRef.collection('contacts').add({
        'type': type.value,
        'at': FieldValue.serverTimestamp(),
        'by': uid,
      });

      await _firestore.runTransaction<void>((tx) async {
        final snap = await tx.get(enquiryRef);
        if (!snap.exists) return;
        final data = snap.data() ?? const <String, dynamic>{};
        tx.update(enquiryRef, contactUpdateFields(data));
      });
    } catch (e, st) {
      Log.e('ContactLogService: failed to record contact', error: e, stackTrace: st);
    }
  }

  /// Latest `at` for contacts of [type] on this enquiry (client-side max; no composite index).
  Stream<DateTime?> watchLatestAt({required String enquiryId, required ContactType type}) {
    if (enquiryId.trim().isEmpty) return Stream.value(null);
    return _firestore
        .collection('enquiries')
        .doc(enquiryId)
        .collection('contacts')
        .where('type', isEqualTo: type.value)
        .snapshots()
        .map((snap) {
          DateTime? latest;
          for (final doc in snap.docs) {
            final raw = doc.data()['at'];
            final at = raw is Timestamp ? raw.toDate() : null;
            if (at == null) continue;
            if (latest == null || at.isAfter(latest)) latest = at;
          }
          return latest;
        });
  }

  /// One-shot latest `at` for [type] (e.g. before a re-send confirm).
  Future<DateTime?> latestAt({required String enquiryId, required ContactType type}) async {
    if (enquiryId.trim().isEmpty) return null;
    try {
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

  /// Fields to write on the enquiry for one new contact. `firstContactAt` is set
  /// only when the enquiry has never been contacted, so it always holds the
  /// earliest contact (a backfilled estimate is kept, being earlier).
  static Map<String, Object> contactUpdateFields(Map<String, dynamic> enquiryData) {
    final alreadyContacted = enquiryData['firstContactAt'] != null;
    return {
      'lastContactAt': FieldValue.serverTimestamp(),
      'contactCount': FieldValue.increment(1),
      if (!alreadyContacted) ...{
        'firstContactAt': FieldValue.serverTimestamp(),
        'firstContactEstimated': false,
      },
    };
  }
}
