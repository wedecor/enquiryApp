import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/theme/tokens.dart';
import '../../../../../services/dropdown_lookup.dart';
import '../../../../../ui/primitives/primitives.dart';
import '../../../../enquiries/presentation/screens/enquiry_details_screen.dart';
import '../../../users/presentation/users_providers.dart';
import '../../domain/pipeline_metrics.dart';
import '../pipeline_controller.dart';
import 'analytics_format.dart';
import 'analytics_section_card.dart';
import 'analytics_state_views.dart';

// ── Formatting ───────────────────────────────────────────────────────────────

String formatDurationShort(Duration? d) {
  if (d == null) return '—';
  if (d.inMinutes < 60) return '${d.inMinutes}m';
  if (d.inHours < 48) {
    final h = d.inMinutes / 60;
    return '${h.toStringAsFixed(h < 10 ? 1 : 0)}h';
  }
  final days = d.inHours / 24;
  return '${days.toStringAsFixed(days < 10 ? 1 : 0)}d';
}

String formatPercent(double fraction) => '${(fraction * 100).round()}%';

String _money(double v) => v == 0 ? '₹0' : formatAnalyticsCurrency(v);

void _openEnquiry(BuildContext context, String id) {
  if (id.isEmpty) return;
  Navigator.of(
    context,
  ).push<void>(MaterialPageRoute<void>(builder: (_) => EnquiryDetailsScreen(enquiryId: id)));
}

// ── Tab body ─────────────────────────────────────────────────────────────────

/// Bottom room so the last section clears the floating nav pill.
const double _bottomClearance = 96;
const double _gap = AppTokens.space4;

/// Watches [pipelineReportProvider] and lays [sections] out like the other
/// analytics tabs.
class PipelineTabBody extends ConsumerWidget {
  const PipelineTabBody({super.key, required this.sections});

  final List<Widget> Function(PipelineReport report) sections;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(pipelineReportProvider);
    return async.when(
      data: (report) {
        final children = [const AttributionToggle(), ...sections(report)];
        return ListView(
          padding: const EdgeInsets.fromLTRB(
            AppTokens.space4,
            AppTokens.space3,
            AppTokens.space4,
            _bottomClearance,
          ),
          children: [
            for (var i = 0; i < children.length; i++) ...[
              if (i > 0) const SizedBox(height: _gap),
              StaggerIn(index: i, child: children[i]),
            ],
          ],
        );
      },
      loading: () => const AnalyticsLoadingView(),
      error: (error, _) => AnalyticsErrorView(
        error: error.toString(),
        onRetry: () => ref.invalidate(pipelineReportProvider),
      ),
    );
  }
}

/// "Count by: Enquiry date | Event date".
class AttributionToggle extends ConsumerWidget {
  const AttributionToggle({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(analyticsAttributionProvider);
    return Row(
      children: [
        const Eyebrow('Count by'),
        const SizedBox(width: AppTokens.space3),
        Flexible(
          child: SegmentedButton<AnalyticsAttribution>(
            showSelectedIcon: false,
            style: const ButtonStyle(visualDensity: VisualDensity.compact),
            segments: [
              for (final a in AnalyticsAttribution.values)
                ButtonSegment(value: a, label: Text(a.label)),
            ],
            selected: {value},
            onSelectionChanged: (s) =>
                ref.read(analyticsAttributionProvider.notifier).state = s.first,
          ),
        ),
      ],
    );
  }
}

// ── Shared table ─────────────────────────────────────────────────────────────

class MetricColumn {
  const MetricColumn(this.label, {this.flex = 1, this.numeric = true});

  final String label;
  final int flex;
  final bool numeric;
}

/// Dense label/value table: eyebrow header, hairline-separated rows.
/// Rows with an [onTap] are tappable.
class MetricTable extends StatelessWidget {
  const MetricTable({
    super.key,
    required this.columns,
    required this.rows,
    this.onRowTap,
    this.onHeaderTap,
    this.sortColumn,
    this.sortAscending = false,
  });

  final List<MetricColumn> columns;
  final List<List<String>> rows;
  final void Function(int rowIndex)? onRowTap;
  final void Function(int columnIndex)? onHeaderTap;
  final int? sortColumn;
  final bool sortAscending;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final s = AppSurfaces.of(context);

