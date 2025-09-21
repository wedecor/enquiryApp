import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/firestore_service.dart';
import '../domain/enquiry.dart';
import '../filters/filters_state.dart';

/// Provider for enquiry repository
final enquiryRepositoryProvider = Provider<EnquiryRepository>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return EnquiryRepository(firestoreService);
});

/// Repository for enquiry data operations
class EnquiryRepository {
  final FirestoreService _firestoreService;

  EnquiryRepository(this._firestoreService);

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
      query = query.where('eventStatus', whereIn: filters.statuses);
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
}
