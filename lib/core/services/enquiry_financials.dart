import 'package:cloud_firestore/cloud_firestore.dart';

/// Booking money lives in `enquiries/{id}/financial/summary`, not on the enquiry.
///
/// Firestore cannot hide fields of a document a user may read, and staff may read
/// the enquiries assigned to them. The summary doc is admin-only in
/// firestore.rules, so staff can no longer read totals, advances, payment status
/// or quotes. Older enquiries may still carry these fields on the parent until
/// `scripts/migrations/2026_11_move_financials.ts` is applied, so admin reads fall
/// back to the parent when no summary exists.
class EnquiryFinancials {
  const EnquiryFinancials._();

  static const String collection = 'financial';
  static const String docId = 'summary';

  /// Fields that belong to the summary doc (never written to the parent any more).
  static const List<String> fields = [
    'totalCost',
    'advancePaid',
    'paymentStatus',
    'paymentStatusValue',
    'paymentStatusLabel',
    'quotedAmount',
    'quotedAt',
  ];

  static DocumentReference<Map<String, dynamic>> ref(FirebaseFirestore db, String enquiryId) =>
      db.collection('enquiries').doc(enquiryId).collection(collection).doc(docId);

  /// Splits an enquiry write into parent fields and money fields.
  static ({Map<String, dynamic> parent, Map<String, dynamic> money}) split(
    Map<String, dynamic> data,
  ) {
    final parent = <String, dynamic>{};
    final money = <String, dynamic>{};
    data.forEach((key, value) {
      (fields.contains(key) ? money : parent)[key] = value;
    });
    return (parent: parent, money: money);
  }

  /// Money write for the summary doc: deletes become nulls (the doc may not exist
  /// yet, and `set(merge)` cannot delete a field of a missing doc), plus `updatedAt`
  /// so the analytics cache picks the change up.
  static Map<String, dynamic> summaryWrite(Map<String, dynamic> money) => {
    for (final entry in money.entries) entry.key: entry.value is FieldValue ? null : entry.value,
    'updatedAt': FieldValue.serverTimestamp(),
  };

  /// [parent] with the money fields taken from [summary] when it exists (admin
  /// views). Without a summary the parent's legacy money fields are kept, so
  /// bookings created before the move still show their amounts.
  static Map<String, dynamic> merge(Map<String, dynamic> parent, Map<String, dynamic>? summary) {
    if (summary == null) return parent;
    return {
      for (final entry in parent.entries)
        if (!fields.contains(entry.key)) entry.key: entry.value,
      for (final key in fields)
        if (summary.containsKey(key)) key: summary[key],
    };
  }

  /// Parent data with every money field removed (what non-admins may be shown).
  static Map<String, dynamic> strip(Map<String, dynamic> parent) => {
    for (final entry in parent.entries)
      if (!fields.contains(entry.key)) entry.key: entry.value,
  };

  static Future<Map<String, dynamic>?> read(FirebaseFirestore db, String enquiryId) async {
    final snap = await ref(db, enquiryId).get();
    return snap.exists ? snap.data() : null;
  }

  static Stream<Map<String, dynamic>?> watch(FirebaseFirestore db, String enquiryId) =>
      ref(db, enquiryId).snapshots().map((snap) => snap.exists ? snap.data() : null);

  /// Every summary doc keyed by enquiry id (admin export / analytics; one read each).
  static Future<Map<String, Map<String, dynamic>>> readAll(
    FirebaseFirestore db, {
    DateTime? since,
  }) async {
    Query<Map<String, dynamic>> query = db.collectionGroup(collection);
    if (since != null) query = query.where('updatedAt', isGreaterThan: Timestamp.fromDate(since));
    final snap = await query.get();
    return {
      for (final doc in snap.docs)
        if (doc.id == docId && doc.reference.parent.parent != null)
          doc.reference.parent.parent!.id: doc.data(),
    };
  }
}
