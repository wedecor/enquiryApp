import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../../core/theme/tokens.dart';
import '../../../../../services/dropdown_lookup.dart';
import '../../../../../ui/primitives/primitives.dart';
import '../../domain/monthly_summary.dart';
import 'analytics_section_card.dart';
import 'pipeline_sections.dart' show formatDurationShort, formatPercent;

String formatMetricComparison(MetricComparison c, {bool asPercentPoints = false}) {
  if (!c.hasData || c.delta == null) return '';
  final delta = c.delta!;
  final sign = delta > 0 ? '+' : '';
  if (c.pct == null) {
    if (asPercentPoints) {
      final pts = delta * 100;
      return '$sign${pts.toStringAsFixed(0)} pts';
    }
    if (delta is int || delta == delta.roundToDouble()) {
      return '$sign${delta.round()}';
    }
    return '$sign$delta';
  }
  final pct = (c.pct! * 100).round();
  return '$sign$pct%';
}

String formatHeadlineValue(HeadlineMetric m, {required String kind}) {
  if (!m.hasValue) return '—';
  switch (kind) {
    case 'rate':
      return formatPercent(m.value.toDouble());
    case 'duration':
      return formatDurationShort(Duration(minutes: m.value.round()));
    default:
      return '${m.value.round()}';
  }
}

String _sourceLabel(String key) => DropdownLookup.titleCase(key);

/// Full monthly summary layout (shared visual language with analytics sections).
class MonthlySummaryBody extends StatelessWidget {
  const MonthlySummaryBody({super.key, required this.summary});

  final MonthlySummary summary;

  @override
  Widget build(BuildContext context) {
    final s = summary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (s.sentences.isNotEmpty) _SentencesCard(sentences: s.sentences),
        const SizedBox(height: AppTokens.space4),
        _HeadlineSection(summary: s),
        const SizedBox(height: AppTokens.space4),
        _SourcesSection(rows: s.sources),
        const SizedBox(height: AppTokens.space4),
        _BookedSection(summary: s),
        const SizedBox(height: AppTokens.space4),
        _LostSection(lost: s.lost),
        const SizedBox(height: AppTokens.space4),
        _EventsSection(events: s.eventsDelivered),
        const SizedBox(height: AppTokens.space4),
        _TimingSection(timing: s.timing),
        const SizedBox(height: AppTokens.space4),
        _TeamSection(team: s.team),
        const SizedBox(height: AppTokens.space4),
        _WishesSection(wishes: s.wishes),
        if (s.stillOpen != null) ...[
          const SizedBox(height: AppTokens.space4),
          _StillOpenSection(open: s.stillOpen!),
        ],
        if (s.monthAhead != null) ...[
          const SizedBox(height: AppTokens.space4),
          _MonthAheadSection(ahead: s.monthAhead!),
        ],
      ],
    );
  }
}

class _SentencesCard extends StatelessWidget {
  const _SentencesCard({required this.sentences});
  final List<String> sentences;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnalyticsSectionCard(
      eyebrow: 'At a glance',
      title: 'Summary',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < sentences.length; i++) ...[
            if (i > 0) const SizedBox(height: AppTokens.space3),
            Text(sentences[i], style: theme.textTheme.bodyLarge),
          ],
        ],
      ),
    );
  }
}

class _HeadlineSection extends StatelessWidget {
  const _HeadlineSection({required this.summary});
  final MonthlySummary summary;

  @override
  Widget build(BuildContext context) {
    final s = summary;
    return AnalyticsSectionCard(
      eyebrow: 'Headline',
      title: 'Numbers',
      child: Column(
        children: [
          _HeadlineRow(label: 'New enquiries', metric: s.newEnquiries, kind: 'count'),
          _HeadlineRow(label: 'Bookings confirmed', metric: s.bookingsConfirmed, kind: 'count'),
          _HeadlineRow(label: 'Events completed', metric: s.eventsCompleted, kind: 'count'),
          _HeadlineRow(label: 'Win rate', metric: s.winRate, kind: 'rate', asPercentPoints: true),
          _HeadlineRow(
            label: 'Median first response',
            metric: s.medianFirstResponse,
            kind: 'duration',
          ),
        ],
      ),
    );
  }
}

