import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/firestore_service.dart';
import '../../../../core/theme/tokens.dart';
import 'dashboard_enquiry_utils.dart';

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

        String? thisWeekSublabel;
        if (nearestEventDate != null) {
          final diff = nearestEventDate.difference(now);
          final name = nearestEventName ?? 'Event';
          if (diff.inDays == 0) {
            thisWeekSublabel = '$name today';
          } else if (diff.inDays == 1) {
            thisWeekSublabel = '$name tomorrow';
          } else {
            thisWeekSublabel = '$name in ${diff.inDays}d';
          }
        }

        final cs = Theme.of(context).colorScheme;
        return _StatStrip(
          cells: [
            _StatCell(
              bucket: 'new',
              value: newUncontacted,
              label: 'New',
              note: staleNew > 0 ? '$staleNew waiting 3d+' : null,
              valueColor: staleNew > 0 ? cs.error : null,
              onTap: onBucketTap,
            ),
            _StatCell(
              bucket: 'reminders',
              value: pendingReminders,
              label: 'Follow-ups',
              note: pendingReminders > 0 ? 'Event within 21d' : null,
              onTap: onBucketTap,
            ),
            _StatCell(
              bucket: 'this_week',
              value: eventsThisWeek,
              label: 'This week',
              note: thisWeekSublabel,
              onTap: onBucketTap,
            ),
          ],
        );
      },
    );
  }
}

/// Three counters in one hairline-divided row — the dashboard's summary line.
class _StatStrip extends StatelessWidget {
  const _StatStrip({required this.cells});

  final List<_StatCell> cells;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final divider = VerticalDivider(width: 1, thickness: 1, color: cs.outlineVariant);
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: cs.outlineVariant),
          bottom: BorderSide(color: cs.outlineVariant),
        ),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (int i = 0; i < cells.length; i++) ...[
              if (i > 0) divider,
              Expanded(child: cells[i]),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  const _StatCell({
    required this.bucket,
    required this.value,
    required this.label,
    this.note,
    this.valueColor,
    this.onTap,
  });

  final String bucket;
  final int value;
  final String label;
  final String? note;
  final Color? valueColor;
  final void Function(String)? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Semantics(
      button: onTap != null,
      label: '$value $label${note != null ? '. $note' : ''}',
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap != null ? () => onTap!(bucket) : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTokens.space4,
            vertical: AppTokens.space3,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(color: cs.onSurfaceVariant),
              ),
              const SizedBox(height: AppTokens.space1 / 2),
              Text(
                '$value',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: valueColor ?? cs.onSurface,
                  fontFeatures: const [FontFeature.tabularFigures()],
                  height: 1.1,
                ),
              ),
              if (note != null) ...[
                const SizedBox(height: AppTokens.space1 / 2),
                Text(
                  note!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