    Widget cell(String text, MetricColumn col, {bool header = false, bool first = false}) {
      final style = header
          ? null
          : t.bodySmall?.copyWith(
              color: cs.onSurface,
              fontWeight: first ? FontWeight.w600 : FontWeight.w400,
              fontFeatures: const [FontFeature.tabularFigures()],
            );
      return Expanded(
        flex: col.flex,
        child: header
            ? Align(
                alignment: col.numeric ? Alignment.centerRight : Alignment.centerLeft,
                child: Eyebrow(text),
              )
            : Text(
                text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: col.numeric ? TextAlign.right : TextAlign.left,
                style: style,
              ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: AppTokens.space2),
          child: Row(
            children: [
              for (var c = 0; c < columns.length; c++)
                if (onHeaderTap == null)
                  cell(columns[c].label, columns[c], header: true)
                else
                  Expanded(
                    flex: columns[c].flex,
                    child: InkWell(
                      onTap: () => onHeaderTap!(c),
                      child: Row(
                        mainAxisAlignment: columns[c].numeric
                            ? MainAxisAlignment.end
                            : MainAxisAlignment.start,
                        children: [
                          Flexible(child: Eyebrow(columns[c].label)),
                          if (sortColumn == c)
                            Icon(
                              sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                              size: 12,
                              color: cs.onSurfaceVariant,
                            ),
                        ],
                      ),
                    ),
                  ),
            ],
          ),
        ),
        for (var r = 0; r < rows.length; r++)
          InkWell(
            onTap: onRowTap == null ? null : () => onRowTap!(r),
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: s.microBorder)),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppTokens.space2 + 2),
                child: Row(
                  children: [
                    for (var c = 0; c < columns.length; c++)
                      cell(rows[r][c], columns[c], first: c == 0),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Small label-over-number stat used in rows of KPIs.
class MiniStat extends StatelessWidget {
  const MiniStat({super.key, required this.label, required this.value, this.hint});

  final String label;
  final String value;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Eyebrow(label),
        const SizedBox(height: AppTokens.space1),
        Text(
          value,
          style: t.titleLarge
              ?.merge(AppTypography.numeral)
              .copyWith(fontSize: 24, color: cs.onSurface),
        ),
        if (hint != null) ...[
          const SizedBox(height: 2),
          Text(
            hint!,
            maxLines: 2,
            style: t.bodySmall?.copyWith(color: cs.onSurfaceVariant, fontWeight: FontWeight.w300),
          ),
        ],
      ],
    );
  }
}

class _StatWrap extends StatelessWidget {
  const _StatWrap({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppTokens.space6,
      runSpacing: AppTokens.space4,
      children: [
        for (final c in children)
          ConstrainedBox(constraints: const BoxConstraints(minWidth: 96), child: c),
      ],
    );
  }
}

/// One labelled proportional bar row (label · count · share).
class _BarRow extends StatelessWidget {
  const _BarRow({required this.label, required this.value, required this.fraction, this.trailing});

  final String label;
  final String value;
  final double fraction;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final s = AppSurfaces.of(context);
    final f = fraction.isNaN ? 0.0 : fraction.clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTokens.space2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: t.bodyMedium?.copyWith(color: cs.onSurface),
                ),
              ),
              Text(
                value,
                style: t.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              if (trailing != null)
                SizedBox(
                  width: 56,
                  child: Text(
                    trailing!,
                    textAlign: TextAlign.right,
                    style: t.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppTokens.space1 + 2),
          ProportionStrip(height: 3, segments: [(f, s.accent), (1 - f, s.microBorder)]),
        ],
      ),
    );
  }
}

// ── Overview additions ───────────────────────────────────────────────────────

/// Median response, weighted pipeline, booked value and a compact funnel line.
class PipelineOverviewSection extends ConsumerWidget {
  const PipelineOverviewSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(pipelineReportProvider);
    return async.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (r) => AnalyticsSectionCard(
        eyebrow: 'Pipeline',
        title: 'At a glance',
        subtitle: 'Counted by ${r.attribution.label.toLowerCase()}',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _StatWrap(
              children: [
                MiniStat(
                  label: 'Median response',
                  value: formatDurationShort(r.speed.median),
                  hint: r.speed.hasData ? '${r.speed.sampleSize} contacted' : 'No contact data yet',
                ),
                MiniStat(
                  label: 'Weighted pipeline',
                  value: _money(r.forecast.expectedValue),
                  hint: '${r.forecast.openCount} in talks',
                ),
                MiniStat(label: 'Booked value', value: _money(r.bookedValueInPeriod)),
              ],
            ),
            const SizedBox(height: AppTokens.space5),
            FunnelSteps(funnel: r.funnel, compact: true),
          ],
        ),
      ),
    );
  }
}