class _HeadlineRow extends StatelessWidget {
  const _HeadlineRow({
    required this.label,
    required this.metric,
    required this.kind,
    this.asPercentPoints = false,
  });

  final String label;
  final HeadlineMetric metric;
  final String kind;
  final bool asPercentPoints;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final vsPrev = formatMetricComparison(metric.vsPreviousMonth, asPercentPoints: asPercentPoints);
    final vsYoy = formatMetricComparison(
      metric.vsSameMonthLastYear,
      asPercentPoints: asPercentPoints,
    );
    final parts = <String>[
      if (vsPrev.isNotEmpty) 'vs last month $vsPrev',
      if (vsYoy.isNotEmpty) 'vs last year $vsYoy',
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTokens.space2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: theme.textTheme.bodyMedium),
                if (parts.isNotEmpty)
                  Text(
                    parts.join(' · '),
                    style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                  ),
              ],
            ),
          ),
          Text(
            formatHeadlineValue(metric, kind: kind),
            style: theme.textTheme.titleMedium?.merge(AppTypography.numeral),
          ),
        ],
      ),
    );
  }
}

class _SourcesSection extends StatelessWidget {
  const _SourcesSection({required this.rows});
  final List<SourceSummaryRow> rows;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnalyticsSectionCard(
      eyebrow: 'Acquisition',
      title: 'Sources',
      child: rows.isEmpty
          ? Text('No sources this month.', style: theme.textTheme.bodyMedium)
          : Column(
              children: [
                for (final r in rows)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: AppTokens.space2),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${_sourceLabel(r.source)}${r.isBestConverting ? ' · best conversion' : ''}',
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                        Text(
                          '${r.enquiries} enq · ${r.bookings} booked',
                          style: theme.textTheme.bodySmall?.merge(AppTypography.numeral),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }
}

class _BookedSection extends StatelessWidget {
  const _BookedSection({required this.summary});
  final MonthlySummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = summary;
    return AnalyticsSectionCard(
      eyebrow: 'Bookings',
      title: 'What was booked',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Returning ${s.returningCustomers} · New ${s.newCustomers}',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: AppTokens.space3),
          const Eyebrow('By event type'),
          const SizedBox(height: AppTokens.space2),
          _CountTable(rows: s.bookingsByEventType, empty: 'No bookings'),
          const SizedBox(height: AppTokens.space3),
          const Eyebrow('By area'),
          const SizedBox(height: AppTokens.space2),
          _CountTable(rows: s.bookingsByArea, empty: 'No bookings'),
        ],
      ),
    );
  }
}

class _CountTable extends StatelessWidget {
  const _CountTable({required this.rows, required this.empty});
  final List<CountLabelRow> rows;
  final String empty;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (rows.isEmpty) {
      return Text(empty, style: theme.textTheme.bodySmall);
    }
    return Column(
      children: [
        for (final r in rows)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppTokens.space1),
            child: Row(
              children: [
                Expanded(child: Text(_sourceLabel(r.label), style: theme.textTheme.bodyMedium)),
                Text('${r.count}', style: theme.textTheme.bodyMedium?.merge(AppTypography.numeral)),
              ],
            ),
          ),
      ],
    );
  }
}

class _LostSection extends StatelessWidget {
  const _LostSection({required this.lost});
  final LostSummary lost;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnalyticsSectionCard(
      eyebrow: 'Pipeline',
      title: 'Lost',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('${lost.total} lost this month', style: theme.textTheme.bodyLarge),
          const SizedBox(height: AppTokens.space2),
          Text(
            'Before any conversation ${lost.beforeConversation} · After talks ${lost.afterTalks}',
            style: theme.textTheme.bodyMedium,
          ),
          if (lost.topReasons.isNotEmpty) ...[
            const SizedBox(height: AppTokens.space3),
            const Eyebrow('Top reasons'),
            const SizedBox(height: AppTokens.space2),
            _CountTable(rows: lost.topReasons, empty: ''),
          ],
        ],
      ),
    );
  }
}

