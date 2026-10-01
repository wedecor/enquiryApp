import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/tokens.dart';
import '../../../../ui/primitives/primitives.dart';
import 'calendar_event.dart';
import 'dashboard_empty_enquiries.dart';

/// Agenda for the selected calendar day: split-weight date heading, status
/// proportion strip, conflict notice and staggered enquiry rows.
class CalendarDayAgenda extends StatelessWidget {
  const CalendarDayAgenda({
    super.key,
    required this.day,
    required this.events,
    required this.statusCounts,
    required this.hasConflict,
    required this.statuses,
    required this.itemBuilder,
  });

  final DateTime day;
  final List<CalendarEvent> events;
  final Map<String, int> statusCounts;
  final bool hasConflict;

  /// (status value, label, colour) in display order for the breakdown.
  final List<(String, String, Color)> statuses;
  final Widget Function(CalendarEvent event) itemBuilder;

  /// Space kept free under the last row for the floating nav pill.
  static const double _bottomClearance = 96;

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return SliverMainAxisGroup(
        slivers: [
          SliverToBoxAdapter(child: _AgendaHeading(day: day, count: 0)),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: AppTokens.space6, bottom: _bottomClearance),
              child: DashboardEmptyMessage(
                eyebrow: 'Free day',
                title: 'No events on ${DateFormat('MMM dd, yyyy').format(day)}',
              ),
            ),
          ),
        ],
      );
    }

    final present = [
      for (final status in statuses)
        if ((statusCounts[status.$1] ?? 0) > 0) (status.$2, status.$3, statusCounts[status.$1]!),
    ];

    return SliverMainAxisGroup(
      slivers: [
        SliverToBoxAdapter(
          child: _AgendaHeading(day: day, count: events.length),
        ),
        if (present.isNotEmpty)
          SliverToBoxAdapter(
            child: StaggerIn(
              key: ValueKey('breakdown-$day'),
              index: 0,
              child: _StatusBreakdown(entries: present),
            ),
          ),
        if (hasConflict) const SliverToBoxAdapter(child: _ConflictNotice()),
        SliverList(
          delegate: SliverChildBuilderDelegate((context, index) {
            final event = events[index];
            return StaggerIn(
              key: ValueKey('$day-${event.enquiryId}'),
              index: index + 1,
              child: itemBuilder(event),
            );
          }, childCount: events.length),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: _bottomClearance)),
      ],
    );
  }
}

class _AgendaHeading extends StatelessWidget {
  const _AgendaHeading({required this.day, required this.count});

  final DateTime day;
  final int count;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final base = (t.headlineSmall ?? const TextStyle()).copyWith(letterSpacing: -0.4);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTokens.space5,
        AppTokens.space6,
        AppTokens.space5,
        AppTokens.space3,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Eyebrow(DateFormat('EEEE').format(day), accent: true),
                const SizedBox(height: AppTokens.space1),
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: DateFormat('d MMMM').format(day),
                        style: base.copyWith(fontWeight: FontWeight.w800),
                      ),
                      TextSpan(
                        text: ' ${day.year}',
                        style: base.copyWith(
                          fontWeight: FontWeight.w300,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (count > 0)
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '$count',
                    style: t.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  TextSpan(
                    text: count == 1 ? ' event' : ' events',
                    style: t.titleSmall?.copyWith(
                      fontWeight: FontWeight.w300,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _StatusBreakdown extends StatelessWidget {
  const _StatusBreakdown({required this.entries});

  /// (label, colour, count)
  final List<(String, Color, int)> entries;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(AppTokens.space4, 0, AppTokens.space4, AppTokens.space2),
      child: GlassPanel(
        padding: const EdgeInsets.all(AppTokens.space4 - 2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Eyebrow('Status breakdown'),
            const SizedBox(height: AppTokens.space3),
            ProportionStrip(
              height: 6,
              segments: [for (final (_, color, count) in entries) (count.toDouble(), color)],
            ),
            const SizedBox(height: AppTokens.space3),
            Wrap(
              spacing: AppTokens.space4,
              runSpacing: AppTokens.space2,
              children: [
                for (final (label, color, count) in entries)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      StatusDot(color: color, size: 7),
                      const SizedBox(width: AppTokens.space1 + 2),
                      Text(label, style: t.labelMedium?.copyWith(color: cs.onSurfaceVariant)),
                      const SizedBox(width: AppTokens.space1),
                      Text('$count', style: t.labelLarge?.copyWith(fontWeight: FontWeight.w800)),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ConflictNotice extends StatelessWidget {
  const _ConflictNotice();

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final error = Theme.of(context).colorScheme.error;

    return Padding(
      padding: const EdgeInsets.fromLTRB(AppTokens.space4, 0, AppTokens.space4, AppTokens.space2),
      child: GlassPanel(
        tint: error.withValues(alpha: 0.08),
        borderColor: error.withValues(alpha: 0.35),
        padding: const EdgeInsets.symmetric(
          horizontal: AppTokens.space4 - 2,
          vertical: AppTokens.space3,
        ),
        child: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: error, size: AppTokens.iconMedium),
            const SizedBox(width: AppTokens.space3 - 2),
            Expanded(
              child: Text(
                'Conflict: Multiple approved bookings on this date',
                style: t.labelLarge?.copyWith(color: error, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
