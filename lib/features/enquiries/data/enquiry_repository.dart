import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/status_vocabulary.dart';
import '../../../core/providers/audit_provider.dart';
import '../../../core/providers/notification_provider.dart';
import '../../../core/services/audit_service.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/services/notification_service.dart' as notification_service;
import '../../../services/dropdown_lookup.dart';
import '../domain/enquiry.dart';
import '../domain/enquiry_lifecycle.dart';
import 'pagination_state.dart';

/// Provider for enquiry repository
final enquiryRepositoryProvider = Provider<EnquiryRepository>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  final dropdownLookupFuture = ref.watch(dropdownLookupProvider.future);
  return EnquiryRepository(
    firestoreService,
    dropdownLookupFuture,
    ref.watch(auditServiceProvider),
    ref.watch(notificationServiceProvider),
  );
});

/// Repository for enquiry data operations
class EnquiryRepository {
  final FirestoreService _firestoreService;
  final Future<DropdownLookup> _dropdownLookupFuture;
  final AuditService _auditService;
  final notification_service.NotificationService _notificationService;

  EnquiryRepository(
    this._firestoreService,
    this._dropdownLookupFuture,
    this._auditService,
    this._notificationService,
  );

  CollectionReference<Map<String, dynamic>> get _enquiries => _firestoreService.enquiriesCollection;

