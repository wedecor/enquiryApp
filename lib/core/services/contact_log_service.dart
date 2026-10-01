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
  reviewRequest('review_request');

  const ContactType(this.value);

  /// Value stored in `enquiries/{id}/contacts/{cid}.type`.
  final String value;
}

/// Provider for [ContactLogService].
final contactLogServiceProvider = Provider<ContactLogService>((ref) {
  final firestore = ref.watch(firestoreServiceProvider).firestore;
  return ContactLogService(firestore, () => FirebaseAuth.instance.currentUser?.uid);
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
