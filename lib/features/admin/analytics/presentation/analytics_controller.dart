import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../domain/analytics_models.dart';
import '../data/analytics_repository.dart';

part 'analytics_controller.g.dart';

/// Analytics controller managing state and data loading
@riverpod
class AnalyticsController extends _$AnalyticsController {
  @override
  Future<AnalyticsState> build() async {
    final initialState = AnalyticsState.initial();
    // Load initial data
    return await _loadAnalyticsData(initialState.filters);
  }

  /// Update filters and reload data
  Future<void> updateFilters(AnalyticsFilters filters) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _loadAnalyticsData(filters));
  }

  /// Update date range preset and reload data
  Future<void> updateDateRangePreset(DateRangePreset preset) async {
    final currentState = await future;
    final newFilters = currentState.filters.copyWith(
      preset: preset,
      dateRange: preset.dateRange,
    );
    await updateFilters(newFilters);
  }

  /// Update custom date range and reload data
  Future<void> updateCustomDateRange(DateRange dateRange) async {
    final currentState = await future;
    final newFilters = currentState.filters.copyWith(
      preset: DateRangePreset.custom,
      dateRange: dateRange,
    );
    await updateFilters(newFilters);
  }

  /// Update event type filter
  Future<void> updateEventTypeFilter(String? eventType) async {
    final currentState = await future;
    final newFilters = currentState.filters.copyWith(eventType: eventType);
    await updateFilters(newFilters);
  }

  /// Update status filter
  Future<void> updateStatusFilter(String? status) async {
    final currentState = await future;
    final newFilters = currentState.filters.copyWith(status: status);
    await updateFilters(newFilters);
  }

  /// Update priority filter
  Future<void> updatePriorityFilter(String? priority) async {
    final currentState = await future;
    final newFilters = currentState.filters.copyWith(priority: priority);
    await updateFilters(newFilters);
  }

  /// Update source filter
  Future<void> updateSourceFilter(String? source) async {
    final currentState = await future;
    final newFilters = currentState.filters.copyWith(source: source);
    await updateFilters(newFilters);
  }

  /// Refresh data with current filters
  Future<void> refresh() async {
    final currentState = await future;
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _loadAnalyticsData(currentState.filters));
  }

  /// Load all analytics data in parallel
  Future<AnalyticsState> _loadAnalyticsData(AnalyticsFilters filters) async {
    final repository = ref.read(analyticsRepositoryProvider);
    
    try {
      // Calculate previous period for deltas
      final currentRange = filters.dateRange;
      final duration = currentRange.end.difference(currentRange.start);
      final previousRange = DateRange(
        start: currentRange.start.subtract(duration),
        end: currentRange.start,
      );

      // Load all data in parallel for better performance
      final results = await Future.wait([
        // Current period data
        _loadCurrentPeriodData(repository, filters),
        // Previous period data for deltas
        _loadPreviousPeriodData(repository, filters, previousRange),
      ]);

      final currentData = results[0] as _CurrentPeriodData;
      final previousData = results[1] as _PreviousPeriodData;

      // Calculate KPI summary with deltas
      final kpiSummary = _calculateKpiSummary(
        currentData,
        previousData,
      );

      // Convert breakdowns to CategoryCount lists
      final statusBreakdown = _convertToCategories(currentData.statusCounts);
      final eventTypeBreakdown = _convertToCategories(currentData.eventTypeCounts);
      final sourceBreakdown = _convertToCategories(currentData.sourceCounts);

      // Get top lists (sorted by count, limited)
      final topEventTypes = statusBreakdown.take(10).toList();
      final topSources = sourceBreakdown.take(10).toList();

      return AnalyticsState(
        filters: filters,
        kpiSummary: kpiSummary,
        timeSeries: currentData.timeSeries,
        statusBreakdown: statusBreakdown,
        eventTypeBreakdown: eventTypeBreakdown,
        sourceBreakdown: sourceBreakdown,
        recentEnquiries: currentData.recentEnquiries,
        topEventTypes: topEventTypes,
        topSources: topSources,
        isLoading: false,
        isRefreshing: false,
      );
    } catch (error) {
      return AnalyticsState(
        filters: filters,
        isLoading: false,
        isRefreshing: false,
        error: error.toString(),
      );
    }
  }

  /// Load current period data
  Future<_CurrentPeriodData> _loadCurrentPeriodData(
    AnalyticsRepository repository,
    AnalyticsFilters filters,
  ) async {
    final bucket = TimeBucket.fromDateRange(filters.dateRange);
    
    final results = await Future.wait([
      repository.countEnquiries(dateRange: filters.dateRange, filters: filters),
      repository.countByStatus(dateRange: filters.dateRange, filters: filters),
      repository.countByEventType(dateRange: filters.dateRange, filters: filters),
      repository.countBySource(dateRange: filters.dateRange, filters: filters),
      repository.sumRevenue(dateRange: filters.dateRange, filters: filters),
      repository.getTimeSeries(
        dateRange: filters.dateRange,
        bucket: bucket,
        filters: filters,
      ),
      repository.getRecentEnquiries(
        dateRange: filters.dateRange,
        filters: filters,
        limit: 20,
      ),
    ]);

    return _CurrentPeriodData(
      totalCount: results[0] as int,
      statusCounts: results[1] as Map<String, int>,
      eventTypeCounts: results[2] as Map<String, int>,
      sourceCounts: results[3] as Map<String, int>,
      totalRevenue: results[4] as double,
      timeSeries: results[5] as List<SeriesPoint>,
      recentEnquiries: results[6] as List<RecentEnquiry>,
    );
  }

  /// Load previous period data for delta calculations
  Future<_PreviousPeriodData> _loadPreviousPeriodData(
    AnalyticsRepository repository,
    AnalyticsFilters filters,
    DateRange previousRange,
  ) async {
    final previousFilters = filters.copyWith(dateRange: previousRange);
    
    final results = await Future.wait([
      repository.countEnquiries(dateRange: previousRange, filters: previousFilters),
      repository.countByStatus(dateRange: previousRange, filters: previousFilters),
      repository.sumRevenue(dateRange: previousRange, filters: previousFilters),
    ]);

    return _PreviousPeriodData(
      totalCount: results[0] as int,
      statusCounts: results[1] as Map<String, int>,
      totalRevenue: results[2] as double,
    );
  }

  /// Calculate KPI summary with deltas
  KpiSummary _calculateKpiSummary(
    _CurrentPeriodData current,
    _PreviousPeriodData previous,
  ) {
    // Calculate current period KPIs
    final activeCount = _countByStatusCategory(current.statusCounts, EnquiryStatusCategory.active);
    final wonCount = _countByStatusCategory(current.statusCounts, EnquiryStatusCategory.won);
    final lostCount = _countByStatusCategory(current.statusCounts, EnquiryStatusCategory.lost);
    
    final conversionRate = (wonCount + lostCount) > 0 
        ? (wonCount / (wonCount + lostCount)) * 100 
        : 0.0;

    // Calculate previous period KPIs for deltas
    final prevActiveCount = _countByStatusCategory(previous.statusCounts, EnquiryStatusCategory.active);
    final prevWonCount = _countByStatusCategory(previous.statusCounts, EnquiryStatusCategory.won);
    final prevLostCount = _countByStatusCategory(previous.statusCounts, EnquiryStatusCategory.lost);
    
    final prevConversionRate = (prevWonCount + prevLostCount) > 0 
        ? (prevWonCount / (prevWonCount + prevLostCount)) * 100 
        : 0.0;

    // Calculate percentage changes
    final deltas = KpiDeltas(
      totalEnquiriesChange: _calculatePercentageChange(previous.totalCount, current.totalCount),
      activeEnquiriesChange: _calculatePercentageChange(prevActiveCount, activeCount),
      wonEnquiriesChange: _calculatePercentageChange(prevWonCount, wonCount),
      lostEnquiriesChange: _calculatePercentageChange(prevLostCount, lostCount),
      conversionRateChange: _calculatePercentageChange(prevConversionRate, conversionRate),
      estimatedRevenueChange: _calculatePercentageChange(previous.totalRevenue, current.totalRevenue),
    );

    return KpiSummary(
      totalEnquiries: current.totalCount,
      activeEnquiries: activeCount,
      wonEnquiries: wonCount,
      lostEnquiries: lostCount,
      conversionRate: conversionRate,
      estimatedRevenue: current.totalRevenue,
      deltas: deltas,
    );
  }

  /// Count enquiries by status category
  int _countByStatusCategory(Map<String, int> statusCounts, EnquiryStatusCategory category) {
    int count = 0;
    for (final entry in statusCounts.entries) {
      if (EnquiryStatusCategory.fromStatus(entry.key) == category) {
        count += entry.value;
      }
    }
    return count;
  }

  /// Calculate percentage change
  double _calculatePercentageChange(num previous, num current) {
    if (previous == 0) {
      return current > 0 ? 100.0 : 0.0;
    }
    return ((current - previous) / previous) * 100;
  }

  /// Convert count map to CategoryCount list with percentages
  List<CategoryCount> _convertToCategories(Map<String, int> counts) {
    final total = counts.values.fold<int>(0, (sum, count) => sum + count);
    
    if (total == 0) return [];
    
    return counts.entries
        .map((entry) => CategoryCount(
              key: entry.key,
              count: entry.value,
              percentage: (entry.value / total) * 100,
            ))
        .toList()
      ..sort((a, b) => b.count.compareTo(a.count)); // Sort by count descending
  }
}

