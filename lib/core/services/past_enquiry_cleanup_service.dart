import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/logging/logger.dart';
import '../../features/enquiries/data/enquiry_repository.dart';
import '../services/firestore_service.dart';

/// Provider for PastEnquiryCleanupService
final pastEnquiryCleanupServiceProvider = Provider<PastEnquiryCleanupService>((ref) {
  final enquiryRepository = ref.watch(enquiryRepositoryProvider);
  final firestoreService = ref.watch(firestoreServiceProvider);
  return PastEnquiryCleanupService(enquiryRepository, firestoreService);
});

/// Service to automatically mark enquiries with passed event dates
///
/// This service checks for enquiries with passed event dates and updates them:
/// - Status "confirmed" → "completed"
///
/// NOTE: "new", "in_talks", and "quote_sent" are intentionally NOT auto-closed.
/// Clients may reschedule or postpone; auto-closing loses legitimate leads.
/// Staff should manually close enquiries they know are no longer active.
class PastEnquiryCleanupService {
  final EnquiryRepository _enquiryRepository;
  final FirestoreService _firestoreService;

  PastEnquiryCleanupService(this._enquiryRepository, this._firestoreService);

  /// Updates enquiries with passed event dates based on their current status
  ///
  /// - Enquiries with status "confirmed" → "completed"
  ///
  /// Enquiries in "new", "in_talks", or "quote_sent" are NOT auto-closed — clients
  /// may reschedule. Staff should manually close these when appropriate.
  ///
  /// Only updates enquiries that have event dates before today.
  ///
  /// Returns the number of enquiries updated.
  Future<int> markPastEnquiriesAsNotInterested({String? userId}) async {
    try {
      // Always use local time — guards against platform-specific UTC/local DateTime differences
      final now = DateTime.now().toLocal();
      // Start of today in local time. Events on today are NOT marked until tomorrow 00:00.
      final todayStart = DateTime(now.year, now.month, now.day);

      // Statuses that should be marked as "completed"
      final statusesToMarkCompleted = ['confirmed'];

      int updatedCount = 0;

      // Query all enquiries once and process
      final allSnapshot = await _firestoreService.fetchAllEnquiries();

      // Process enquiries to mark as "completed"
      for (final doc in allSnapshot.docs) {
        final data = doc.data();

        // Only use statusValue - standard field
        final statusValue = data['statusValue'] as String?;
        final status = (statusValue ?? '').toLowerCase().trim();

        // Skip if not confirmed status
        if (!statusesToMarkCompleted.contains(status)) {
          continue;
        }

        final eventDate = data['eventDate'];
        if (eventDate == null) continue;

        DateTime? eventDateTime;
        if (eventDate is Timestamp) {
          eventDateTime = eventDate.toDate();
        } else if (eventDate is DateTime) {
          eventDateTime = eventDate;
        } else {
          continue;
        }

        // Always work in local timezone — Timestamp.toDate() may return a UTC-aware
        // DateTime on Flutter Web, causing off-by-one date errors for IST users
        // (July 1 00:00 IST = June 30 18:30 UTC → would wrongly appear as June 30).
        final localEvent = eventDateTime.toLocal();
        final eventDay = DateTime(localEvent.year, localEvent.month, localEvent.day);

        // Mark as completed only if the event day is STRICTLY before today.
        // July 1st event: NOT marked on July 1st. Marked on July 2nd 00:00 onwards.
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

  /// Runs automatic cleanup if needed (checks last run time to avoid running too frequently)
  ///
  /// This method checks when the cleanup was last run and only runs if:
  /// - It hasn't been run today, OR
  /// - Force is set to true
  ///
  /// Updates:
  /// - "confirmed" → "completed" (when event date has fully passed, i.e. next day 00:00)
  ///
  /// Returns the number of enquiries updated, or null if cleanup was skipped.
  Future<int?> runAutomaticCleanup({bool force = false, String? userId}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      const lastRunKey = 'past_enquiry_cleanup_last_run';

      if (!force) {
        // Check if we've run today
        final lastRunTimestamp = prefs.getInt(lastRunKey);
        if (lastRunTimestamp != null) {
          final lastRun = DateTime.fromMillisecondsSinceEpoch(lastRunTimestamp);
          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);
          final lastRunDay = DateTime(lastRun.year, lastRun.month, lastRun.day);

          // If we ran today, skip
          if (lastRunDay.isAtSameMomentAs(today)) {
            Log.d('Past enquiry cleanup skipped - already ran today');
            return null;
          }
        }
      }

      // Run cleanup
      final updatedCount = await markPastEnquiriesAsNotInterested(userId: userId);

      // Save last run time
      await prefs.setInt(lastRunKey, DateTime.now().millisecondsSinceEpoch);

      Log.i('Past enquiry cleanup completed', data: {'updatedCount': updatedCount});
      return updatedCount;
    } catch (e) {
      Log.e('Error in automatic cleanup', error: e);
      return null;
    }
  }

  /// Checks if there are any past enquiries that need to be updated
  ///
  /// Returns the count of enquiries that would be updated.
  Future<int> countPastEnquiriesToUpdate() async {
    try {
      final now = DateTime.now();
      // Use start of today for date comparison
      final todayStart = DateTime(now.year, now.month, now.day);

      // Only count confirmed enquiries — others are not auto-closed (see B-06)
      final statusesToCheck = ['confirmed'];
      int count = 0;

      // Query all enquiries and filter client-side using statusValue only
      final allSnapshot = await _firestoreService.fetchAllEnquiries();

      for (final doc in allSnapshot.docs) {
        final data = doc.data();

        // Only use statusValue - standard field
        final statusValue = data['statusValue'] as String?;
        final status = (statusValue ?? '').toLowerCase().trim();

        // Skip if not in the list of statuses to check
        if (!statusesToCheck.contains(status)) {
          continue;
        }

        final eventDate = data['eventDate'];
        if (eventDate == null) continue;

        DateTime? eventDateTime;
        if (eventDate is Timestamp) {
          eventDateTime = eventDate.toDate();
        } else if (eventDate is DateTime) {
          eventDateTime = eventDate;
        } else {
          continue;
        }

        // Normalize event date to start of day (ignore time)
        final eventDay = DateTime(eventDateTime.year, eventDateTime.month, eventDateTime.day);

        if (eventDay.isBefore(todayStart)) {
          count++;
        }
      }

      return count;
    } catch (e) {
      throw Exception('Error counting past enquiries: $e');
    }
  }
}
