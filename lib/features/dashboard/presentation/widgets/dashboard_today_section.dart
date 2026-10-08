import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/status_vocabulary.dart';
import '../../../../core/services/firestore_service.dart';
import '../dashboard_providers.dart';
import 'dashboard_enquiry_utils.dart';
import 'dashboard_metric_tiles.dart';

/// Summary counters (New · Follow-ups · This week) computed from live data.
/// Each counter is tappable and jumps to the matching tab / Calendar.
class DashboardTodaySection extends ConsumerWidget {
  const DashboardTodaySection({
    super.key,
    required this.isAdmin,
    required this.userId,
    this.onBucketTap,
  });

  final bool isAdmin;
  final String? userId;

  /// Optional callback so the parent can navigate to the right tab/filter.
  /// bucket: 'new' | 'reminders' | 'this_week'
  final void Function(String bucket)? onBucketTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Same shared listeners as the dashboard tabs. Lost enquiries never count
    // here, so only the active and completed slices are needed.
    final enquiriesAsync = watchRoleScopedEnquiries(
      ref,
      isAdmin: isAdmin,
      uid: userId,
      scopes: const [EnquiryScope.active, EnquiryScope.completed],
    );
    final docs = enquiriesAsync.valueOrNull;
    if (docs == null) {
      return DashboardMetricCluster(
        hero: const DashboardMetric(bucket: 'this_week', label: 'This week', value: null),
        heroUnit: 'events',
        heroSeries: List.filled(7, 0),
        first: const DashboardMetric(bucket: 'new', label: 'New', value: null),
        second: const DashboardMetric(bucket: 'reminders', label: 'Follow-ups', value: null),
        onTap: onBucketTap,
      );
    }

    final now = DateTime.now();

    int newUncontacted = 0;
    int staleNew = 0;
    int pendingReminders = 0;
    int eventsThisWeek = 0;
    final perDay = List<double>.filled(7, 0);

    DateTime? nearestEventDate;
    int? nearestDayOffset;
    String? nearestEventName;

    for (final doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final status = EnquiryStatus.fromValue(data['statusValue'] as String?);
      final eventDate = (data['eventDate'] as Timestamp?)?.toDate();

      if (status == EnquiryStatus.newEnquiry) {
        newUncontacted++;
        final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
        if (createdAt != null && now.difference(createdAt).inDays > 3) staleNew++;
      }
      if (shouldShowReminder(data, now)) pendingReminders++;
      if (eventDate == null || status?.category == StatusCategory.lost) continue;
      final dayOffset = eventDayOffset(eventDate, now);
      if (dayOffset < 0 || dayOffset >= 7) continue;
      eventsThisWeek++;
      perDay[dayOffset]++;
      if (nearestEventDate == null || eventDate.isBefore(nearestEventDate)) {
        nearestEventDate = eventDate;
        nearestDayOffset = dayOffset;
        nearestEventName = data['customerName'] as String?;
      }
    }

    String? thisWeekSublabel;
    if (nearestDayOffset != null) {
      final name = nearestEventName ?? 'Event';
      if (nearestDayOffset == 0) {
        thisWeekSublabel = '$name today';
      } else if (nearestDayOffset == 1) {
        thisWeekSublabel = '$name tomorrow';
      } else {
        thisWeekSublabel = '$name in ${nearestDayOffset}d';
      }
    }

    return DashboardMetricCluster(
      hero: DashboardMetric(
        bucket: 'this_week',
        label: 'This week',
        value: eventsThisWeek,
        note: thisWeekSublabel,
      ),
      heroUnit: eventsThisWeek == 1 ? 'event' : 'events',
      heroSeries: perDay,
      first: DashboardMetric(
        bucket: 'new',
        label: 'New',
        value: newUncontacted,
        note: staleNew > 0 ? '$staleNew waiting 3d+' : null,
        alert: staleNew > 0,
      ),
      second: DashboardMetric(
        bucket: 'reminders',
        label: 'Follow-ups',
        value: pendingReminders,
        note: pendingReminders > 0 ? 'Event within 21d' : null,
      ),
      onTap: onBucketTap,
    );
  }
}
