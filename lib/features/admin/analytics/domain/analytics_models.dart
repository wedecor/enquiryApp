import 'package:freezed_annotation/freezed_annotation.dart';

part 'analytics_models.freezed.dart';
part 'analytics_models.g.dart';

/// Date range for analytics filtering
@freezed
class DateRange with _$DateRange {
  const factory DateRange({required DateTime start, required DateTime end}) = _DateRange;

  factory DateRange.fromJson(Map<String, dynamic> json) => _$DateRangeFromJson(json);
}

/// Predefined date range presets
enum DateRangePreset {
  today,
  last7Days,
  last30Days,
  last90Days,
  yearToDate,
  custom;

  String get label {
    switch (this) {
      case DateRangePreset.today:
        return 'Today';
      case DateRangePreset.last7Days:
        return 'Last 7 Days';
      case DateRangePreset.last30Days:
        return 'Last 30 Days';
      case DateRangePreset.last90Days:
        return 'Last 90 Days';
      case DateRangePreset.yearToDate:
        return 'Year to Date';
      case DateRangePreset.custom:
        return 'Custom Range';
    }
  }

  DateRange get dateRange {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    switch (this) {
      case DateRangePreset.today:
        return DateRange(start: today, end: today.add(const Duration(days: 1, microseconds: -1)));
      case DateRangePreset.last7Days:
        return DateRange(
          start: today.subtract(const Duration(days: 6)),
          end: today.add(const Duration(days: 1, microseconds: -1)),
        );
      case DateRangePreset.last30Days:
        return DateRange(
          start: today.subtract(const Duration(days: 29)),
          end: today.add(const Duration(days: 1, microseconds: -1)),
        );
      case DateRangePreset.last90Days:
        return DateRange(
          start: today.subtract(const Duration(days: 89)),
          end: today.add(const Duration(days: 1, microseconds: -1)),
        );
      case DateRangePreset.yearToDate:
        return DateRange(
          start: DateTime(now.year, 1, 1),
          end: today.add(const Duration(days: 1, microseconds: -1)),
        );
      case DateRangePreset.custom:
        // Default to last 30 days for custom
        return DateRangePreset.last30Days.dateRange;
    }
  }
}

/// KPI summary with delta comparison
@freezed
class KpiSummary with _$KpiSummary {
  const factory KpiSummary({
    required int totalEnquiries,
    required int activeEnquiries,
    required int wonEnquiries,
    required int lostEnquiries,
    required double conversionRate,
    required double estimatedRevenue,
    required KpiDeltas deltas,
  }) = _KpiSummary;

  factory KpiSummary.fromJson(Map<String, dynamic> json) => _$KpiSummaryFromJson(json);
}

/// Delta changes for KPIs compared to previous period
@freezed
class KpiDeltas with _$KpiDeltas {
  const factory KpiDeltas({
    required double totalEnquiriesChange,
    required double activeEnquiriesChange,
    required double wonEnquiriesChange,
    required double lostEnquiriesChange,
    required double conversionRateChange,
    required double estimatedRevenueChange,
  }) = _KpiDeltas;

  factory KpiDeltas.fromJson(Map<String, dynamic> json) => _$KpiDeltasFromJson(json);
}

/// Data point for time series charts
@freezed
class SeriesPoint with _$SeriesPoint {
  const factory SeriesPoint({required DateTime x, required int count}) = _SeriesPoint;

  factory SeriesPoint.fromJson(Map<String, dynamic> json) => _$SeriesPointFromJson(json);
}

/// Category count for breakdown charts
@freezed
class CategoryCount with _$CategoryCount {
  const factory CategoryCount({
    required String key,
    required int count,
    required double percentage,
  }) = _CategoryCount;

  factory CategoryCount.fromJson(Map<String, dynamic> json) => _$CategoryCountFromJson(json);
}

/// Recent enquiry summary for tables
@freezed
class RecentEnquiry with _$RecentEnquiry {
  const factory RecentEnquiry({
    required String id,
    required DateTime date,
    required String customerName,
    required String eventType,
    required String status,
    required String source,
    required String priority,
    double? totalCost,
  }) = _RecentEnquiry;

  factory RecentEnquiry.fromJson(Map<String, dynamic> json) => _$RecentEnquiryFromJson(json);
}

/// Analytics filters
@freezed
class AnalyticsFilters with _$AnalyticsFilters {
  const factory AnalyticsFilters({
    required DateRange dateRange,
    required DateRangePreset preset,
    String? eventType,
    String? status,
    String? priority,
    String? source,
  }) = _AnalyticsFilters;

  factory AnalyticsFilters.fromJson(Map<String, dynamic> json) => _$AnalyticsFiltersFromJson(json);

  factory AnalyticsFilters.initial() {
    final preset = DateRangePreset.last30Days;
    return AnalyticsFilters(dateRange: preset.dateRange, preset: preset);
  }
}

/// Complete analytics state
@freezed
class AnalyticsState with _$AnalyticsState {
  const factory AnalyticsState({
    required AnalyticsFilters filters,
    KpiSummary? kpiSummary,
    @Default([]) List<SeriesPoint> timeSeries,
    @Default([]) List<CategoryCount> statusBreakdown,
    @Default([]) List<CategoryCount> eventTypeBreakdown,
    @Default([]) List<CategoryCount> sourceBreakdown,
    @Default([]) List<RecentEnquiry> recentEnquiries,
    @Default([]) List<CategoryCount> topEventTypes,
    @Default([]) List<CategoryCount> topSources,
    @Default(false) bool isLoading,
    @Default(false) bool isRefreshing,
    String? error,
  }) = _AnalyticsState;

  factory AnalyticsState.fromJson(Map<String, dynamic> json) => _$AnalyticsStateFromJson(json);

  factory AnalyticsState.initial() {
    return AnalyticsState(filters: AnalyticsFilters.initial());
  }
}

/// Time bucket for grouping data
enum TimeBucket {
  day,
  week,
  month;

  String get label {
    switch (this) {
      case TimeBucket.day:
        return 'Daily';
      case TimeBucket.week:
        return 'Weekly';
      case TimeBucket.month:
        return 'Monthly';
    }
  }

  /// Determine appropriate bucket based on date range
  static TimeBucket fromDateRange(DateRange range) {
    final duration = range.end.difference(range.start);

    if (duration.inDays <= 90) {
      return TimeBucket.day;
    } else if (duration.inDays <= 365) {
      return TimeBucket.week;
    } else {
      return TimeBucket.month;
    }
  }
}

/// Status categories for KPI calculations
enum EnquiryStatusCategory {
  active,
  won,
  lost;

  static EnquiryStatusCategory? fromStatus(String status) {
    final normalizedStatus = status.toLowerCase().replaceAll(' ', '_');

    switch (normalizedStatus) {
      case 'new':
      case 'in_talks':
      case 'quotation_sent':
        return EnquiryStatusCategory.active;
      case 'confirmed':
      case 'completed':
        return EnquiryStatusCategory.won;
      case 'cancelled':
      case 'not_interested':
        return EnquiryStatusCategory.lost;
      default:
        return null; // Unknown status
    }
  }
}
