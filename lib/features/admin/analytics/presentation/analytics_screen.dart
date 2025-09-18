import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/analytics_models.dart';
import 'analytics_controller.dart';
import 'widgets/kpi_card.dart';
import 'widgets/line_trend_chart.dart';
import 'widgets/breakdown_charts.dart';
import 'widgets/top_list_table.dart';
import '../../../../core/providers/role_provider.dart';
import '../../../../core/export/csv_export.dart';

/// Analytics screen with admin-only access
class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});

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
    final isAdmin = ref.watch(isAdminProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('System Analytics'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: isAdmin ? TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Overview', icon: Icon(Icons.dashboard, size: 20)),
            Tab(text: 'Trends', icon: Icon(Icons.trending_up, size: 20)),
            Tab(text: 'Breakdown', icon: Icon(Icons.pie_chart, size: 20)),
            Tab(text: 'Tables', icon: Icon(Icons.table_chart, size: 20)),
          ],
        ) : null,
      ),
      body: isAdmin ? _buildAdminContent() : _buildNoAccessContent(),
    );
  }

  Widget _buildAdminContent() {
    return Column(
      children: [
        // Filters bar
        _buildFiltersBar(),
        
        // Tab content
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildOverviewTab(),
              _buildTrendsTab(),
              _buildBreakdownTab(),
              _buildTablesTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFiltersBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Date range presets
          Row(
            children: [
          Expanded(
                child: _buildDateRangeSelector(),
              ),
              const SizedBox(width: 16),
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: _exportAnalytics,
                    icon: const Icon(Icons.download, size: 18),
                    label: const Text('Export'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: _refreshData,
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('Refresh'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Filter dropdowns
          Row(
            children: [
              Expanded(child: _buildEventTypeFilter()),
              const SizedBox(width: 12),
              Expanded(child: _buildStatusFilter()),
              const SizedBox(width: 12),
              Expanded(child: _buildPriorityFilter()),
              const SizedBox(width: 12),
              Expanded(child: _buildSourceFilter()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDateRangeSelector() {
    return Consumer(
      builder: (context, ref, child) {
        final analyticsAsync = ref.watch(analyticsControllerProvider);
        
        return analyticsAsync.when(
          data: (state) {
            return Row(
              children: [
                Text(
                  'Date Range:',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<DateRangePreset>(
                      initialValue: state.filters.preset,
                      decoration: const InputDecoration(
                        isDense: true,
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    items: DateRangePreset.values.map((preset) {
                      return DropdownMenuItem(
                        value: preset,
                        child: Text(preset.label),
                      );
                    }).toList(),
                    onChanged: (preset) {
                      if (preset != null) {
                        if (preset == DateRangePreset.custom) {
                          _showCustomDateRangePicker(state.filters.dateRange);
                        } else {
                          ref.read(analyticsControllerProvider.notifier)
                              .updateDateRangePreset(preset);
                        }
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  _formatDateRange(state.filters.dateRange),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Text('Error: $error'),
        );
      },
    );
  }

  Widget _buildEventTypeFilter() {
    return Consumer(
      builder: (context, ref, child) {
        final eventTypesAsync = ref.watch(eventTypesForFilterProvider);
        final analyticsAsync = ref.watch(analyticsControllerProvider);
        
        return eventTypesAsync.when(
          data: (eventTypes) {
            final currentEventType = analyticsAsync.value?.filters.eventType;
            
            return DropdownButtonFormField<String?>(
              initialValue: currentEventType,
              decoration: const InputDecoration(
                labelText: 'Event Type',
                isDense: true,
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('All Event Types'),
                ),
                ...eventTypes.map((eventType) => DropdownMenuItem<String?>(
                  value: eventType,
                  child: Text(eventType),
                )),
              ],
              onChanged: (eventType) {
                ref.read(analyticsControllerProvider.notifier)
                    .updateEventTypeFilter(eventType);
              },
            );
          },
          loading: () => DropdownButtonFormField<String>(
            items: const [],
            onChanged: null,
            decoration: const InputDecoration(
              labelText: 'Event Type',
              isDense: true,
              border: OutlineInputBorder(),
            ),
          ),
          error: (error, stack) => DropdownButtonFormField<String>(
            items: const [],
            onChanged: null,
            decoration: const InputDecoration(
              labelText: 'Event Type (Error)',
              isDense: true,
              border: OutlineInputBorder(),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusFilter() {
    return Consumer(
      builder: (context, ref, child) {
        final statusesAsync = ref.watch(statusesForFilterProvider);
        final analyticsAsync = ref.watch(analyticsControllerProvider);
        
        return statusesAsync.when(
          data: (statuses) {
            final currentStatus = analyticsAsync.value?.filters.status;
            
            return DropdownButtonFormField<String?>(
              initialValue: currentStatus,
              decoration: const InputDecoration(
                labelText: 'Status',
                isDense: true,
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('All Statuses'),
                ),
                ...statuses.map((status) => DropdownMenuItem<String?>(
                  value: status,
                  child: Text(status),
                )),
              ],
              onChanged: (status) {
                ref.read(analyticsControllerProvider.notifier)
                    .updateStatusFilter(status);
              },
            );
          },
          loading: () => DropdownButtonFormField<String>(
            items: const [],
            onChanged: null,
            decoration: const InputDecoration(
              labelText: 'Status',
              isDense: true,
              border: OutlineInputBorder(),
            ),
          ),
          error: (error, stack) => DropdownButtonFormField<String>(
            items: const [],
            onChanged: null,
            decoration: const InputDecoration(
              labelText: 'Status (Error)',
              isDense: true,
              border: OutlineInputBorder(),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPriorityFilter() {
    return Consumer(
      builder: (context, ref, child) {
        final prioritiesAsync = ref.watch(prioritiesForFilterProvider);
        final analyticsAsync = ref.watch(analyticsControllerProvider);
        
        return prioritiesAsync.when(
          data: (priorities) {
            final currentPriority = analyticsAsync.value?.filters.priority;
            
            return DropdownButtonFormField<String?>(
              initialValue: currentPriority,
              decoration: const InputDecoration(
                labelText: 'Priority',
                isDense: true,
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('All Priorities'),
                ),
                ...priorities.map((priority) => DropdownMenuItem<String?>(
                  value: priority,
                  child: Text(priority),
                )),
              ],
              onChanged: (priority) {
                ref.read(analyticsControllerProvider.notifier)
                    .updatePriorityFilter(priority);
              },
            );
          },
          loading: () => DropdownButtonFormField<String>(
            items: const [],
            onChanged: null,
            decoration: const InputDecoration(
              labelText: 'Priority',
              isDense: true,
              border: OutlineInputBorder(),
            ),
          ),
          error: (error, stack) => DropdownButtonFormField<String>(
            items: const [],
            onChanged: null,
            decoration: const InputDecoration(
              labelText: 'Priority (Error)',
              isDense: true,
              border: OutlineInputBorder(),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSourceFilter() {
    return Consumer(
      builder: (context, ref, child) {
        final sourcesAsync = ref.watch(sourcesForFilterProvider);
        final analyticsAsync = ref.watch(analyticsControllerProvider);
        
        return sourcesAsync.when(
          data: (sources) {
            final currentSource = analyticsAsync.value?.filters.source;
            
            return DropdownButtonFormField<String?>(
              initialValue: currentSource,
              decoration: const InputDecoration(
                labelText: 'Source',
                isDense: true,
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('All Sources'),
                ),
                ...sources.map((source) => DropdownMenuItem<String?>(
                  value: source,
                  child: Text(source),
                )),
              ],
              onChanged: (source) {
                ref.read(analyticsControllerProvider.notifier)
                    .updateSourceFilter(source);
              },
            );
          },
          loading: () => DropdownButtonFormField<String>(
            items: const [],
            onChanged: null,
            decoration: const InputDecoration(
              labelText: 'Source',
              isDense: true,
              border: OutlineInputBorder(),
            ),
          ),
          error: (error, stack) => DropdownButtonFormField<String>(
            items: const [],
            onChanged: null,
            decoration: const InputDecoration(
              labelText: 'Source (Error)',
              isDense: true,
              border: OutlineInputBorder(),
            ),
          ),
        );
      },
    );
  }

  Widget _buildOverviewTab() {
    return Consumer(
      builder: (context, ref, child) {
        final analyticsAsync = ref.watch(analyticsControllerProvider);
        
        return analyticsAsync.when(
          data: (state) => SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // KPI Cards
                _buildKpiGrid(state),
                const SizedBox(height: 24),
                
                // Quick trend chart
                LineTrendChart(
                  data: state.timeSeries,
                  title: 'Enquiries Trend',
                  subtitle: _formatDateRange(state.filters.dateRange),
                ),
              ],
            ),
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
          data: (state) => SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: LineTrendChart(
              data: state.timeSeries,
              title: 'Enquiries Over Time',
              subtitle: '${_formatDateRange(state.filters.dateRange)} • ${TimeBucket.fromDateRange(state.filters.dateRange).label} view',
            ),
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
          data: (state) => SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
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
              const SizedBox(width: 16),
              Expanded(
                      child: EventTypePieChart(
                        data: state.eventTypeBreakdown,
                        title: 'Event Types',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SourceBarChart(
                  data: state.sourceBreakdown,
                  title: 'Sources',
                ),
              ],
            ),
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
          data: (state) => SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                RecentEnquiriesTable(
                  data: state.recentEnquiries,
                  title: 'Recent Enquiries',
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TopListTable(
                        title: 'Top Event Types',
                        data: state.topEventTypes,
                ),
              ),
              const SizedBox(width: 16),
                    Expanded(
                      child: TopListTable(
                        title: 'Top Sources',
                        data: state.topSources,
                      ),
                ),
            ],
          ),
        ],
      ),
          ),
          loading: () => _buildLoadingState(),
          error: (error, stack) => _buildErrorState(error.toString()),
        );
      },
    );
  }

  Widget _buildKpiGrid(AnalyticsState state) {
    final kpi = state.kpiSummary;
    if (kpi == null) return const SizedBox.shrink();
    
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        TotalEnquiriesCard(
          count: kpi.totalEnquiries,
          deltaPercentage: kpi.deltas.totalEnquiriesChange,
          isLoading: state.isLoading,
        ),
        ActiveEnquiriesCard(
          count: kpi.activeEnquiries,
          deltaPercentage: kpi.deltas.activeEnquiriesChange,
          isLoading: state.isLoading,
        ),
        WonEnquiriesCard(
          count: kpi.wonEnquiries,
          deltaPercentage: kpi.deltas.wonEnquiriesChange,
          isLoading: state.isLoading,
        ),
        LostEnquiriesCard(
          count: kpi.lostEnquiries,
          deltaPercentage: kpi.deltas.lostEnquiriesChange,
          isLoading: state.isLoading,
        ),
        ConversionRateCard(
          rate: kpi.conversionRate,
          deltaPercentage: kpi.deltas.conversionRateChange,
          isLoading: state.isLoading,
        ),
        EstimatedRevenueCard(
          revenue: kpi.estimatedRevenue,
          deltaPercentage: kpi.deltas.estimatedRevenueChange,
          isLoading: state.isLoading,
        ),
      ],
    );
  }

  Widget _buildNoAccessContent() {
    return Center(
      child: Card(
        margin: const EdgeInsets.all(32),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.security,
                size: 64,
                color: Colors.orange.shade400,
              ),
              const SizedBox(height: 24),
              Text(
                'Access Restricted',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'System Analytics is only available to administrators.',
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Please contact your administrator if you need access to these features.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Go Back'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Loading analytics data...'),
        ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Card(
        margin: const EdgeInsets.all(32),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red.shade400,
              ),
              const SizedBox(height: 24),
              Text(
                'Error Loading Data',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                error,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _refreshData,
                icon: const Icon(Icons.refresh),
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
      final customRange = DateRange(
        start: picked.start,
        end: picked.end,
      );
      ref.read(analyticsControllerProvider.notifier)
          .updateCustomDateRange(customRange);
    }
  }

  String _formatDateRange(DateRange range) {
    final start = '${range.start.day}/${range.start.month}/${range.start.year}';
    final end = '${range.end.day}/${range.end.month}/${range.end.year}';
    return '$start - $end';
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
                backgroundColor: Colors.orange,
              ),
            );
            return;
          }

          // Show loading
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => const AlertDialog(
              content: Row(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(width: 16),
                  Text('Exporting analytics...'),
                ],
              ),
            ),
          );

          // Export analytics summary
          await CsvExport.exportAnalyticsSummary(
            kpiSummary: state.kpiSummary!,
            statusBreakdown: state.statusBreakdown,
            eventTypeBreakdown: state.eventTypeBreakdown,
            sourceBreakdown: state.sourceBreakdown,
            dateRange: state.filters.dateRange,
          );

          // Close loading dialog
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
            backgroundColor: Colors.orange,
          ),
        );
      },
      error: (error, stack) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${error.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      },
    );
  }
}