/// Helper class for current period data
class _CurrentPeriodData {
  final int totalCount;
  final Map<String, int> statusCounts;
  final Map<String, int> eventTypeCounts;
  final Map<String, int> sourceCounts;
  final double totalRevenue;
  final List<SeriesPoint> timeSeries;
  final List<RecentEnquiry> recentEnquiries;

  const _CurrentPeriodData({
    required this.totalCount,
    required this.statusCounts,
    required this.eventTypeCounts,
    required this.sourceCounts,
    required this.totalRevenue,
    required this.timeSeries,
    required this.recentEnquiries,
  });
}

/// Helper class for previous period data
class _PreviousPeriodData {
  final int totalCount;
  final Map<String, int> statusCounts;
  final double totalRevenue;

  const _PreviousPeriodData({
    required this.totalCount,
    required this.statusCounts,
    required this.totalRevenue,
  });
}

/// Provider for filter dropdown values
@riverpod
Future<List<String>> eventTypesForFilter(EventTypesForFilterRef ref) async {
  final repository = ref.watch(analyticsRepositoryProvider);
  return repository.getEventTypes();
}

@riverpod
Future<List<String>> statusesForFilter(StatusesForFilterRef ref) async {
  final repository = ref.watch(analyticsRepositoryProvider);
  return repository.getStatuses();
}

@riverpod
Future<List<String>> sourcesForFilter(SourcesForFilterRef ref) async {
  final repository = ref.watch(analyticsRepositoryProvider);
  return repository.getSources();
}

@riverpod
Future<List<String>> prioritiesForFilter(PrioritiesForFilterRef ref) async {
  final repository = ref.watch(analyticsRepositoryProvider);
  return repository.getPriorities();
}