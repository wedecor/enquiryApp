import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
  return EnquiryRepository(firestoreService, dropdownLookupFuture);
});

/// Repository for enquiry data operations
class EnquiryRepository {
  final FirestoreService _firestoreService;
  final Future<DropdownLookup> _dropdownLookupFuture;

  EnquiryRepository(this._firestoreService, this._dropdownLookupFuture);

  /// Get all enquiries as a stream
  Stream<List<Enquiry>> getEnquiries() {
    return FirebaseFirestore.instance
        .collection('enquiries')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Enquiry.fromFirestore(doc)).toList());
  }

  /// Get paginated enquiries (cursor-based pagination)
  ///
  /// [isAdmin]: If true, returns all enquiries. If false, filters by assignedTo.
  /// [assignedTo]: User ID to filter by (required if isAdmin is false).
  /// [status]: Optional status filter.
  /// [lastDocument]: Cursor for pagination (null for first page).
  /// [pageSize]: Number of documents per page (default: 20).
  Future<PaginationState> getPaginatedEnquiries({
    required bool isAdmin,
    String? assignedTo,
    String? status,
    QueryDocumentSnapshot<Map<String, dynamic>>? lastDocument,
    int pageSize = 20,
  }) async {
    try {
      Query<Map<String, dynamic>> query = FirebaseFirestore.instance
          .collection('enquiries')
          .orderBy('createdAt', descending: true);

      // Apply filters
      if (!isAdmin && assignedTo != null) {
        query = query.where('assignedTo', isEqualTo: assignedTo);
      }

      if (status != null && status.isNotEmpty && status != 'All' && status != 'reminders') {
        query = query.where('statusValue', isEqualTo: status);
      }

      // Apply cursor for pagination
      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      // Apply limit
      query = query.limit(pageSize + 1); // Fetch one extra to check if more pages exist

      final snapshot = await query.get();
      final docs = snapshot.docs;

      // Check if more pages exist
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
    Query query = FirebaseFirestore.instance.collection('enquiries');

    // Apply filters
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
    // Fetch old enquiry data to get old status value
    final oldEnquiryDoc = await FirebaseFirestore.instance.collection('enquiries').doc(id).get();

    if (!oldEnquiryDoc.exists) {
      throw Exception('Enquiry not found: $id');
    }

    final oldEnquiryData = oldEnquiryDoc.data() as Map<String, dynamic>;
    // Only use statusValue - standard field
    final oldStatusValue = (oldEnquiryData['statusValue'] as String?) ?? 'new';

    // Only update if status actually changed
    if (oldStatusValue == nextStatus) {
      return; // No change needed
    }

    final lookup = await _dropdownLookupFuture;
    final statusLabel = lookup.labelForStatus(nextStatus);
    final oldStatusLabel = lookup.labelForStatus(oldStatusValue);

    // Get enquiry data for notifications
    final customerName = oldEnquiryData['customerName'] as String? ?? 'Unknown Customer';
    final assignedTo = oldEnquiryData['assignedTo'] as String?;

    await FirebaseFirestore.instance.collection('enquiries').doc(id).update({
      'statusValue': nextStatus, // Standardized field - only write to this
      'statusLabel': statusLabel,
      'statusUpdatedAt': FieldValue.serverTimestamp(),
      'statusUpdatedBy': userId,
      'updatedAt': FieldValue.serverTimestamp(),
      // Remove old fields if they exist
      'eventStatus': FieldValue.delete(),
      'status': FieldValue.delete(),
      'status_slug': FieldValue.delete(),
    });

    // Record audit trail for status change (store VALUES, not labels)
    final auditService = AuditService();
    await auditService.recordChange(
      enquiryId: id,
      fieldChanged: 'statusValue', // Use standardized field name
      oldValue: oldStatusValue,
      newValue: nextStatus,
      userId: userId,
    );

    // Send notification to all admins about status change
    try {
      final notificationService = notification_service.NotificationService();
      await notificationService.notifyStatusUpdated(
        enquiryId: id,
        customerName: customerName,
        oldStatus: oldStatusLabel,
        newStatus: statusLabel,
        updatedBy: userId,
        assignedTo: assignedTo,
      );
    } catch (notificationError) {
      // Log notification error but don't fail the status update
      // Status update already succeeded, so we continue
      // Errors are already logged in NotificationService
    }
  }

  /// Create enquiry (admin): normalizes denormalized/search fields
  Future<void> createEnquiry(Map<String, dynamic> data) async {
    final name = (data['customerName'] as String?) ?? '';
    final phone = data['customerPhone'] as String?;
    final email = (data['customerEmail'] as String?)?.toLowerCase();
    final createdBy = data['createdBy'] as String? ?? '';
    final createdByName = data['createdByName'] as String? ?? '';

    String normalizePhone(String? p) => p == null ? '' : p.replaceAll(RegExp(r'[^0-9]'), '');
    String makeTextIndex({required String name, String? phone, String? email, String? notes}) =>
        [name, phone ?? '', email ?? '', (notes ?? '')].join(' ').toLowerCase();

    await FirebaseFirestore.instance.collection('enquiries').add({
      ...data,
      'customerNameLower': name.toLowerCase(),
      'phoneNormalized': normalizePhone(phone),
      'customerEmail': email,
      'textIndex': makeTextIndex(
        name: name,
        phone: phone,
        email: email,
        notes: data['notes'] as String?,
      ),
      'createdBy': createdBy,
      'createdByName': createdByName,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
