import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/status_vocabulary.dart';
import '../../../core/providers/audit_provider.dart';
import '../../../core/providers/notification_provider.dart';
import '../../../core/services/audit_service.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/services/notification_service.dart'
    as notification_service;
import '../../../services/dropdown_lookup.dart';
import '../domain/enquiry.dart';
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

  CollectionReference<Map<String, dynamic>> get _enquiries =>
      _firestoreService.enquiriesCollection;

  /// Get all enquiries as a stream
  Stream<List<Enquiry>> getEnquiries() {
    return _enquiries
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Enquiry.fromFirestore(doc)).toList(),
        );
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
      Query<Map<String, dynamic>> query = _enquiries.orderBy(
        'createdAt',
        descending: true,
      );

      if (!isAdmin && assignedTo != null) {
        query = query.where('assignedTo', isEqualTo: assignedTo);
      }

      if (status != null &&
          status.isNotEmpty &&
          status != 'All' &&
          status != 'reminders') {
        query = query.where('statusValue', isEqualTo: status);
      }

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

  /// Update status fields with server timestamps (rules-compliant for staff)
  Future<void> updateStatus({
    required String id,
    required String nextStatus,
    required String userId,
  }) async {
    final oldEnquiryDoc = await _enquiries.doc(id).get();

    if (!oldEnquiryDoc.exists) {
      throw Exception('Enquiry not found: $id');
    }

    final oldEnquiryData = oldEnquiryDoc.data()!;
    final oldStatusValue =
        EnquiryStatus.canonicalValue(
          oldEnquiryData['statusValue'] as String?,
        ) ??
        (oldEnquiryData['statusValue'] as String? ?? 'new');
    final canonicalNext =
        EnquiryStatus.canonicalValue(nextStatus) ?? nextStatus;

    if (oldStatusValue == canonicalNext) {
      return;
    }

    final lookup = await _dropdownLookupFuture;
    final statusLabel = lookup.labelForStatus(canonicalNext);
    final oldStatusLabel = lookup.labelForStatus(oldStatusValue);

    final customerName =
        oldEnquiryData['customerName'] as String? ?? 'Unknown Customer';
    final assignedTo = oldEnquiryData['assignedTo'] as String?;

    await _enquiries.doc(id).update({
      'statusValue': canonicalNext,
      'statusLabel': statusLabel,
      'statusUpdatedAt': FieldValue.serverTimestamp(),
      'statusUpdatedBy': userId,
      'updatedAt': FieldValue.serverTimestamp(),
      'eventStatus': FieldValue.delete(),
      'status': FieldValue.delete(),
      'status_slug': FieldValue.delete(),
    });

    await _auditService.recordChange(
      enquiryId: id,
      fieldChanged: 'statusValue',
      oldValue: oldStatusValue,
      newValue: canonicalNext,
      userId: userId,
    );

    try {
      await _notificationService.notifyStatusUpdated(
        enquiryId: id,
        customerName: customerName,
        oldStatus: oldStatusLabel,
        newStatus: statusLabel,
        updatedBy: userId,
        assignedTo: assignedTo,
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
