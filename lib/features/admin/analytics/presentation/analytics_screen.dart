import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/export/csv_export.dart';
import '../../../../core/providers/role_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../shared/models/user_model.dart';
import '../../../../ui/primitives/primitives.dart';
import '../domain/analytics_models.dart';
import 'analytics_controller.dart';
import 'pipeline_controller.dart';
import 'widgets/analytics_filters_panel.dart';
import 'widgets/analytics_header.dart';
import 'widgets/analytics_kpi_grid.dart';
import 'widgets/analytics_state_views.dart';
import 'widgets/analytics_tab_bar_delegate.dart';
import 'widgets/analytics_tabs.dart';

/// Analytics screen with admin-only access.
///
/// Inside the shell ([embeddedInShell]) it is a transparent tab body under the
/// shell's glass top bar; pushed standalone it brings its own ambient ground.
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
    _tabController = TabController(length: 7, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  VoidCallback? get _onBack => widget.embeddedInShell ? null : () => Navigator.of(context).pop();

  @override
  Widget build(BuildContext context) {
    final roleAsync = ref.watch(roleProvider);

    final body = roleAsync.when(
      data: (role) {
        if (role != UserRole.admin) {
          return AnalyticsNoAccessView(onBack: _onBack);
        }
        return _buildAnalyticsContent(context);
      },
      loading: () => const AnalyticsLoadingView(message: 'Checking permissions...'),
      error: (error, stack) => AnalyticsNoAccessView(onBack: _onBack),
    );

    if (widget.embeddedInShell) {
      return body;
    }

    return AmbientBackdrop(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        resizeToAvoidBottomInset: true,
        body: body,
      ),
    );
  }

  Widget _buildAnalyticsContent(BuildContext context) {
    final tabBar = buildAnalyticsTabBar(context: context, controller: _tabController);

    return SafeArea(
      bottom: false,
      child: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AnalyticsHeader(
                  onExport: _exportAnalytics,
                  onRefresh: _refreshData,
                  onBack: _onBack,
                ),
                const AnalyticsKpiGrid(),
                AnalyticsFiltersPanel(onCustomDateRange: _showCustomDateRangePicker),
              ],
            ),
          ),
          SliverPersistentHeader(pinned: true, delegate: AnalyticsTabBarDelegate(tabBar)),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            AnalyticsOverviewTab(onRetry: _refreshData),
            const AnalyticsPipelineTab(),
            const AnalyticsTeamTab(),
            const AnalyticsMoneyTab(),
            AnalyticsTrendsTab(onRetry: _refreshData),
            AnalyticsBreakdownTab(onRetry: _refreshData),
            AnalyticsTablesTab(onRetry: _refreshData),
          ],
        ),
      ),
    );
  }

  void _refreshData() {
    ref.read(analyticsControllerProvider.notifier).refresh();
    // Pipeline tabs re-run when the controller reloads; invalidate in case the
    // filters did not change (pure refresh).
    ref.invalidate(pipelineReportProvider);
  }

  Future<void> _showCustomDateRangePicker(DateRange currentRange) async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(
        start: currentRange.start,
        end: lastIncludedDay(currentRange),
      ),
    );

    if (picked != null) {
      final end = picked.end;
      final customRange = DateRange(
        start: picked.start,
        end: DateTime(end.year, end.month, end.day).add(const Duration(days: 1)),
      );
      unawaited(ref.read(analyticsControllerProvider.notifier).updateCustomDateRange(customRange));
    }
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

          unawaited(
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
