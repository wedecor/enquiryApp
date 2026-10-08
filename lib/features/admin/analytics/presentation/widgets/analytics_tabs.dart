import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/tokens.dart';
import '../../../../../ui/primitives/primitives.dart';
import '../../../../reengagement/presentation/reengagement_analytics_card.dart';
import '../../domain/analytics_models.dart';
import '../../domain/pipeline_metrics.dart';
import '../analytics_controller.dart';
import '../pipeline_controller.dart';
import 'analytics_format.dart';
import 'analytics_state_views.dart';
import 'breakdown_charts.dart';
import 'line_trend_chart.dart';
import 'pipeline_sections.dart';
import 'recent_enquiries_table.dart';
import 'top_list_table.dart';

/// Bottom room so the last section clears the floating nav pill.
const double _bottomClearance = 96;
const double _gap = AppTokens.space4;

/// Shared scaffold for an analytics tab: watches the controller and lays the
/// sections out as a staggered list.
class _AnalyticsTabBody extends ConsumerWidget {
  const _AnalyticsTabBody({required this.onRetry, required this.sections});

  final VoidCallback onRetry;
  final List<Widget> Function(AnalyticsState state) sections;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analyticsAsync = ref.watch(analyticsControllerProvider);

    return analyticsAsync.when(
      data: (state) {
        final children = sections(state);
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
      error: (error, stack) => AnalyticsErrorView(error: error.toString(), onRetry: onRetry),
    );
  }
}

class AnalyticsOverviewTab extends StatelessWidget {
  const AnalyticsOverviewTab({super.key, required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return _AnalyticsTabBody(
      onRetry: onRetry,
      sections: (state) => [
        const PipelineOverviewSection(),
        LineTrendChart(
          data: state.timeSeries,
          title: 'Enquiries Trend',
          subtitle: formatAnalyticsDateRange(state.filters.dateRange),
        ),
      ],
    );
  }
}

class AnalyticsTrendsTab extends StatelessWidget {
  const AnalyticsTrendsTab({super.key, required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return _AnalyticsTabBody(
      onRetry: onRetry,
      sections: (state) => [
        LineTrendChart(
          data: state.timeSeries,
          title: 'Enquiries Over Time',
          subtitle:
              '${formatAnalyticsDateRange(state.filters.dateRange)} • ${TimeBucket.fromDateRange(state.filters.dateRange).label} view',
        ),
      ],
    );
  }
}

class AnalyticsBreakdownTab extends StatelessWidget {
  const AnalyticsBreakdownTab({super.key, required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return _AnalyticsTabBody(
      onRetry: onRetry,
      sections: (state) {
        final status = StatusStackedBarChart(
          data: state.statusBreakdown,
          title: 'Status Breakdown',
        );
        final eventTypes = EventTypePieChart(data: state.eventTypeBreakdown, title: 'Event Types');
        final sources = SourceBarChart(data: state.sourceBreakdown, title: 'Sources');
        return [
          _Responsive(narrow: [status, eventTypes], wide: _pair(status, eventTypes)),
          sources,
          const _PipelineSlot(builder: _demandSections),
        ];
      },
    );
  }
}

class AnalyticsTablesTab extends StatelessWidget {
  const AnalyticsTablesTab({super.key, required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return _AnalyticsTabBody(
      onRetry: onRetry,
      sections: (state) {
        final topEvents = TopListTable(title: 'Top Event Types', data: state.topEventTypes);
        final topSources = TopListTable(title: 'Top Sources', data: state.topSources);
        return [
          RecentEnquiriesTable(data: state.recentEnquiries, title: 'Recent Enquiries'),
          _Responsive(narrow: [topEvents, topSources], wide: _pair(topEvents, topSources)),
        ];
      },
    );
  }
}

Widget _pair(Widget a, Widget b) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(child: a),
      const SizedBox(width: _gap),
      Expanded(child: b),
    ],
  );
}

/// Stacks [narrow] below the tablet breakpoint, otherwise shows [wide].
class _Responsive extends StatelessWidget {
  const _Responsive({required this.narrow, required this.wide});

  final List<Widget> narrow;
  final Widget wide;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= AppTokens.breakpointTablet) return wide;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < narrow.length; i++) ...[
              if (i > 0) const SizedBox(height: _gap),
              narrow[i],
            ],
          ],
        );
      },
    );
  }
}

// ── Pipeline-backed tabs ─────────────────────────────────────────────────────

class AnalyticsPipelineTab extends StatelessWidget {
  const AnalyticsPipelineTab({super.key});

  @override
  Widget build(BuildContext context) {
    return PipelineTabBody(
      sections: (r) => [
        FunnelSection(report: r),
        _Responsive(
          narrow: [
            LostReasonsSection(report: r),
            SpeedToLeadSection(report: r),
          ],
          wide: _pair(LostReasonsSection(report: r), SpeedToLeadSection(report: r)),
        ),
      ],
    );
  }
}

class AnalyticsTeamTab extends StatelessWidget {
  const AnalyticsTeamTab({super.key});

  @override
  Widget build(BuildContext context) {
    return PipelineTabBody(
      sections: (r) => [
        TeamSection(report: r),
        FollowUpSection(report: r),
        const ReengagementAnalyticsCard(),
      ],
    );
  }
}

class AnalyticsMoneyTab extends StatelessWidget {
  const AnalyticsMoneyTab({super.key});

  @override
  Widget build(BuildContext context) {
    return PipelineTabBody(
      sections: (r) => [
        ForecastSection(report: r),
        MoneyByMonthSection(report: r),
        OverdueSection(report: r),
      ],
    );
  }
}

List<Widget> _demandSections(PipelineReport r) => [
  SourcePerformanceSection(report: r),
  AreaBreakdownSection(report: r),
  _Responsive(
    narrow: [
      LeadTimeSection(report: r),
      UpcomingDemandSection(report: r),
    ],
    wide: _pair(LeadTimeSection(report: r), UpcomingDemandSection(report: r)),
  ),
];

/// Embeds pipeline-report sections inside a tab driven by the main controller.
class _PipelineSlot extends ConsumerWidget {
  const _PipelineSlot({required this.builder});

  final List<Widget> Function(PipelineReport report) builder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref
        .watch(pipelineReportProvider)
        .when(
          loading: () => const SizedBox.shrink(),
          error: (_, _) => const SizedBox.shrink(),
          data: (r) {
            final children = builder(r);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < children.length; i++) ...[
                  if (i > 0) const SizedBox(height: _gap),
                  children[i],
                ],
              ],
            );
          },
        );
  }
}