  /// Get all enquiries as a stream
  Stream<List<Enquiry>> getEnquiries() {
    return _enquiries
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Enquiry.fromFirestore(doc)).toList());
  }

  /// Newest-first list query; staff are scoped to their own enquiries.
  Query<Map<String, dynamic>> _listQuery({
    required bool isAdmin,
    String? assignedTo,
    String? status,
  }) {
    Query<Map<String, dynamic>> query = _enquiries.orderBy('createdAt', descending: true);

    if (!isAdmin && assignedTo != null) {
      query = query.where('assignedTo', isEqualTo: assignedTo);
    }

    if (status != null && status.isNotEmpty && status != 'All' && status != 'reminders') {
      query = query.where('statusValue', whereIn: EnquiryStatus.rawValuesFor(status));
    }
    return query;
  }

  /// Live view of the newest [limit] enquiries, scoped like [getPaginatedEnquiries].
  ///
  /// Includes metadata changes so listeners learn when a cache-only result has been
  /// confirmed by the server.
  Stream<QuerySnapshot<Map<String, dynamic>>> watchEnquiriesPage({
    required bool isAdmin,
    String? assignedTo,
    String? status,
    required int limit,
  }) {
    return _listQuery(
      isAdmin: isAdmin,
      assignedTo: assignedTo,
      status: status,
    ).limit(limit).snapshots(includeMetadataChanges: true);
  }

  /// Get paginated enquiries (cursor-based pagination)
  Future<PaginationState> getPaginatedEnquiries({
    required bool isAdmin,
    String? assignedTo,
    String? status,
    QueryDocumentSnapshot<Map<String, dynamic>>? lastDocument,
    int pageSize = 20,
  }) async {
    try {
      var query = _listQuery(isAdmin: isAdmin, assignedTo: assignedTo, status: status);

      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      query = query.limit(pageSize + 1);

      final snapshot = await query.get();
      final docs = snapshot.docs;

      final hasMore = docs.length > pageSize;
      final documents = hasMore ? docs.sublist(0, pageSize) : docs;
      final newLastDocument = documents.isNotEmpty ? documents.last : null;

      return PaginationState(
        documents: documents,
        lastDocument: newLastDocument,
        hasMore: hasMore,
        isLoading: false,
      );
    } catch (e) {
      return PaginationState(error: e.toString(), isLoading: false);
    }
  }

  /// Update status fields with server timestamps (rules-compliant for staff).
  ///
  /// The read, stage stamping, update and history entries run in one transaction, so
  /// concurrent status changes can't stamp the wrong stage or log a stale "from" status.
  Future<void> updateStatus({
    required String id,
    required String nextStatus,
    required String userId,
    LostReasonChoice? lostReason,
  }) async {
    final lookup = await _dropdownLookupFuture;
    final canonicalNext = EnquiryStatus.canonicalValue(nextStatus) ?? nextStatus;
    final statusLabel = lookup.labelForStatus(canonicalNext);
    final isLost = EnquiryStatus.isLost(canonicalNext);
    final clearLost = EnquiryStageFields.clearsLostFields(canonicalNext);
    final docRef = _enquiries.doc(id);

    final result = await _firestoreService.firestore.runTransaction<_StatusChangeResult?>((
      transaction,
    ) async {
      final oldEnquiryDoc = await transaction.get(docRef);
      if (!oldEnquiryDoc.exists) {
        throw Exception('Enquiry not found: $id');
      }

      final oldEnquiryData = oldEnquiryDoc.data()!;
      final oldStatusValue =
          EnquiryStatus.canonicalValue(oldEnquiryData['statusValue'] as String?) ??
          (oldEnquiryData['statusValue'] as String? ?? 'new');

      if (oldStatusValue == canonicalNext) return null;

      transaction.update(docRef, {
        'statusValue': canonicalNext,
        'statusLabel': statusLabel,
        'statusUpdatedAt': FieldValue.serverTimestamp(),
        'statusUpdatedBy': userId,
        'updatedAt': FieldValue.serverTimestamp(),
        'eventStatus': FieldValue.delete(),
        'status': FieldValue.delete(),
        'status_slug': FieldValue.delete(),
        for (final field in EnquiryStageFields.fieldsToStamp(oldEnquiryData, canonicalNext))
          field: FieldValue.serverTimestamp(),
        if (isLost && lostReason != null) ...lostReason.toFields(),
        if (clearLost)
          for (final field in EnquiryStageFields.lostOnlyFields) field: FieldValue.delete(),
      });

      transaction.set(
        _auditService.newHistoryRef(id),
        _auditService.buildHistoryEntry(
          fieldChanged: 'statusValue',
          oldValue: oldStatusValue,
          newValue: canonicalNext,
        ),
      );

      final oldLostReason = oldEnquiryData['lostReason'];
      if (isLost && lostReason != null) {
        transaction.set(
          _auditService.newHistoryRef(id),
          _auditService.buildHistoryEntry(
            fieldChanged: 'lostReason',
            oldValue: oldLostReason,
            newValue: lostReason.reason.value,
          ),
        );
      } else if (clearLost && oldLostReason != null) {
        transaction.set(
          _auditService.newHistoryRef(id),
          _auditService.buildHistoryEntry(
            fieldChanged: 'lostReason',
            oldValue: oldLostReason,
            newValue: null,
          ),
        );
      }

      return _StatusChangeResult(
        oldStatusValue: oldStatusValue,
        customerName: oldEnquiryData['customerName'] as String? ?? 'Unknown Customer',
        assignedTo: oldEnquiryData['assignedTo'] as String?,
      );
    });

    if (result == null) return;

    try {
      await _notificationService.notifyStatusUpdated(
        enquiryId: id,
        customerName: result.customerName,
        oldStatus: lookup.labelForStatus(result.oldStatusValue),
        newStatus: statusLabel,
        updatedBy: userId,
        assignedTo: result.assignedTo,
      );
    } catch (_) {
      // Status update already succeeded; notification errors are non-fatal.
    }
  }

  /// Create enquiry via [FirestoreService] (single write path + search indexes).
  Future<String> createEnquiry(Map<String, dynamic> data) {
    return _firestoreService.createEnquiryFromData(data);
  }
}

/// What [EnquiryRepository.updateStatus] needs from inside its transaction afterwards.
class _StatusChangeResult {
  const _StatusChangeResult({
    required this.oldStatusValue,
    required this.customerName,
    required this.assignedTo,
  });

  final String oldStatusValue;
  final String customerName;
  final String? assignedTo;
}
