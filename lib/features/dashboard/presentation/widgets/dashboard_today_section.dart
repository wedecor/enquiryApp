import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/firestore_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/tokens.dart';
import 'dashboard_enquiry_utils.dart';

/// "Needs Attention" — surfaces the most actionable buckets from live data.
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
        int staleNew = 0;
        int pendingReminders = 0;
        int eventsThisWeek = 0;

        DateTime? nearestEventDate;
        String? nearestEventName;

        for (final doc in docs) {
          final data = doc.data() as Map<String, dynamic>;
          final status = (data['statusValue'] as String?)?.toLowerCase() ?? '';
          final eventDate = (data['eventDate'] as Timestamp?)?.toDate();

          if (status == 'new') {
            newUncontacted++;
            final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
            if (createdAt != null && now.difference(createdAt).inDays > 3)
              staleNew++;
          }
          if (shouldShowReminder(data, now)) pendingReminders++;
          if (eventDate != null &&
              eventDate.isAfter(now) &&
              eventDate.isBefore(weekFromNow)) {
            eventsThisWeek++;
            if (nearestEventDate == null ||
                eventDate.isBefore(nearestEventDate)) {
              nearestEventDate = eventDate;
              nearestEventName = data['customerName'] as String?;
            }
          }
        }

        String thisWeekSublabel = 'Happening this week';
        if (nearestEventDate != null) {
          final diff = nearestEventDate.difference(now);
          if (diff.inDays == 0) {
            thisWeekSublabel = '${nearestEventName ?? 'Event'} — today!';
          } else if (diff.inDays == 1) {
            thisWeekSublabel = '${nearestEventName ?? 'Event'} — tomorrow';
          } else {
            thisWeekSublabel =
                '${nearestEventName ?? 'Event'} in ${diff.inDays}d';
          }
        }

        final buckets = <_PriorityBucket>[
          if (newUncontacted > 0)
            _PriorityBucket(
              bucket: 'new',
              icon: Icons.person_add_outlined,
              label: '$newUncontacted new',
              sublabel: staleNew > 0
                  ? '$staleNew waiting 3+ days'
                  : 'Need first contact',
              urgency: staleNew > 0 ? _Urgency.critical : _Urgency.high,
              onTap: onBucketTap,
            ),
          if (pendingReminders > 0)
            _PriorityBucket(
              bucket: 'reminders',
              icon: Icons.notifications_active_outlined,
              label:
                  '$pendingReminders follow-up${pendingReminders == 1 ? '' : 's'}',
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

        if (buckets.isEmpty) return const _AllClearBanner();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppTokens.space4,
                AppTokens.space2,
                AppTokens.space4,
                AppTokens.space3,
              ),
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
                  const SizedBox(width: AppTokens.space2),
                  Text(
                    '· tap to jump',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide =
                    constraints.maxWidth >= AppTokens.breakpointTablet;

                if (isWide) {
                  return Padding(
                    padding: AppSpacing.horizontal4,
                    child: GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: AppTokens.space3,
                      mainAxisSpacing: AppTokens.space3,
                      childAspectRatio: 2.6,
                      children: buckets,
                    ),
                  );
                }

                return SizedBox(
                  height: 108,
                  child: ListView.separated(
                    padding: AppSpacing.horizontal4,
                    scrollDirection: Axis.horizontal,
                    itemCount: buckets.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(width: AppTokens.space3),
                    itemBuilder: (context, i) =>
                        SizedBox(width: 172, child: buckets[i]),
                  ),
                );
              },
            ),
            const SizedBox(height: AppTokens.space2),
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

    final Color accentColor;
    final Color accentSurface;
    switch (urgency) {
      case _Urgency.critical:
        accentColor = cs.error;
        accentSurface = cs.errorContainer.withValues(alpha: 0.35);
      case _Urgency.high:
        accentColor = AppColorScheme.warning;
        accentSurface = cs.secondaryContainer.withValues(alpha: 0.45);
      case _Urgency.medium:
        accentColor = cs.primary;
        accentSurface = cs.primaryContainer.withValues(alpha: 0.5);
      case _Urgency.low:
        accentColor = cs.secondary;
        accentSurface = cs.secondaryContainer.withValues(alpha: 0.4);
    }

    return Semantics(
      button: true,
      label: '$label. $sublabel',
      child: Material(
        color: cs.surface,
        elevation: 0,
        shadowColor: cs.shadow.withValues(alpha: 0.08),
        borderRadius: AppRadius.xLarge,
        child: InkWell(
          onTap: onTap != null ? () => onTap!(bucket) : null,
          borderRadius: AppRadius.xLarge,
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: AppRadius.xLarge,
              border: Border.all(color: cs.outlineVariant),
              boxShadow: AppShadows.elevation1,
            ),
            child: ClipRRect(
              borderRadius: AppRadius.xLarge,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(width: 4, color: accentColor),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(AppTokens.space3),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: accentSurface,
                              borderRadius: AppRadius.medium,
                            ),
                            alignment: Alignment.center,
                            child: Icon(
                              icon,
                              color: accentColor,
                              size: AppTokens.iconMedium,
                            ),
                          ),
                          const SizedBox(width: AppTokens.space3),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  label,
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: cs.onSurface,
                                  ),
                                ),
                                const SizedBox(height: AppTokens.space1),
                                Text(
                                  sublabel,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: cs.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 14,
                            color: cs.onSurfaceVariant,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AllClearBanner extends StatelessWidget {
  const _AllClearBanner();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTokens.space4,
        AppTokens.space3,
        AppTokens.space4,
        AppTokens.space2,
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: AppTokens.space4,
          vertical: AppTokens.space3,
        ),
        decoration: BoxDecoration(
          color: cs.tertiaryContainer.withValues(alpha: 0.45),
          borderRadius: AppRadius.xLarge,
          border: Border.all(color: cs.tertiary.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: cs.tertiary.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.celebration_outlined,
                color: cs.tertiary,
                size: 20,
              ),
            ),
            const SizedBox(width: AppTokens.space3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'All caught up!',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: cs.onTertiaryContainer,
                    ),
                  ),
                  Text(
                    'Nothing needs your attention right now.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: cs.onTertiaryContainer.withValues(alpha: 0.85),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
