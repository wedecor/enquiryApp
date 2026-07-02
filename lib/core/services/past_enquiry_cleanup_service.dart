import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/status_vocabulary.dart';
import '../../core/logging/logger.dart';
import '../../features/enquiries/data/enquiry_repository.dart';
import '../services/firestore_service.dart';

/// Provider for PastEnquiryCleanupService
final pastEnquiryCleanupServiceProvider = Provider<PastEnquiryCleanupService>((
  ref,
) {
  final enquiryRepository = ref.watch(enquiryRepositoryProvider);
  final firestoreService = ref.watch(firestoreServiceProvider);
  return PastEnquiryCleanupService(enquiryRepository, firestoreService);
});

/// Service to automatically mark enquiries with passed event dates
///
/// Approved bookings (event date before today) → **completed**.
///
/// New / In Talks are intentionally NOT auto-closed — staff close manually.
class PastEnquiryCleanupService {
  PastEnquiryCleanupService(this._enquiryRepository, this._firestoreService);

  final EnquiryRepository _enquiryRepository;
  final FirestoreService _firestoreService;

  /// Approved enquiries whose event day is strictly before today → completed.
  Future<int> markPastEnquiriesAsNotInterested({String? userId}) async {
    try {
      final now = DateTime.now().toLocal();
      final todayStart = DateTime(now.year, now.month, now.day);
      var updatedCount = 0;

      final allSnapshot = await _firestoreService.fetchAllEnquiries();

      for (final doc in allSnapshot.docs) {
        final data = doc.data();
        final statusValue = data['statusValue'] as String?;

        if (!EnquiryStatus.isApproved(statusValue)) {
          continue;
        }

        final eventDateTime = _parseEventDate(data['eventDate']);
        if (eventDateTime == null) continue;

        final localEvent = eventDateTime.toLocal();
        final eventDay = DateTime(
          localEvent.year,
          localEvent.month,
          localEvent.day,
        );

        if (eventDay.isBefore(todayStart)) {
          await _enquiryRepository.updateStatus(
            id: doc.id,
            nextStatus: 'completed',
            userId: userId ?? 'system',
          );
          updatedCount++;
        }
      }

      return updatedCount;
    } catch (e) {
      throw Exception('Error marking past enquiries: $e');
    }
  }

  Future<int?> runAutomaticCleanup({bool force = false, String? userId}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      const lastRunKey = 'past_enquiry_cleanup_last_run';

      if (!force) {
        final lastRunTimestamp = prefs.getInt(lastRunKey);
        if (lastRunTimestamp != null) {
          final lastRun = DateTime.fromMillisecondsSinceEpoch(lastRunTimestamp);
          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);
          final lastRunDay = DateTime(lastRun.year, lastRun.month, lastRun.day);

          if (lastRunDay.isAtSameMomentAs(today)) {
            Log.d('Past enquiry cleanup skipped - already ran today');
            return null;
          }
        }
      }

      final updatedCount = await markPastEnquiriesAsNotInterested(
        userId: userId,
      );
      await prefs.setInt(lastRunKey, DateTime.now().millisecondsSinceEpoch);
      Log.i(
        'Past enquiry cleanup completed',
        data: {'updatedCount': updatedCount},
      );
      return updatedCount;
    } catch (e) {
      Log.e('Error in automatic cleanup', error: e);
      return null;
    }
  }

  Future<int> countPastEnquiriesToUpdate() async {
    try {
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);
      var count = 0;

      final allSnapshot = await _firestoreService.fetchAllEnquiries();

      for (final doc in allSnapshot.docs) {
        final data = doc.data();
        if (!EnquiryStatus.isApproved(data['statusValue'] as String?)) {
          continue;
        }

        final eventDateTime = _parseEventDate(data['eventDate']);
        if (eventDateTime == null) continue;

        final eventDay = DateTime(
          eventDateTime.year,
          eventDateTime.month,
          eventDateTime.day,
        );

        if (eventDay.isBefore(todayStart)) {
          count++;
        }
      }

      return count;
    } catch (e) {
      throw Exception('Error counting past enquiries: $e');
    }
  }

  DateTime? _parseEventDate(dynamic eventDate) {
    if (eventDate == null) return null;
    if (eventDate is Timestamp) return eventDate.toDate();
    if (eventDate is DateTime) return eventDate;
    return null;
  }
}