// ── Pipeline tab ─────────────────────────────────────────────────────────────

/// New → In Talks → Approved → Completed with counts and step conversion.
class FunnelSteps extends StatelessWidget {
  const FunnelSteps({super.key, required this.funnel, this.compact = false});

  final FunnelReport funnel;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final f = funnel;
    final steps = <(String, int)>[
      ('Enquiries', f.total),
      ('In Talks', f.reachedInTalks),
      ('Approved', f.reachedApproved),
      ('Completed', f.reachedCompleted),
    ];
    String step(int i) {
      if (i == 0) return '';
      final prev = steps[i - 1].$2;
      return prev == 0 ? '—' : formatPercent(steps[i].$2 / prev);
    }

    if (f.total == 0) {
      return const AnalyticsEmptyState(
        icon: Icons.filter_alt_outlined,
        message: 'No enquiries in this period',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < steps.length; i++)
          _BarRow(
            label: steps[i].$1,
            value: '${steps[i].$2}',
            fraction: steps[i].$2 / f.total,
            trailing: i == 0 ? null : step(i),
          ),
        if (!compact) ...[
          const SizedBox(height: AppTokens.space3),
          MetricTable(
            columns: const [MetricColumn('Lost', flex: 3, numeric: false), MetricColumn('Count')],
            rows: [
              ['Before In Talks', '${f.lostBeforeInTalks}'],
              ['After In Talks', '${f.lostAfterInTalks}'],
              ['After Approved', '${f.lostAfterApproved}'],
              ['Still open', '${f.open}'],
            ],
          ),
        ],
      ],
    );
  }
}

class FunnelSection extends StatelessWidget {
  const FunnelSection({super.key, required this.report});

  final PipelineReport report;

  @override
  Widget build(BuildContext context) {
    return AnalyticsSectionCard(
      eyebrow: 'Conversion',
      title: 'Funnel',
      subtitle: 'How far enquiries in this period got. % = conversion from the step above.',
      child: FunnelSteps(funnel: report.funnel),
    );
  }
}

class LostReasonsSection extends StatelessWidget {
  const LostReasonsSection({super.key, required this.report});

  final PipelineReport report;

  @override
  Widget build(BuildContext context) {
    final items = report.lostReasons;
    final total = items.fold<int>(0, (a, b) => a + b.count);
    return AnalyticsSectionCard(
      eyebrow: 'Why we lose',
      title: 'Lost reasons',
      child: items.isEmpty
          ? const AnalyticsEmptyState(
              icon: Icons.thumb_down_alt_outlined,
              message: 'No lost enquiries in this period',
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final item in items)
                  _BarRow(
                    label: item.label,
                    value: '${item.count}',
                    fraction: total == 0 ? 0 : item.count / total,
                    trailing: total == 0 ? null : formatPercent(item.count / total),
                  ),
              ],
            ),
    );
  }
}

class SpeedToLeadSection extends StatelessWidget {
  const SpeedToLeadSection({super.key, required this.report});

  final PipelineReport report;

