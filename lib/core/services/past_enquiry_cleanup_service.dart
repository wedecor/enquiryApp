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
      final today = DateTime(now.year, now.month, now.day);
      
      // Statuses that should be marked as "not_interested"
      final statusesToMarkNotInterested = ['new', 'in_talks', 'quote_sent'];
      // Statuses that should be marked as "completed"
      final statusesToMarkCompleted = ['confirmed'];
      
      int updatedCount = 0;
      
      // Process enquiries to mark as "not_interested"
      for (final status in statusesToMarkNotInterested) {
        final query = FirebaseFirestore.instance
            .collection('enquiries')
            .where('statusValue', isEqualTo: status);
        
        final snapshot = await query.get();
        
        for (final doc in snapshot.docs) {
          final data = doc.data();
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
          
          final eventDay = DateTime(
            eventDateTime.year,
            eventDateTime.month,
            eventDateTime.day,
          );
          
          if (eventDay.isBefore(today)) {
            await _enquiryRepository.updateStatus(
              id: doc.id,
              nextStatus: 'not_interested',
              userId: userId ?? 'system',
            );
            updatedCount++;
          }
        }
      }
      
      // Process enquiries to mark as "completed"
      for (final status in statusesToMarkCompleted) {
        final query = FirebaseFirestore.instance
            .collection('enquiries')
            .where('statusValue', isEqualTo: status);
        
        final snapshot = await query.get();
        
        for (final doc in snapshot.docs) {
          final data = doc.data();
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
          
          final eventDay = DateTime(
            eventDateTime.year,
            eventDateTime.month,
            eventDateTime.day,
          );
          
          if (eventDay.isBefore(today)) {
            await _enquiryRepository.updateStatus(
              id: doc.id,
              nextStatus: 'completed',
              userId: userId ?? 'system',
            );
            updatedCount++;
          }
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
      final today = DateTime(now.year, now.month, now.day);
      
      final statusesToCheck = ['new', 'in_talks', 'quote_sent', 'confirmed'];
      int count = 0;
      
      for (final status in statusesToCheck) {
        final query = FirebaseFirestore.instance
            .collection('enquiries')
            .where('statusValue', isEqualTo: status);
        
        final snapshot = await query.get();
        
        for (final doc in snapshot.docs) {
          final data = doc.data();
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
          
          final eventDay = DateTime(
            eventDateTime.year,
            eventDateTime.month,
            eventDateTime.day,
          );
          
          if (eventDay.isBefore(today)) {
            count++;
          }
        }
      }
      
      return count;
    } catch (e) {
      throw Exception('Error counting past enquiries: $e');
    }
  }
}

