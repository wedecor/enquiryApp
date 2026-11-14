import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/tokens.dart';
import '../../../../../ui/primitives/primitives.dart';
import '../../../../reengagement/domain/occasion_reminder.dart';
import '../../domain/usage_summary.dart';
import '../usage_providers.dart';
import 'analytics_section_card.dart';
import 'analytics_state_views.dart';
import 'pipeline_sections.dart';

/// First release that records app usage (footer disclosure).
const kUsageTrackingSinceVersion = '2.0.34';

/// Team-tab section: time spent in the app for the selected analytics period.
class AppUsageSection extends ConsumerWidget {
  const AppUsageSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(teamAppUsageProvider);
    return AnalyticsSectionCard(
      eyebrow: 'App usage',
      title: 'Time spent in the app',
      subtitle: 'Active time with the app open and in use. Tap a column to sort.',
      child: async.when(
        loading: () => const Padding(
          padding: EdgeInsets.symmetric(vertical: AppTokens.space6),
          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ),
        error: (error, _) => AnalyticsErrorView(
          error: error.toString(),
          onRetry: () => ref.invalidate(teamAppUsageProvider),
        ),
        data: (summaries) {
          if (summaries.isEmpty) {
            return const AnalyticsEmptyState(
              icon: Icons.timer_outlined,
              message: 'No active users',
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: _usageTableWidth(context),
                  child: AppUsageTable(summaries: summaries),
                ),
              ),
              const SizedBox(height: AppTokens.space4),
              Text(
                'Counts time with the app open and in use. '
                'Recorded from version $kUsageTrackingSinceVersion.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w300,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

double _usageTableWidth(BuildContext context) {
  final available = MediaQuery.sizeOf(context).width - AppTokens.space4 * 2 - AppTokens.space5 * 2;
  return available < 640 ? 640 : available;
}

class AppUsageTable extends StatefulWidget {
  const AppUsageTable({super.key, required this.summaries});

  final List<UsageUserSummary> summaries;

  @override
  State<AppUsageTable> createState() => _AppUsageTableState();
}

class _AppUsageTableState extends State<AppUsageTable> {
  int _sortColumn = 1;
  bool _ascending = false;

  static const _columns = [
    MetricColumn('Name', flex: 3, numeric: false),
    MetricColumn('Time', flex: 2),
    MetricColumn('Avg / day', flex: 2),
    MetricColumn('Days'),
    MetricColumn('Opens'),
    MetricColumn('Last active', flex: 3, numeric: false),
  ];

  Comparable<dynamic> _sortKey(UsageUserSummary s) {
    switch (_sortColumn) {
      case 0:
        return s.name.toLowerCase();
      case 1:
        return s.hasActivity ? s.totalSeconds : -1;
      case 2:
        return s.hasActivity ? s.averageSecondsPerActiveDay : -1;
      case 3:
        return s.hasActivity ? s.daysActive : -1;
      case 4:
        return s.hasActivity ? s.totalOpens : -1;
      default:
        return s.lastSeenAt?.millisecondsSinceEpoch ?? -1;
    }
  }

  List<String> _rowCells(UsageUserSummary s) {
    if (!s.hasActivity) {
      return [s.name, 'No activity', '—', '—', '—', '—'];
    }
    return [
      s.name,
      formatUsageDuration(s.totalSeconds),
      formatUsageDuration(s.averageSecondsPerActiveDay),
      '${s.daysActive}',
      '${s.totalOpens}',
      formatLastActive(s.lastSeenAt),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final sorted = [...widget.summaries]
      ..sort((a, b) {
        final aInactive = !a.hasActivity;
        final bInactive = !b.hasActivity;
        if (aInactive != bInactive) return aInactive ? 1 : -1;
        final c = _sortKey(a).compareTo(_sortKey(b));
        return _ascending ? c : -c;
      });
    final muted = <int>{
      for (var i = 0; i < sorted.length; i++)
        if (!sorted[i].hasActivity) i,
    };
    return MetricTable(
      columns: _columns,
      sortColumn: _sortColumn,
      sortAscending: _ascending,
      mutedRowIndexes: muted,
      onHeaderTap: (c) => setState(() {
        if (_sortColumn == c) {
          _ascending = !_ascending;
        } else {
          _sortColumn = c;
          _ascending = c == 0 || c == 5;
        }
      }),
      onRowTap: (i) => _showDetail(context, sorted[i]),
      rows: [for (final s in sorted) _rowCells(s)],
    );
  }

  void _showDetail(BuildContext context, UsageUserSummary summary) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => _AppUsageDetailSheet(summary: summary),
    );
  }
}

class _AppUsageDetailSheet extends StatelessWidget {
  const _AppUsageDetailSheet({required this.summary});

  final UsageUserSummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final days = [...summary.days.reversed];
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AppTokens.space5, 0, AppTokens.space5, AppTokens.space5),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              summary.name,
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: AppTokens.space1),
            Text(
              summary.hasActivity
                  ? 'Last active ${formatLastActive(summary.lastSeenAt)}'
                  : 'No activity in this period',
              style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            ),
            if (summary.platform != null || summary.appVersion != null) ...[
              const SizedBox(height: AppTokens.space1),
              Text(
                [
                  if (summary.platform != null) summary.platform!,
                  if (summary.appVersion != null) 'v${summary.appVersion}',
                ].join(' · '),
                style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
              ),
            ],
            const SizedBox(height: AppTokens.space5),
            if (!summary.hasActivity || days.isEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: AppTokens.space4),
                child: Text(
                  'No day-by-day usage in this period.',
                  style: theme.textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                ),
              )
            else ...[
              const Eyebrow('Day by day'),
              const SizedBox(height: AppTokens.space2),
              ConstrainedBox(
                constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.45),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: days.length,
                  separatorBuilder: (_, _) => const SizedBox(height: AppTokens.space2),
                  itemBuilder: (context, i) {
                    final d = days[i];
                    final label = _dayLabel(d.day);
                    final mins = formatUsageDuration(d.activeSeconds);
                    return Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Text(
                            label,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            mins,
                            textAlign: TextAlign.right,
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            '${d.opens} open${d.opens == 1 ? '' : 's'}',
                            textAlign: TextAlign.right,
                            style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _dayLabel(String day) {
    final parts = day.split('-');
    if (parts.length != 3) return day;
    final y = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    final d = int.tryParse(parts[2]);
    if (y == null || m == null || d == null) return day;
    // Instant at noon IST so calendar helpers land on that day.
    final instant = IstDate.startOfDay(y, m, d).add(const Duration(hours: 12));
    return IstDate.short(instant);
  }
}
