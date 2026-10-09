import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/status_vocabulary.dart';
import '../../../core/services/firestore_service.dart';
import '../domain/enquiry_occasion.dart';
import '../domain/occasion_kind.dart';
import '../domain/occasion_reminder.dart';
import '../domain/past_customer_occasion.dart';
import '../domain/reengagement_config.dart';
import '../domain/reengagement_stats.dart';

final reengagementRepositoryProvider = Provider<ReengagementRepository>((ref) {
  return ReengagementRepository(ref.watch(firestoreServiceProvider).firestore);
});

/// Reads/writes `reminders`, `customer_prefs`, `app_config/reengagement` and the
/// yearly-reminder fields of enquiries.
class ReengagementRepository {
  ReengagementRepository(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _reminders => _firestore.collection('reminders');

  CollectionReference<Map<String, dynamic>> get _prefs => _firestore.collection('customer_prefs');

  DocumentReference<Map<String, dynamic>> get _configDoc =>
      _firestore.collection('app_config').doc(ReengagementConfig.docId);

  /// Pending reminders with an occasion in `[from, to)`, soonest first.
  /// Admins: all (index status + occasionDate). Staff: their own — the rules only
  /// allow a query constrained to `assignedTo == uid` (index assignedTo + status +
  /// occasionDate).
  Stream<List<OccasionReminder>> watchPending({
    required bool isAdmin,
    required String uid,
    required DateTime from,
    required DateTime to,
  }) {
    Query<Map<String, dynamic>> query = _reminders;
    if (!isAdmin) query = query.where('assignedTo', isEqualTo: uid);
    return query
        .where('status', isEqualTo: OccasionReminder.statusPending)
        .where('occasionDate', isGreaterThanOrEqualTo: Timestamp.fromDate(from))
        .where('occasionDate', isLessThan: Timestamp.fromDate(to))
        .orderBy('occasionDate')
        .limit(200)
        .snapshots()
        .map((snap) => snap.docs.map((d) => OccasionReminder.fromMap(d.id, d.data())).toList());
  }

  /// Marks a reminder as sent by [uid].
  Future<void> markSent(String id, String uid) {
    return _reminders.doc(id).update({
      'status': OccasionReminder.statusSent,
      'sentAt': FieldValue.serverTimestamp(),
      'sentBy': uid,
    });
  }

  /// Skips a reminder (this year only unless the customer is also opted out).
  Future<void> skip(String id, {String reason = OccasionReminder.skipReasonManual}) {
    return _reminders.doc(id).update({
      'status': OccasionReminder.statusSkipped,
      'skippedReason': reason,
    });
  }

  /// "Don't remind again" for a customer (normalized phone).
  Future<void> setNoReminders(String phoneNormalized, {required bool value, required String uid}) {
    return _prefs.doc(phoneNormalized).set({
      'noReminders': value,
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': uid,
    }, SetOptions(merge: true));
  }

  Stream<bool> watchNoReminders(String phoneNormalized) {
    return _prefs.doc(phoneNormalized).snapshots().map((s) => s.data()?['noReminders'] == true);
  }

  Stream<ReengagementConfig> watchConfig() {
    return _configDoc.snapshots().map((snap) => ReengagementConfig.fromMap(snap.data()));
  }

  /// Admin only (app_config rules). Full overwrite so templates reset to default
  /// are really removed.
  Future<void> saveConfig(ReengagementConfig config) {
    return _configDoc.set({...config.toMap(), 'updatedAt': FieldValue.serverTimestamp()});
  }

  DocumentReference<Map<String, dynamic>> _enquiry(String id) =>
      _firestore.collection('enquiries').doc(id);

  /// Admin edit of kind / date / person (kind + date become manual).
  Future<void> adminEditOccasion(
    String enquiryId, {
    required OccasionKind kind,
    required DateTime day,
    required String? person,
  }) {
    final fields = EnquiryOccasion.adminEditFields(kind: kind, day: day, person: person);
    return _enquiry(
      enquiryId,
    ).update({for (final e in fields.entries) e.key: e.value ?? FieldValue.delete()});
  }

  /// Staff (and admin) edit of whose occasion it is. Empty clears it.
  Future<void> setOccasionPerson(String enquiryId, String? person) {
    final value = person?.trim() ?? '';
    return _enquiry(
      enquiryId,
    ).update({EnquiryOccasion.personField: value.isEmpty ? FieldValue.delete() : value});
  }

  /// Yearly reminders on/off for one enquiry.
  Future<void> setOccasionReminders(String enquiryId, {required bool on}) {
    return _enquiry(enquiryId).update({EnquiryOccasion.remindersField: on});
  }

  /// Completed enquiries with an occasion stamp (unsorted; sorted client-side).
  /// Admins: all. Staff: only those assigned to them — the enquiries rules only
  /// allow a query constrained to `assignedTo == uid`. Equality / `in` filters
  /// only (no orderBy), so no composite index is needed.
  Future<List<PastCustomerOccasion>> fetchCompletedOccasions({
    required bool isAdmin,
    required String uid,
  }) async {
    Query<Map<String, dynamic>> query = _firestore.collection('enquiries');
    if (!isAdmin) query = query.where('assignedTo', isEqualTo: uid);
    final snap = await query
        .where('statusValue', whereIn: EnquiryStatus.rawValuesFor(EnquiryStatus.completed.value))
        .get();
    return snap.docs
        .map((d) => PastCustomerOccasion.fromEnquiry(d.id, d.data()))
        .whereType<PastCustomerOccasion>()
        .toList(growable: false);
  }

  /// Normalized phones of customers who chose "Don't remind again".
  Future<Set<String>> fetchOptedOutPhones() async {
    final snap = await _prefs.where('noReminders', isEqualTo: true).get();
    return {for (final d in snap.docs) d.id};
  }

  /// Marks `reminders/{id}` sent if it exists and is not sent yet. Returns true
  /// when it was updated. A missing doc (or one the caller may not read — staff
  /// reading an unassigned/missing reminder are denied by the rules) returns false.
  Future<bool> markSentIfExists(String id, String uid) async {
    try {
      final snap = await _reminders.doc(id).get();
      if (!snap.exists || snap.data()?['status'] == OccasionReminder.statusSent) return false;
      await markSent(id, uid);
      return true;
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied' || e.code == 'not-found') return false;
      rethrow;
    }
  }

  /// Reminders sent in `[start, end]` (admin; single-field range → automatic index).
  Future<List<SentReminder>> fetchSent(DateTime start, DateTime end) async {
    final snap = await _reminders
        .where('sentAt', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('sentAt', isLessThanOrEqualTo: Timestamp.fromDate(end))
        .get();
    final result = <SentReminder>[];
    for (final doc in snap.docs) {
      final data = doc.data();
      final sentAt = data['sentAt'];
      if (data['status'] != OccasionReminder.statusSent || sentAt is! Timestamp) continue;
      result.add(
        SentReminder(
          phoneNormalized: (data['phoneNormalized'] as String?) ?? '',
          sentAt: sentAt.toDate(),
        ),
      );
    }
    return result;
  }
}
