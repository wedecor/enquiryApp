import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/firestore_service.dart';
import '../../../services/dropdown_lookup.dart';
import '../domain/enquiry.dart';
import '../filters/filters_state.dart';

/// Provider for enquiry repository
final enquiryRepositoryProvider = Provider<EnquiryRepository>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  final dropdownLookupFuture = ref.watch(dropdownLookupProvider.future);
  return EnquiryRepository(
    firestoreService,
    dropdownLookupFuture,
  );
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
    final lookup = await _dropdownLookupFuture;
    final statusLabel = lookup.labelForStatus(nextStatus);

    await FirebaseFirestore.instance.collection('enquiries').doc(id).update({
      'status': nextStatus,
      'eventStatus': nextStatus,
      'statusValue': nextStatus,
      'statusLabel': statusLabel,
      'statusUpdatedAt': FieldValue.serverTimestamp(),
      'statusUpdatedBy': userId,
      'updatedAt': FieldValue.serverTimestamp(),
    });
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
