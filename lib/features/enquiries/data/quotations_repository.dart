import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/firestore_schema.dart';
import '../../../core/providers/audit_provider.dart';
import '../../../core/services/audit_service.dart';
import '../../../core/services/enquiry_financials.dart';
import '../../../core/services/firestore_service.dart';
import '../domain/quotation.dart';

final quotationsRepositoryProvider = Provider<QuotationsRepository>((ref) {
  return QuotationsRepository(
    ref.watch(firestoreServiceProvider).firestore,
    ref.watch(auditServiceProvider),
  );
});

/// Admin CRUD for `enquiries/{id}/quotations` and the shared `catalog` collection.
class QuotationsRepository {
  QuotationsRepository(this._db, this._audit);

  final FirebaseFirestore _db;
  final AuditService _audit;

  CollectionReference<Map<String, dynamic>> _quotes(String enquiryId) => _db
      .collection(FirestoreCollections.enquiries)
      .doc(enquiryId)
      .collection(FirestoreCollections.quotations);

  CollectionReference<Map<String, dynamic>> get _catalog =>
      _db.collection(FirestoreCollections.catalog);

  Stream<List<Quotation>> watchQuotations(String enquiryId) {
    return _quotes(enquiryId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => Quotation.fromMap(d.id, d.data())).toList());
  }

  Future<Quotation?> getQuotation(String enquiryId, String quoteId) async {
    final snap = await _quotes(enquiryId).doc(quoteId).get();
    if (!snap.exists || snap.data() == null) return null;
    return Quotation.fromMap(snap.id, snap.data()!);
  }

  /// Creates a draft quote and returns its id. [reference] defaults to Q-yyyyMMdd-HHmm.
  Future<String> createDraft({
    required String enquiryId,
    required String actorUid,
    required List<QuotationLineItem> items,
    String? reference,
    String? notes,
    DateTime? validUntil,
  }) async {
    final ref = _quotes(enquiryId).doc();
    final quote = Quotation(
      id: ref.id,
      status: Quotation.statusDraft,
      items: items,
      subtotal: 0,
      gstTotal: 0,
      discountTotal: 0,
      total: 0,
      reference: reference?.trim().isNotEmpty == true ? reference!.trim() : _defaultReference(),
      notes: notes,
      validUntil: validUntil,
    );
    final batch = _db.batch()
      ..set(ref, quote.toMap(actorUid: actorUid, creating: true))
      ..set(
        _audit.newHistoryRef(enquiryId),
        _audit.buildHistoryEntry(
          fieldChanged: 'quotation',
          oldValue: null,
          newValue: 'draft ${quote.reference ?? ref.id}',
        ),
      );
    await batch.commit();
    return ref.id;
  }

  Future<void> updateDraft({
    required String enquiryId,
    required String quoteId,
    required String actorUid,
    required List<QuotationLineItem> items,
    String? reference,
    String? notes,
    DateTime? validUntil,
    required String status,
  }) async {
    if (status != Quotation.statusDraft) {
      throw StateError('Only draft quotations can be edited');
    }
    final quote = Quotation(
      id: quoteId,
      status: Quotation.statusDraft,
      items: items,
      subtotal: 0,
      gstTotal: 0,
      discountTotal: 0,
      total: 0,
      reference: reference,
      notes: notes,
      validUntil: validUntil,
    );
    await _quotes(
      enquiryId,
    ).doc(quoteId).set(quote.toMap(actorUid: actorUid), SetOptions(merge: true));
  }

  /// Marks the quote sent and writes `quotedAmount` / `quotedAt` on the financial summary.
  Future<void> markSent({
    required String enquiryId,
    required String quoteId,
    required String actorUid,
  }) async {
    final quoteRef = _quotes(enquiryId).doc(quoteId);
    final snap = await quoteRef.get();
    if (!snap.exists || snap.data() == null) {
      throw StateError('Quotation not found');
    }
    final quote = Quotation.fromMap(snap.id, snap.data()!);
    final totals = QuotationTotals.of(quote.items);

    final batch = _db.batch()
      ..update(quoteRef, {
        'status': Quotation.statusSent,
        'sentAt': FieldValue.serverTimestamp(),
        'sentBy': actorUid,
        'subtotal': totals.subtotal,
        'gstTotal': totals.gstTotal,
        'discountTotal': totals.discountTotal,
        'total': totals.total,
        'updatedAt': FieldValue.serverTimestamp(),
      })
      ..set(
        EnquiryFinancials.ref(_db, enquiryId),
        EnquiryFinancials.summaryWrite({
          'quotedAmount': totals.total,
          'quotedAt': FieldValue.serverTimestamp(),
        }),
        SetOptions(merge: true),
      )
      ..set(
        _audit.newHistoryRef(enquiryId),
        _audit.buildHistoryEntry(
          fieldChanged: 'quotation',
          oldValue: quote.status,
          // No amount here: assigned staff can read history, money is admin-only.
          newValue: 'sent ${quote.reference ?? quoteId}',
        ),
      );
    await batch.commit();
  }

  Future<void> deleteDraft({required String enquiryId, required String quoteId}) async {
    final snap = await _quotes(enquiryId).doc(quoteId).get();
    if (!snap.exists) return;
    final status = snap.data()?['status'] as String? ?? Quotation.statusDraft;
    if (status != Quotation.statusDraft) {
      throw StateError('Sent quotations cannot be deleted');
    }
    await _quotes(enquiryId).doc(quoteId).delete();
  }

  Stream<List<CatalogItem>> watchCatalog() {
    return _catalog
        .orderBy('name')
        .snapshots()
        .map((snap) => snap.docs.map((d) => CatalogItem.fromMap(d.id, d.data())).toList());
  }

  Future<String> upsertCatalogItem(CatalogItem item) async {
    final ref = item.id.isEmpty ? _catalog.doc() : _catalog.doc(item.id);
    await ref.set({...item.toMap(), 'name': item.name}, SetOptions(merge: true));
    return ref.id;
  }

  Future<void> deleteCatalogItem(String id) => _catalog.doc(id).delete();

  static String _defaultReference() {
    final now = DateTime.now();
    return 'Q-${DateFormat('yyyyMMdd-HHmm').format(now)}';
  }
}
