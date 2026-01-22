import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/enquiries/data/enquiry_repository.dart';
import '../../services/dropdown_lookup.dart';
import '../../utils/logger.dart';
import '../providers/role_provider.dart';

/// Provider for PastEnquiryCleanupService
final pastEnquiryCleanupServiceProvider = Provider<PastEnquiryCleanupService>((ref) {
  final enquiryRepository = ref.watch(enquiryRepositoryProvider);
  final dropdownLookupFuture = ref.watch(dropdownLookupProvider.future);
  return PastEnquiryCleanupService(enquiryRepository, dropdownLookupFuture);
});

/// Service to automatically mark enquiries with passed event dates
///
/// This service checks for enquiries with passed event dates and updates them:
/// - Status "new", "in_talks", or "quote_sent" → "not_interested"
/// - Status "confirmed" → "completed"
class PastEnquiryCleanupService {
  final EnquiryRepository _enquiryRepository;
  final Future<DropdownLookup> _dropdownLookupFuture;

  PastEnquiryCleanupService(this._enquiryRepository, this._dropdownLookupFuture);

  /// Updates enquiries with passed event dates based on their current status
  ///
  /// - Enquiries with status "new", "in_talks", or "quote_sent" → "not_interested"
  /// - Enquiries with status "confirmed" → "completed"
  ///
  /// Only updates enquiries that have event dates before today.
  ///
  /// Returns the number of enquiries updated.
  Future<int> markPastEnquiriesAsNotInterested({String? userId}) async {
    try {
      final now = DateTime.now();
      // Use start of today for date comparison (so events on today are not marked until tomorrow)
      // This ensures events on the 23rd are marked completed/not_interested on the 24th
      final todayStart = DateTime(now.year, now.month, now.day);

      // Statuses that should be marked as "not_interested"
      final statusesToMarkNotInterested = ['new', 'in_talks', 'quote_sent'];
      // Statuses that should be marked as "completed"
      final statusesToMarkCompleted = ['confirmed'];

      int updatedCount = 0;

      // Query all enquiries once and process both status types
      final allEnquiriesQuery = FirebaseFirestore.instance.collection('enquiries');
      final allSnapshot = await allEnquiriesQuery.get();

      // Process enquiries to mark as "not_interested"
      for (final doc in allSnapshot.docs) {
        final data = doc.data();

        // Only use statusValue - standard field
        final statusValue = data['statusValue'] as String?;
        final status = (statusValue ?? '').toLowerCase().trim();

        // Skip if not in the list of statuses to mark as not_interested
        if (!statusesToMarkNotInterested.contains(status)) {
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

        // Mark as not_interested if event date day has passed (event date < today)
        // This ensures events on the 23rd are marked not_interested on the 24th
        if (eventDay.isBefore(todayStart)) {
          await _enquiryRepository.updateStatus(
            id: doc.id,
            nextStatus: 'not_interested',
            userId: userId ?? 'system',
          );
          updatedCount++;
        }
      }

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

        // Normalize event date to start of day (ignore time)
        final eventDay = DateTime(eventDateTime.year, eventDateTime.month, eventDateTime.day);

        // Mark as completed if event date day has passed (event date < today)
        // This ensures events on the 23rd are marked completed on the 24th
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
  /// - "new", "in_talks", "quote_sent" → "not_interested"
  /// - "confirmed" → "completed"
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

      final statusesToCheck = ['new', 'in_talks', 'quote_sent', 'confirmed'];
      int count = 0;

      // Query all enquiries and filter client-side using statusValue only
      final allSnapshot = await FirebaseFirestore.instance.collection('enquiries').get();

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
