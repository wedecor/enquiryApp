import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/theme/tokens.dart';
import '../../../../../services/dropdown_lookup.dart';
import '../../../../../ui/primitives/primitives.dart';
import '../../../../reengagement/domain/occasion_reminder.dart';
import '../../domain/timing_metrics.dart';
import '../timing_controller.dart';
import 'analytics_section_card.dart';
import 'analytics_state_views.dart';
import 'pipeline_sections.dart';

/// Website-only filter for the time-of-day grid (section 2).
final timingWebsiteOnlyProvider = StateProvider.autoDispose<bool>((ref) => false);

const double _timingBottom = 96;
const double _timingGap = AppTokens.space4;

/// Timing tab body — watches [timingReportProvider] independently of attribution.
class AnalyticsTimingTab extends ConsumerWidget {
  const AnalyticsTimingTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(timingReportProvider);
    return async.when(
      loading: () => const AnalyticsLoadingView(),
      error: (e, _) => AnalyticsErrorView(
        error: e.toString(),
        onRetry: () => ref.invalidate(timingReportProvider),
      ),
      data: (report) {
        final children = [
          WeekdayEnquiriesSection(report: report.weekdayEnquiries),
          TimeOfDayEnquiriesSection(
            all: report.timeOfDay,
            websiteOnly: report.timeOfDayWebsiteOnly,
          ),
          ResponseByArrivalSection(report: report.responseArrival),
          EventsByWeekdaySection(report: report.eventsByWeekday),
          BusiestDatesSection(report: report.busiestDates),
          SeasonSection(report: report.season),
          LeadTimeWinSection(report: report.leadTime),
        ];
        return ListView(
          padding: const EdgeInsets.fromLTRB(
            AppTokens.space4,
            AppTokens.space3,
            AppTokens.space4,
            _timingBottom,
          ),
          children: [
            for (var i = 0; i < children.length; i++) ...[
              if (i > 0) const SizedBox(height: _timingGap),
              StaggerIn(index: i, child: children[i]),
            ],
          ],
        );
      },
    );
  }
}

// ── Shared helpers ───────────────────────────────────────────────────────────

String _share(int part, int total) => total == 0 ? '—' : formatPercent(part / total);

Color _heatColor(BuildContext context, int value, int max) {
  final s = AppSurfaces.of(context);
  if (max <= 0 || value <= 0) return s.microBorder.withValues(alpha: 0.15);
  final t = (value / max).clamp(0.0, 1.0);
  final step = t <= 0.25
      ? 0.18
      : t <= 0.5
      ? 0.35
      : t <= 0.75
      ? 0.55
      : 0.78;
  return Color.lerp(s.microBorder, s.accent, step)!;
}

String _typeLabel(WidgetRef ref, String key) {
  if (key == 'Other' || key == 'unknown') return key == 'unknown' ? 'Unknown' : key;
  final lookup = ref.watch(dropdownLookupProvider).maybeWhen(data: (l) => l, orElse: () => null);
  return lookup?.labelForEventType(key) ?? DropdownLookup.titleCase(key);
}

// ── Section 1 ────────────────────────────────────────────────────────────────

class WeekdayEnquiriesSection extends StatelessWidget {
  const WeekdayEnquiriesSection({super.key, required this.report});

  final WeekdayEnquiryReport report;

  @override
  Widget build(BuildContext context) {
    final total = report.total;
    return AnalyticsSectionCard(
      eyebrow: 'Arrival',
      title: 'Enquiries by day of the week',
      subtitle: 'Enquiries created in this period (by enquiry date)',
      child: total == 0
          ? const AnalyticsEmptyState(icon: Icons.calendar_view_week_outlined)
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  report.summary,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: AppTokens.space4),
                for (final r in report.rows)
                  _BarRowPublic(
                    label: r.label,
                    value: '${r.enquiries}',
                    fraction: total == 0 ? 0 : r.enquiries / total,
                    trailing:
                        '${_share(r.enquiries, total)} · '
                        'W ${r.won} · L ${r.lost} · '
                        '${formatWinRateOrDash(r.won, r.lost)}',
                  ),
              ],
            ),
    );
  }
}

/// Public wrapper around the private bar row used in pipeline sections.
class _BarRowPublic extends StatelessWidget {
  const _BarRowPublic({
    required this.label,
    required this.value,
    required this.fraction,
    this.trailing,
  });