  @override
  Widget build(BuildContext context) {
    final sp = report.speed;
    return AnalyticsSectionCard(
      eyebrow: 'Speed to lead',
      title: 'Response time',
      subtitle: 'Created → first call/WhatsApp from the app',
      child: !sp.hasData
          ? const AnalyticsEmptyState(
              icon: Icons.timer_outlined,
              message: 'No response-time data yet',
              hint: 'Appears once calls / WhatsApp are made from the app.',
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _StatWrap(
                  children: [
                    MiniStat(label: 'Median', value: formatDurationShort(sp.median)),
                    MiniStat(label: '75% within', value: formatDurationShort(sp.p75)),
                    MiniStat(label: '≤ 1 hour', value: formatPercent(sp.within1h)),
                    MiniStat(label: '≤ 24 hours', value: formatPercent(sp.within24h)),
                    MiniStat(label: 'Never contacted', value: '${sp.neverContacted}'),
                  ],
                ),
                const SizedBox(height: AppTokens.space5),
                MetricTable(
                  columns: const [
                    MetricColumn('Responded', flex: 3, numeric: false),
                    MetricColumn('Leads'),
                    MetricColumn('Win rate'),
                  ],
                  rows: [
                    for (final b in sp.buckets)
                      [
                        b.label,
                        '${b.leads}',
                        (b.won + b.lost) == 0 ? '—' : formatPercent(b.winRate),
                      ],
                  ],
                ),
                if (sp.estimatedExcluded > 0) ...[
                  const SizedBox(height: AppTokens.space2),
                  Text(
                    '${sp.estimatedExcluded} older enquiries with estimated contact times are excluded.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
    );
  }
}

class FollowUpSection extends ConsumerWidget {
  const FollowUpSection({super.key, required this.report});

  final PipelineReport report;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fu = report.followUp;
    final items = fu.notContacted7d.take(15).toList();
    String avg(double? v) => v == null ? '—' : v.toStringAsFixed(1);
    return AnalyticsSectionCard(
      eyebrow: 'Discipline',
      title: 'Follow-up',
      subtitle: 'Open enquiries not contacted for 7+ days',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _StatWrap(
            children: [
              MiniStat(label: 'Not contacted 7d+', value: '${fu.notContacted7d.length}'),
              MiniStat(label: 'Contacts per win', value: avg(fu.avgContactsBeforeWin)),
              MiniStat(label: 'Contacts per loss', value: avg(fu.avgContactsBeforeLoss)),
              MiniStat(label: 'Reminders sent', value: '${fu.remindersSent}'),
            ],
          ),
          if (items.isNotEmpty) ...[
            const SizedBox(height: AppTokens.space5),
            MetricTable(
              columns: const [
                MetricColumn('Customer', flex: 3, numeric: false),
                MetricColumn('Assignee', flex: 2, numeric: false),
                MetricColumn('Days'),
              ],
              rows: [
                for (final i in items)
                  [i.customerName, _assigneeName(ref, i.assignedTo), '${i.daysSinceContact}'],
              ],
              onRowTap: (index) => _openEnquiry(context, items[index].id),
            ),
          ],
        ],
      ),
    );
  }
}

String _assigneeName(WidgetRef ref, String? uid) {
  if (uid == null || uid.isEmpty) return 'Unassigned';
  return ref.watch(userDisplayNameProvider(uid)).maybeWhen(data: (name) => name, orElse: () => '…');
}

// ── Team & sources ───────────────────────────────────────────────────────────

/// Sortable performance table, shared by team (assignee) and source views.
class PerformanceTable extends StatefulWidget {
  const PerformanceTable({super.key, required this.rows, required this.nameOf});

  final List<PerformanceRow> rows;
  final String Function(PerformanceRow row) nameOf;

  @override
  State<PerformanceTable> createState() => _PerformanceTableState();
}

class _PerformanceTableState extends State<PerformanceTable> {
  int _sortColumn = 1;
  bool _ascending = false;

  static const _columns = [
    MetricColumn('Name', flex: 3, numeric: false),
    MetricColumn('Leads'),
    MetricColumn('Open'),
    MetricColumn('Stale'),
    MetricColumn('Win %'),
    MetricColumn('Resp.'),
    MetricColumn('Booked', flex: 2),
  ];

  Comparable<dynamic> _sortKey(PerformanceRow r) {
    switch (_sortColumn) {
      case 0:
        return widget.nameOf(r).toLowerCase();
      case 1:
        return r.leads;
      case 2:
        return r.open;
      case 3:
        return r.stale;
      case 4:
        return r.winRate;
      case 5:
        return r.medianResponse?.inMinutes ?? 1 << 30;
      default:
        return r.bookedValue;
    }
  }

