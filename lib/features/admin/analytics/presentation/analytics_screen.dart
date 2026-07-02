import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/export/csv_export.dart';
import '../../../../core/providers/role_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../shared/models/user_model.dart';
import '../domain/analytics_models.dart';
import 'analytics_controller.dart';
import 'widgets/analytics_filters_panel.dart';
import 'widgets/analytics_header.dart';
import 'widgets/analytics_kpi_grid.dart';
import 'widgets/analytics_tab_bar_delegate.dart';
import 'widgets/breakdown_charts.dart';
import 'widgets/line_trend_chart.dart';
import 'widgets/top_list_table.dart';

/// Analytics screen with admin-only access.
class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key, this.embeddedInShell = false});

  final bool embeddedInShell;

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final roleAsync = ref.watch(roleProvider);

    final body = roleAsync.when(
      data: (role) {
        if (role != UserRole.admin) {
          return _buildNoAccessContent();
        }
        return _buildAnalyticsContent(context);
      },
      loading: () => const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: AppTokens.space4),
            Text('Checking permissions...'),
          ],
        ),
      ),
      error: (error, stack) => _buildNoAccessContent(),
    );

    if (widget.embeddedInShell) {
      return body;
    }

    return Scaffold(resizeToAvoidBottomInset: true, body: body);
  }

  Widget _buildAnalyticsContent(BuildContext context) {
    final tabBar = buildAnalyticsTabBar(
      context: context,
      controller: _tabController,
    );

    return SafeArea(
      child: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AnalyticsHeader(
                  onExport: _exportAnalytics,
                  onRefresh: _refreshData,
                ),
                const AnalyticsKpiGrid(),
                AnalyticsFiltersPanel(
                  onCustomDateRange: _showCustomDateRangePicker,
                ),
              ],
            ),
          ),
          SliverPersistentHeader(
            pinned: true,
            delegate: AnalyticsTabBarDelegate(tabBar),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildOverviewTab(),
            _buildTrendsTab(),
            _buildBreakdownTab(),
            _buildTablesTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewTab() {
    return Consumer(
      builder: (context, ref, child) {
        final analyticsAsync = ref.watch(analyticsControllerProvider);

        return analyticsAsync.when(
          data: (state) => ListView(
            padding: AppSpacing.space4,
            children: [
              LineTrendChart(
                data: state.timeSeries,
                title: 'Enquiries Trend',
                subtitle: _formatDateRange(state.filters.dateRange),
              ),
            ],
          ),
          loading: () => _buildLoadingState(),
          error: (error, stack) => _buildErrorState(error.toString()),
        );
      },
    );
  }

  Widget _buildTrendsTab() {
    return Consumer(
      builder: (context, ref, child) {
        final analyticsAsync = ref.watch(analyticsControllerProvider);

        return analyticsAsync.when(
          data: (state) => ListView(
            padding: AppSpacing.space4,
            children: [
              LineTrendChart(
                data: state.timeSeries,
                title: 'Enquiries Over Time',
                subtitle:
                    '${_formatDateRange(state.filters.dateRange)} • ${TimeBucket.fromDateRange(state.filters.dateRange).label} view',
              ),
            ],
          ),
          loading: () => _buildLoadingState(),
          error: (error, stack) => _buildErrorState(error.toString()),
        );
      },
    );
  }

  Widget _buildBreakdownTab() {
    return Consumer(
      builder: (context, ref, child) {
        final analyticsAsync = ref.watch(analyticsControllerProvider);

        return analyticsAsync.when(
          data: (state) => ListView(
            padding: AppSpacing.space4,
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth < AppTokens.breakpointTablet) {
                    return Column(
                      children: [
                        StatusStackedBarChart(
                          data: state.statusBreakdown,
                          title: 'Status Breakdown',
                        ),
                        const SizedBox(height: AppTokens.space4),
                        EventTypePieChart(
                          data: state.eventTypeBreakdown,
                          title: 'Event Types',
                        ),
                        const SizedBox(height: AppTokens.space4),
                        SourceBarChart(
                          data: state.sourceBreakdown,
                          title: 'Sources',
                        ),
                      ],
                    );
                  }
                  return Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: StatusStackedBarChart(
                              data: state.statusBreakdown,
                              title: 'Status Breakdown',
                            ),
                          ),
                          const SizedBox(width: AppTokens.space4),
                          Expanded(
                            child: EventTypePieChart(
                              data: state.eventTypeBreakdown,
                              title: 'Event Types',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppTokens.space4),
                      SourceBarChart(
                        data: state.sourceBreakdown,
                        title: 'Sources',
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
          loading: () => _buildLoadingState(),
          error: (error, stack) => _buildErrorState(error.toString()),
        );
      },
    );
  }

  Widget _buildTablesTab() {
    return Consumer(
      builder: (context, ref, child) {
        final analyticsAsync = ref.watch(analyticsControllerProvider);

        return analyticsAsync.when(
          data: (state) => ListView(
            padding: AppSpacing.space4,
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  return Column(
                    children: [
                      RecentEnquiriesTable(
                        data: state.recentEnquiries,
                        title: 'Recent Enquiries',
                      ),
                      const SizedBox(height: AppTokens.space4),
                      if (constraints.maxWidth < AppTokens.breakpointTablet)
                        Column(
                          children: [
                            TopListTable(
                              title: 'Top Event Types',
                              data: state.topEventTypes,
                            ),
                            const SizedBox(height: AppTokens.space4),
                            TopListTable(
                              title: 'Top Sources',
                              data: state.topSources,
                            ),
                          ],
                        )
                      else
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: TopListTable(
                                title: 'Top Event Types',
                                data: state.topEventTypes,
                              ),
                            ),
                            const SizedBox(width: AppTokens.space4),
                            Expanded(
                              child: TopListTable(
                                title: 'Top Sources',
                                data: state.topSources,
                              ),
                            ),
                          ],
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
          loading: () => _buildLoadingState(),
          error: (error, stack) => _buildErrorState(error.toString()),
        );
      },
    );
  }

  Widget _buildNoAccessContent() {
    final cs = Theme.of(context).colorScheme;

    return Center(
      child: Card.filled(
        margin: AppSpacing.space8,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.large,
          side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.7)),
        ),
        child: Padding(
          padding: AppSpacing.space8,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.security_rounded,
                size: 64,
                color: AppColorScheme.snackWarning,
              ),
              const SizedBox(height: AppTokens.space6),
              Text(
                'Access Restricted',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppTokens.space4),
              Text(
                'System Analytics is only available to administrators.',
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppTokens.space2),
              Text(
                'Please contact your administrator if you need access to these features.',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
              if (!widget.embeddedInShell) ...[
                const SizedBox(height: AppTokens.space6),
                OutlinedButton.icon(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.arrow_back_rounded),
                  label: const Text('Go Back'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Padding(
        padding: AppSpacing.space8,
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: AppTokens.space4),
            Text('Loading analytics data...'),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    final cs = Theme.of(context).colorScheme;

    return Center(
      child: Card.filled(
        margin: AppSpacing.space8,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.large,
          side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.7)),
        ),
        child: Padding(
          padding: AppSpacing.space8,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline_rounded, size: 64, color: cs.error),
              const SizedBox(height: AppTokens.space6),
              Text(
                'Error Loading Data',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppTokens.space4),
              Text(
                error,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppTokens.space6),
              OutlinedButton.icon(
                onPressed: _refreshData,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Try Again'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _refreshData() {
    ref.read(analyticsControllerProvider.notifier).refresh();
  }

  Future<void> _showCustomDateRangePicker(DateRange currentRange) async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(
        start: currentRange.start,
        end: currentRange.end,
      ),
    );

    if (picked != null) {
      final customRange = DateRange(start: picked.start, end: picked.end);
      ref
          .read(analyticsControllerProvider.notifier)
          .updateCustomDateRange(customRange);
    }
  }

  String _formatDateRange(DateRange range) {
    final fmt = DateFormat('d MMM yyyy');
    return '${fmt.format(range.start)} – ${fmt.format(range.end)}';
  }

  Future<void> _exportAnalytics() async {
    final analyticsAsync = ref.read(analyticsControllerProvider);

    analyticsAsync.when(
      data: (state) async {
        try {
          if (state.kpiSummary == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('No analytics data to export'),
                backgroundColor: AppColorScheme.snackWarning,
              ),
            );
            return;
          }

          showDialog<void>(
            context: context,
            barrierDismissible: false,
            builder: (context) => const AlertDialog(
              content: Row(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(width: AppTokens.space4),
                  Text('Exporting analytics...'),
                ],
              ),
            ),
          );

          await CsvExport.exportAnalyticsSummary(
            kpiSummary: state.kpiSummary!,
            statusBreakdown: state.statusBreakdown,
            eventTypeBreakdown: state.eventTypeBreakdown,
            sourceBreakdown: state.sourceBreakdown,
            dateRange: state.filters.dateRange,
          );

          if (mounted) {
            Navigator.of(context).pop();
            CsvExport.showExportSuccess(context, 'analytics_summary.csv');
          }
        } catch (e) {
          if (mounted) {
            Navigator.of(context).pop();
            CsvExport.showExportError(context, e.toString());
          }
        }
      },
      loading: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Analytics data is still loading'),
            backgroundColor: AppColorScheme.snackWarning,
          ),
        );
      },
      error: (error, stack) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${error.toString()}'),
            backgroundColor: AppColorScheme.snackError,
          ),
        );
      },
    );
  }
}
