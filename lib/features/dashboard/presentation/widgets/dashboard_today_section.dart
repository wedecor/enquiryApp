import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/firestore_service.dart';
import '../../../../core/theme/tokens.dart';
import 'dashboard_enquiry_utils.dart';

/// "Today at a Glance" — surfaces the 3 most actionable buckets from live data.
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
  /// bucket: 'new' | 'reminders' | 'this_week' | 'quote_sent' — maps to dashboard tab values
  final void Function(String bucket)? onBucketTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return StreamBuilder<QuerySnapshot>(
      stream: ref
          .read(firestoreServiceProvider)
          .watchEnquiriesForRole(isAdmin: isAdmin, assignedToUid: userId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();

        final docs = snapshot.data!.docs;
        final now = DateTime.now();
        final weekFromNow = now.add(const Duration(days: 7));

        int newUncontacted = 0;
        int staleNew = 0; // new enquiries sitting uncontacted for >3 days
        int pendingReminders = 0;
        int eventsThisWeek = 0;

        // Track nearest upcoming event for the this_week bucket sublabel
        DateTime? nearestEventDate;
        String? nearestEventName;

        for (final doc in docs) {
          final data = doc.data() as Map<String, dynamic>;
          final status = (data['statusValue'] as String?)?.toLowerCase() ?? '';
          final eventDate = (data['eventDate'] as Timestamp?)?.toDate();

          if (status == 'new') {
            newUncontacted++;
            final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
            if (createdAt != null && now.difference(createdAt).inDays > 3) staleNew++;
          }
          if (shouldShowReminder(data, now)) pendingReminders++;
          if (eventDate != null && eventDate.isAfter(now) && eventDate.isBefore(weekFromNow)) {
            eventsThisWeek++;
            if (nearestEventDate == null || eventDate.isBefore(nearestEventDate)) {
              nearestEventDate = eventDate;
              nearestEventName = data['customerName'] as String?;
            }
          }
        }

        // Build sublabel for this_week bucket
        String thisWeekSublabel = 'Happening this week';
        if (nearestEventDate != null) {
          final diff = nearestEventDate.difference(now);
          if (diff.inDays == 0) {
            thisWeekSublabel = '${nearestEventName ?? 'Event'} — today!';
          } else if (diff.inDays == 1) {
            thisWeekSublabel = '${nearestEventName ?? 'Event'} — tomorrow';
          } else {
            thisWeekSublabel = '${nearestEventName ?? 'Event'} in ${diff.inDays}d';
          }
        }

        final buckets = <_PriorityBucket>[
          if (newUncontacted > 0)
            _PriorityBucket(
              bucket: 'new',
              icon: Icons.person_add_outlined,
              label: '$newUncontacted new',
              sublabel: staleNew > 0 ? '$staleNew waiting 3+ days' : 'Need first contact',
              urgency: staleNew > 0 ? _Urgency.critical : _Urgency.high,
              onTap: onBucketTap,
            ),
          if (pendingReminders > 0)
            _PriorityBucket(
              bucket: 'reminders',
              icon: Icons.notifications_active_outlined,
              label: '$pendingReminders follow-up${pendingReminders == 1 ? '' : 's'}',
              sublabel: 'Event within 21 days',
              urgency: _Urgency.medium,
              onTap: onBucketTap,
            ),
          if (eventsThisWeek > 0)
            _PriorityBucket(
              bucket: 'this_week',
              icon: Icons.event_outlined,
              label: '$eventsThisWeek event${eventsThisWeek == 1 ? '' : 's'}',
              sublabel: thisWeekSublabel,
              urgency: _Urgency.high,
              onTap: onBucketTap,
            ),
        ];

        if (buckets.isEmpty) return _AllClearBanner();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    'Needs Attention',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '· across all enquiries',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 90,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: buckets.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, i) => buckets[i],
              ),
            ),
            const SizedBox(height: 8),
          ],
        );
      },
    );
  }
}

enum _Urgency { critical, high, medium, low }

class _PriorityBucket extends StatelessWidget {
  const _PriorityBucket({
    required this.bucket,
    required this.icon,
    required this.label,
    required this.sublabel,
    required this.urgency,
    this.onTap,
  });

  final String bucket;
  final IconData icon;
  final String label;
  final String sublabel;
  final _Urgency urgency;
  final void Function(String)? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final Color iconColor;
    final Color bgColor;
    switch (urgency) {
      case _Urgency.critical:
        iconColor = cs.error;
        bgColor = cs.errorContainer.withValues(alpha: 0.45);
      case _Urgency.high:
        iconColor = cs.error;
        bgColor = cs.errorContainer.withValues(alpha: 0.25);
      case _Urgency.medium:
        iconColor = cs.primary;
        bgColor = cs.primaryContainer.withValues(alpha: 0.3);
      case _Urgency.low:
        iconColor = cs.secondary;
        bgColor = cs.secondaryContainer.withValues(alpha: 0.3);
    }

    return GestureDetector(
      onTap: onTap != null ? () => onTap!(bucket) : null,
      child: Container(
        width: 150,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(AppTokens.radiusMedium),
          border: Border.all(color: iconColor.withValues(alpha: 0.18)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, color: iconColor, size: 22),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                  ),
                ),
                Text(
                  sublabel,
                  style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AllClearBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Row(
        children: [
          Icon(Icons.check_circle_outline, color: theme.colorScheme.tertiary, size: 18),
          const SizedBox(width: 8),
          Text(
            'All caught up — nothing needs attention right now.',
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