  @override
  Widget build(BuildContext context) {
    final sorted = [...widget.rows]
      ..sort((a, b) {
        final c = _sortKey(a).compareTo(_sortKey(b));
        return _ascending ? c : -c;
      });
    return MetricTable(
      columns: _columns,
      sortColumn: _sortColumn,
      sortAscending: _ascending,
      onHeaderTap: (c) => setState(() {
        if (_sortColumn == c) {
          _ascending = !_ascending;
        } else {
          _sortColumn = c;
          _ascending = c == 0 || c == 5;
        }
      }),
      rows: [
        for (final r in sorted)
          [
            widget.nameOf(r),
            '${r.leads}',
            '${r.open}',
            '${r.stale}',
            (r.won + r.lost) == 0 ? '—' : formatPercent(r.winRate),
            formatDurationShort(r.medianResponse),
            _money(r.bookedValue),
          ],
      ],
    );
  }
}

class TeamSection extends ConsumerWidget {
  const TeamSection({super.key, required this.report});

  final PipelineReport report;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final names = {for (final r in report.team) r.key: _assigneeName(ref, r.key)};
    return AnalyticsSectionCard(
      eyebrow: 'People',
      title: 'Team performance',
      subtitle: 'Enquiries in this period by assignee. Tap a column to sort.',
      child: report.team.isEmpty
          ? const AnalyticsEmptyState(icon: Icons.groups_outlined)
          : SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: _tableWidth(context),
                child: PerformanceTable(
                  rows: report.team,
                  nameOf: (r) => names[r.key] ?? 'Unknown',
                ),
              ),
            ),
    );
  }
}

class SourcePerformanceSection extends ConsumerWidget {
  const SourcePerformanceSection({super.key, required this.report});

  final PipelineReport report;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lookup = ref.watch(dropdownLookupProvider).maybeWhen(data: (l) => l, orElse: () => null);
    return AnalyticsSectionCard(
      eyebrow: 'Channels',
      title: 'Source performance',
      subtitle: 'Which sources bring bookings, not just enquiries',
      child: report.sources.isEmpty
          ? const AnalyticsEmptyState(icon: Icons.campaign_outlined)
          : SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: _tableWidth(context),
                child: PerformanceTable(
                  rows: report.sources,
                  nameOf: (r) => r.key == 'unknown'
                      ? 'Unknown'
                      : (lookup?.labelForSource(r.key) ?? DropdownLookup.titleCase(r.key)),
                ),
              ),
            ),
    );
  }
}

/// Tables keep a readable minimum width and scroll sideways on phones.
double _tableWidth(BuildContext context) {
  final available = MediaQuery.sizeOf(context).width - AppTokens.space4 * 2 - AppTokens.space5 * 2;
  return available < 560 ? 560 : available;
}

// ── Money tab ────────────────────────────────────────────────────────────────

class MoneyByMonthSection extends StatelessWidget {
  const MoneyByMonthSection({super.key, required this.report});

  final PipelineReport report;

