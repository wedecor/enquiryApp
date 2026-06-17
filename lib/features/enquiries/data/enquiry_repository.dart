import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/audit_provider.dart';
import '../../../core/providers/notification_provider.dart';
import '../../../core/services/audit_service.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/services/notification_service.dart' as notification_service;
import '../../../services/dropdown_lookup.dart';
import '../domain/enquiry.dart';
import '../filters/filters_state.dart';
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

  /// Get paginated enquiries (cursor-based pagination)
  Future<PaginationState> getPaginatedEnquiries({
    required bool isAdmin,
    String? assignedTo,
    String? status,
    QueryDocumentSnapshot<Map<String, dynamic>>? lastDocument,
    int pageSize = 20,
  }) async {
    try {
      Query<Map<String, dynamic>> query = _enquiries.orderBy('createdAt', descending: true);

      if (!isAdmin && assignedTo != null) {
        query = query.where('assignedTo', isEqualTo: assignedTo);
      }

      if (status != null && status.isNotEmpty && status != 'All' && status != 'reminders') {
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

  /// Get filtered enquiries
  Future<List<Enquiry>> getFilteredEnquiries(EnquiryFilters filters) async {
    Query<Map<String, dynamic>> query = _enquiries;

    if (filters.statuses.isNotEmpty) {
      query = query.where('status', whereIn: filters.statuses);
    }

    if (filters.eventTypes.isNotEmpty) {
      query = query.where('eventType', whereIn: filters.eventTypes);
    }

    if (filters.assigneeId != null) {
      query = query.where('assignedTo', isEqualTo: filters.assigneeId);
    }

    if (filters.dateRange != null) {
      final startDate = Timestamp.fromDate(filters.dateRange!.start);
      final endDate = Timestamp.fromDate(filters.dateRange!.end);
      query = query
          .where('eventDate', isGreaterThanOrEqualTo: startDate)
          .where('eventDate', isLessThanOrEqualTo: endDate);
    }

    query = query.orderBy('createdAt', descending: true);

    final snapshot = await query.get();
    return snapshot.docs.map((doc) => Enquiry.fromFirestore(doc)).toList();
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
    final oldStatusValue = oldEnquiryData['statusValue'] as String? ?? 'new';

    if (oldStatusValue == nextStatus) {
      return;
    }

    final lookup = await _dropdownLookupFuture;
    final statusLabel = lookup.labelForStatus(nextStatus);
    final oldStatusLabel = lookup.labelForStatus(oldStatusValue);

    final customerName = oldEnquiryData['customerName'] as String? ?? 'Unknown Customer';
    final assignedTo = oldEnquiryData['assignedTo'] as String?;

    await _enquiries.doc(id).update({
      'statusValue': nextStatus,
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
      newValue: nextStatus,
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