  final String label;
  final String value;
  final double fraction;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final s = AppSurfaces.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTokens.space3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(label, style: t.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
              ),
              Text(
                value,
                style: t.bodyMedium?.copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
              ),
              if (trailing != null) ...[
                const SizedBox(width: AppTokens.space3),
                Flexible(
                  child: Text(
                    trailing!,
                    textAlign: TextAlign.right,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: t.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: AppTokens.space1),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: fraction.clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: s.microBorder,
              color: s.accent,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Section 2 ────────────────────────────────────────────────────────────────

class TimeOfDayEnquiriesSection extends ConsumerWidget {
  const TimeOfDayEnquiriesSection({super.key, required this.all, required this.websiteOnly});

  final TimeOfDayGrid all;
  final TimeOfDayGrid websiteOnly;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onlyWeb = ref.watch(timingWebsiteOnlyProvider);
    final grid = onlyWeb ? websiteOnly : all;
    final max = grid.cells.expand((r) => r).fold<int>(0, (m, v) => v > m ? v : m);
    final cs = Theme.of(context).colorScheme;
    return AnalyticsSectionCard(
      eyebrow: 'Arrival',
      title: 'Enquiries by time of day',
      subtitle: 'Enquiries created in this period (by enquiry date)',
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Website only',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant),
          ),
          Switch.adaptive(
            value: onlyWeb,
            onChanged: (v) => ref.read(timingWebsiteOnlyProvider.notifier).state = v,
          ),
        ],
      ),
      child: grid.grandTotal == 0
          ? const AnalyticsEmptyState(icon: Icons.schedule_outlined)
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: _TimeGridTable(grid: grid, max: max),
                ),
                const SizedBox(height: AppTokens.space3),
                Text(
                  'Website enquiries are timed exactly. '
                  'Enquiries entered by the team show when they were typed in.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w300,
                  ),
                ),
              ],
            ),
    );
  }
}

class _TimeGridTable extends StatelessWidget {
  const _TimeGridTable({required this.grid, required this.max});

  final TimeOfDayGrid grid;
  final int max;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    Widget header(String text) => SizedBox(
      width: 72,
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: t.labelSmall?.copyWith(color: cs.onSurfaceVariant),
      ),
    );
    Widget cell(int n, {bool total = false}) => Container(
      width: 72,
      height: 40,
      alignment: Alignment.center,
      color: total ? null : _heatColor(context, n, max),
      child: Text(
        '$n',
        style: t.bodySmall?.copyWith(
          fontWeight: total ? FontWeight.w700 : FontWeight.w500,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const SizedBox(width: 88),
            for (final b in TimeOfDayBucket.values) header(b.label),
            header('Total'),
          ],
        ),
        for (var w = 0; w < 7; w++)
          Row(
            children: [
              SizedBox(
                width: 88,
                child: Text(
                  kWeekdayLabels[w],
                  style: t.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              for (var c = 0; c < TimeOfDayBucket.values.length; c++) cell(grid.cells[w][c]),
              cell(grid.rowTotals[w], total: true),
            ],
          ),
        Row(
          children: [
            SizedBox(
              width: 88,
              child: Text('Total', style: t.bodySmall?.copyWith(fontWeight: FontWeight.w700)),
            ),
            for (final n in grid.colTotals) cell(n, total: true),
            cell(grid.grandTotal, total: true),
          ],
        ),
      ],
    );
  }
}

// ── Section 3 ────────────────────────────────────────────────────────────────

class ResponseByArrivalSection extends StatelessWidget {
  const ResponseByArrivalSection({super.key, required this.report});

  final ResponseArrivalReport report;

  @override
  Widget build(BuildContext context) {
    final empty = report.byWeekday.every((r) => r.enquiries == 0);
    return AnalyticsSectionCard(
      eyebrow: 'Speed',
      title: 'Response time by when the enquiry arrived',
      subtitle:
          'Enquiries created in this period — same first-contact rules as Response time '
          '(estimated contacts excluded)',
      child: empty
          ? const AnalyticsEmptyState(icon: Icons.timer_outlined)
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'By weekday of arrival',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: AppTokens.space2),
                _ResponseTable(rows: report.byWeekday),
                const SizedBox(height: AppTokens.space5),
                Text(
                  'By time of day',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: AppTokens.space2),
                _ResponseTable(rows: report.byBucket),
              ],
            ),
    );
  }
}

class _ResponseTable extends StatelessWidget {
  const _ResponseTable({required this.rows});

  final List<ResponseArrivalRow> rows;

  @override
  Widget build(BuildContext context) {
    return MetricTable(
      columns: const [
        MetricColumn('When', flex: 3, numeric: false),
        MetricColumn('Enq.'),
        MetricColumn('Median', flex: 2),
        MetricColumn('<24h'),
        MetricColumn('Never'),
        MetricColumn('Win %'),
      ],
      rows: [
        for (final r in rows)
          [
            r.label,
            '${r.enquiries}',
            r.median == null ? '—' : formatDurationShort(r.median),
            r.within24h == null ? '—' : formatPercent(r.within24h!),
            '${r.neverContacted}',
            formatWinRateOrDash(r.won, r.lost),
          ],
      ],
    );
  }
}

// ── Section 4 ────────────────────────────────────────────────────────────────

class EventsByWeekdaySection extends ConsumerWidget {
  const EventsByWeekdaySection({super.key, required this.report});