  @override
  Widget build(BuildContext context) {
    final months = report.money;
    final maxBooked = months.fold<double>(0, (m, e) => e.booked > m ? e.booked : m);
    final s = AppSurfaces.of(context);
    final fmt = DateFormat('MMM yyyy');
    return AnalyticsSectionCard(
      eyebrow: 'Cash',
      title: 'Booked by event month',
      subtitle: 'Approved & completed bookings · advance collected vs balance due',
      child: maxBooked == 0
          ? const AnalyticsEmptyState(
              icon: Icons.account_balance_wallet_outlined,
              message: 'No bookings in the next 6 months',
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                MetricTable(
                  columns: const [
                    MetricColumn('Month', flex: 2, numeric: false),
                    MetricColumn('Events'),
                    MetricColumn('Booked', flex: 2),
                    MetricColumn('Collected', flex: 2),
                    MetricColumn('Due', flex: 2),
                  ],
                  rows: [
                    for (final m in months)
                      [
                        fmt.format(m.month),
                        '${m.bookings}',
                        _money(m.booked),
                        _money(m.collected),
                        _money(m.outstanding),
                      ],
                  ],
                ),
                const SizedBox(height: AppTokens.space4),
                for (final m in months)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppTokens.space2),
                    child: Row(
                      children: [
                        SizedBox(width: 64, child: Eyebrow(DateFormat('MMM').format(m.month))),
                        Expanded(
                          child: ProportionStrip(
                            height: 8,
                            segments: [
                              (m.collected.clamp(0, m.booked).toDouble(), s.accent),
                              (m.outstanding, s.accent.withValues(alpha: 0.3)),
                              (
                                (maxBooked - m.booked).clamp(0, maxBooked).toDouble(),
                                s.microBorder,
                              ),
                            ],
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

class OverdueSection extends StatelessWidget {
  const OverdueSection({super.key, required this.report});

  final PipelineReport report;

  @override
  Widget build(BuildContext context) {
    final items = report.overdue.take(20).toList();
    final total = report.overdue.fold<double>(0, (a, b) => a + b.outstanding);
    final fmt = DateFormat('d MMM yyyy');
    return AnalyticsSectionCard(
      eyebrow: 'Collections',
      title: 'Overdue balances',
      subtitle: items.isEmpty
          ? 'Past events with a balance still due'
          : '${report.overdue.length} past events · ${_money(total)} due',
      child: items.isEmpty
          ? const AnalyticsEmptyState(icon: Icons.check_circle_outline, message: 'Nothing overdue')
          : MetricTable(
              columns: const [
                MetricColumn('Customer', flex: 3, numeric: false),
                MetricColumn('Event', flex: 2),
                MetricColumn('Due', flex: 2),
              ],
              rows: [
                for (final i in items)
                  [i.customerName, fmt.format(i.eventDate), _money(i.outstanding)],
              ],
              onRowTap: (index) => _openEnquiry(context, items[index].id),
            ),
    );
  }
}

class ForecastSection extends StatelessWidget {
  const ForecastSection({super.key, required this.report});

  final PipelineReport report;

  @override
  Widget build(BuildContext context) {
    final f = report.forecast;
    return AnalyticsSectionCard(
      eyebrow: 'Forecast',
      title: 'Weighted pipeline',
      subtitle:
          '${f.openCount} in talks · value from quotes (${f.quotedCount}) or average booking for the event type · '
          'win rate ${formatPercent(f.winProbability)} over the last 12 months (${f.decidedSample} decided)',
      child: _StatWrap(
        children: [
          MiniStat(label: 'Expected', value: _money(f.expectedValue)),
          MiniStat(label: 'If all close', value: _money(f.totalValue)),
          MiniStat(label: 'Win rate', value: formatPercent(f.winProbability)),
        ],
      ),
    );
  }
}

// ── Demand (Breakdown tab) ───────────────────────────────────────────────────

class LeadTimeSection extends StatelessWidget {
  const LeadTimeSection({super.key, required this.report});

  final PipelineReport report;

  @override
  Widget build(BuildContext context) {
    final items = report.leadTime;
    final total = items.fold<int>(0, (a, b) => a + b.count);
    return AnalyticsSectionCard(
      eyebrow: 'Demand',
      title: 'How far ahead people enquire',
      child: total == 0
          ? const AnalyticsEmptyState(icon: Icons.schedule_outlined)
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final item in items)
                  _BarRow(
                    label: item.label,
                    value: '${item.count}',
                    fraction: item.count / total,
                    trailing: formatPercent(item.count / total),
                  ),
              ],
            ),
    );
  }
}

class UpcomingDemandSection extends ConsumerWidget {
  const UpcomingDemandSection({super.key, required this.report});

  final PipelineReport report;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lookup = ref.watch(dropdownLookupProvider).maybeWhen(data: (l) => l, orElse: () => null);
    final months = report.upcomingDemand;
    final max = months.fold<int>(0, (m, e) => e.total > m ? e.total : m);
    final fmt = DateFormat('MMM yyyy');
    String top(MonthDemand m) {
      final entries = m.byEventType.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
      return entries
          .take(3)
          .map(
            (e) =>
                '${lookup?.labelForEventType(e.key) ?? DropdownLookup.titleCase(e.key)} ${e.value}',
          )
          .join(' · ');
    }

    return AnalyticsSectionCard(
      eyebrow: 'Capacity',
      title: 'Busy months ahead',
      subtitle: 'Upcoming events (not lost) for the next 12 months',
      child: max == 0
          ? const AnalyticsEmptyState(
              icon: Icons.event_busy_outlined,
              message: 'No upcoming events',
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final m in months)
                  _BarRow(
                    label: m.total == 0
                        ? fmt.format(m.month)
                        : '${fmt.format(m.month)} — ${top(m)}',
                    value: '${m.total}',
                    fraction: max == 0 ? 0 : m.total / max,
                  ),
              ],
            ),
    );
  }
}