class _EventsSection extends StatelessWidget {
  const _EventsSection({required this.events});
  final EventsDeliveredSummary events;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dayFmt = DateFormat('d MMM yyyy');
    String? busy;
    if (events.busiestDate != null && events.busiestCount > 0) {
      busy = '${dayFmt.format(events.busiestDate!.toLocal())} (${events.busiestCount})';
    }
    return AnalyticsSectionCard(
      eyebrow: 'Delivery',
      title: 'Events delivered',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('${events.total} events', style: theme.textTheme.bodyLarge),
          if (busy != null) ...[
            const SizedBox(height: AppTokens.space2),
            Text('Busiest date: $busy', style: theme.textTheme.bodyMedium),
          ],
          const SizedBox(height: AppTokens.space2),
          Text(
            'Days with 2+ events: ${events.daysWithTwoOrMore}',
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _TimingSection extends StatelessWidget {
  const _TimingSection({required this.timing});
  final TimingSummary timing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnalyticsSectionCard(
      eyebrow: 'Timing',
      title: 'Weekdays',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Most new enquiries: ${timing.busiestEnquiryWeekday ?? '—'}',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: AppTokens.space2),
          Text(
            'Most events: ${timing.busiestEventWeekday ?? '—'}',
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _TeamSection extends StatelessWidget {
  const _TeamSection({required this.team});
  final List<TeamMemberSummary> team;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnalyticsSectionCard(
      eyebrow: 'People',
      title: 'Team',
      child: team.isEmpty
          ? Text('No assigned enquiries this month.', style: theme.textTheme.bodyMedium)
          : Column(
              children: [
                for (final m in team)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: AppTokens.space2),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(m.name, style: theme.textTheme.titleSmall),
                        Text(
                          '${m.enquiriesAssigned} enquiries · ${m.bookingsConfirmed} bookings · '
                          'median ${formatDurationShort(m.medianFirstResponse)} · '
                          'contacts logged ${m.contactsLogged}',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }
}

class _WishesSection extends StatelessWidget {
  const _WishesSection({required this.wishes});
  final WishesSummary wishes;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnalyticsSectionCard(
      eyebrow: 'Re-engagement',
      title: 'Wishes',
      child: Text(
        '${wishes.sent} yearly wishes sent · ${wishes.cameBack} came back with a new enquiry',
        style: theme.textTheme.bodyMedium,
      ),
    );
  }
}

class _StillOpenSection extends StatelessWidget {
  const _StillOpenSection({required this.open});
  final StillOpenSummary open;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnalyticsSectionCard(
      eyebrow: 'Now',
      title: 'Still open',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('${open.openNow} in New or In Talks', style: theme.textTheme.bodyMedium),
          const SizedBox(height: AppTokens.space2),
          Text('Older than 30 days: ${open.olderThan30Days}', style: theme.textTheme.bodyMedium),
          const SizedBox(height: AppTokens.space2),
          Text(
            'Event date already passed: ${open.eventDatePassed}',
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _MonthAheadSection extends StatelessWidget {
  const _MonthAheadSection({required this.ahead});
  final MonthAheadSummary ahead;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dayFmt = DateFormat('d MMM');
    return AnalyticsSectionCard(
      eyebrow: 'Next',
      title: 'The month ahead',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'In Talks with a date next month: ${ahead.inTalksWithDate}',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: AppTokens.space3),
          const Eyebrow('Confirmed events by week'),
          const SizedBox(height: AppTokens.space2),
          for (final w in ahead.weeks)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppTokens.space1),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${dayFmt.format(w.weekStart.toLocal())} – ${dayFmt.format(w.weekEnd.subtract(const Duration(days: 1)).toLocal())}',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                  Text(
                    '${w.confirmedEvents}',
                    style: theme.textTheme.bodyMedium?.merge(AppTypography.numeral),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