  final WeekdayEventReport report;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final total = report.total;
    final typeCols = report.typeColumns;
    return AnalyticsSectionCard(
      eyebrow: 'Events',
      title: 'Events by day of the week',
      subtitle:
          'Functions dated in this period on approved/completed bookings '
          '(by function date; ignores the created/event attribution toggle)',
      child: total == 0
          ? const AnalyticsEmptyState(icon: Icons.event_outlined)
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  report.summary,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: AppTokens.space4),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: 560,
                    child: MetricTable(
                      columns: [
                        const MetricColumn('Day', flex: 3, numeric: false),
                        const MetricColumn('Events'),
                        const MetricColumn('Share'),
                        for (final t in typeCols) MetricColumn(_typeLabel(ref, t), flex: 2),
                      ],
                      rows: [
                        for (final r in report.rows)
                          [
                            r.label,
                            '${r.events}',
                            _share(r.events, total),
                            for (final t in typeCols) '${r.byType[t] ?? 0}',
                          ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

// ── Section 5 ────────────────────────────────────────────────────────────────

class BusiestDatesSection extends StatelessWidget {
  const BusiestDatesSection({super.key, required this.report});

  final BusiestDatesReport report;

  @override
  Widget build(BuildContext context) {
    final empty = report.topDates.isEmpty;
    return AnalyticsSectionCard(
      eyebrow: 'Events',
      title: 'Busiest dates',
      subtitle:
          'Functions dated in this period on approved/completed bookings '
          '(by function date; ignores the created/event attribution toggle)',
      child: empty
          ? const AnalyticsEmptyState(icon: Icons.event_busy_outlined)
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Wrap(
                  spacing: AppTokens.space6,
                  runSpacing: AppTokens.space4,
                  children: [
                    MiniStat(label: 'Most on one day', value: '${report.maxOnSingleDay}'),
                    MiniStat(label: 'Days with 2+', value: '${report.daysWith2Plus}'),
                    MiniStat(label: 'Days with 3+', value: '${report.daysWith3Plus}'),
                  ],
                ),
                const SizedBox(height: AppTokens.space5),
                MetricTable(
                  columns: const [
                    MetricColumn('Date', flex: 4, numeric: false),
                    MetricColumn('Events'),
                    MetricColumn('Types', flex: 4, numeric: false),
                  ],
                  rows: [
                    for (final d in report.topDates)
                      [
                        '${IstDate.short(d.dayStart)} '
                            '(${kWeekdayLabels[istWeekdayIndex(d.dayStart)]})',
                        '${d.events}',
                        d.eventTypes.join(', '),
                      ],
                  ],
                ),
              ],
            ),
    );
  }
}

// ── Section 6 ────────────────────────────────────────────────────────────────

class SeasonSection extends ConsumerWidget {
  const SeasonSection({super.key, required this.report});

  final SeasonReport report;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fmt = DateFormat('MMM yyyy');
    final empty = report.rows.every((r) => r.total == 0);
    return AnalyticsSectionCard(
      eyebrow: 'Season',
      title: 'Season by event type',
      subtitle:
          'Last 12 months vs the 12 before — functions by function date (approved + completed)',
      child: empty
          ? const AnalyticsEmptyState(icon: Icons.calendar_month_outlined)
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (report.note != null) ...[
                  Text(
                    report.note!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppTokens.space3),
                ],
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: report.hasYearEarlier ? 720 : 560,
                    child: MetricTable(
                      columns: [
                        const MetricColumn('Month', flex: 3, numeric: false),
                        for (final t in report.typeColumns)
                          MetricColumn(_typeLabel(ref, t), flex: 2),
                        const MetricColumn('Other'),
                        const MetricColumn('Total'),
                        if (report.hasYearEarlier) ...[
                          const MetricColumn('Year ago', flex: 2),
                          const MetricColumn('Change'),
                        ],
                      ],
                      rows: [
                        for (final r in report.rows)
                          [
                            fmt.format(DateTime(r.monthStart.year, r.monthStart.month)),
                            for (final t in report.typeColumns) '${r.byType[t] ?? 0}',
                            '${r.other}',
                            '${r.total}',
                            if (report.hasYearEarlier) ...[
                              '${r.priorTotal ?? 0}',
                              r.change == null
                                  ? '—'
                                  : (r.change! > 0 ? '+${r.change}' : '${r.change}'),
                            ],
                          ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

// ── Section 7 ────────────────────────────────────────────────────────────────

class LeadTimeWinSection extends StatelessWidget {
  const LeadTimeWinSection({super.key, required this.report});

  final LeadTimeWinReport report;

  @override
  Widget build(BuildContext context) {
    final total = report.total;
    return AnalyticsSectionCard(
      eyebrow: 'Demand',
      title: 'How far ahead people enquire',
      subtitle:
          'Per event (function) for enquiries created in this period — '
          'enquiry date to each function\'s date',
      child: total == 0
          ? const AnalyticsEmptyState(icon: Icons.schedule_outlined)
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  report.summary,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: AppTokens.space4),
                for (final item in report.rows)
                  _BarRowPublic(
                    label: item.label,
                    value: '${item.count}',
                    fraction: total == 0 ? 0 : item.count / total,
                    trailing:
                        '${_share(item.count, total)} · '
                        'W ${item.won} · L ${item.lost} · '
                        '${formatWinRateOrDash(item.won, item.lost)}',
                  ),
              ],
            ),
    );
  }
}
