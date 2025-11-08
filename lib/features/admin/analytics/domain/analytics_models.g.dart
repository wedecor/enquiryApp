// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'analytics_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$DateRangeImpl _$$DateRangeImplFromJson(Map<String, dynamic> json) =>
    _$DateRangeImpl(
      start: DateTime.parse(json['start'] as String),
      end: DateTime.parse(json['end'] as String),
    );

Map<String, dynamic> _$$DateRangeImplToJson(_$DateRangeImpl instance) =>
    <String, dynamic>{
      'start': instance.start.toIso8601String(),
      'end': instance.end.toIso8601String(),
    };

_$KpiSummaryImpl _$$KpiSummaryImplFromJson(Map<String, dynamic> json) =>
    _$KpiSummaryImpl(
      totalEnquiries: (json['totalEnquiries'] as num).toInt(),
      activeEnquiries: (json['activeEnquiries'] as num).toInt(),
      wonEnquiries: (json['wonEnquiries'] as num).toInt(),
      lostEnquiries: (json['lostEnquiries'] as num).toInt(),
      conversionRate: (json['conversionRate'] as num).toDouble(),
      estimatedRevenue: (json['estimatedRevenue'] as num).toDouble(),
      deltas: KpiDeltas.fromJson(json['deltas'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$$KpiSummaryImplToJson(_$KpiSummaryImpl instance) =>
    <String, dynamic>{
      'totalEnquiries': instance.totalEnquiries,
      'activeEnquiries': instance.activeEnquiries,
      'wonEnquiries': instance.wonEnquiries,
      'lostEnquiries': instance.lostEnquiries,
      'conversionRate': instance.conversionRate,
      'estimatedRevenue': instance.estimatedRevenue,
      'deltas': instance.deltas,
    };

_$KpiDeltasImpl _$$KpiDeltasImplFromJson(Map<String, dynamic> json) =>
    _$KpiDeltasImpl(
      totalEnquiriesChange: (json['totalEnquiriesChange'] as num).toDouble(),
      activeEnquiriesChange: (json['activeEnquiriesChange'] as num).toDouble(),
      wonEnquiriesChange: (json['wonEnquiriesChange'] as num).toDouble(),
      lostEnquiriesChange: (json['lostEnquiriesChange'] as num).toDouble(),
      conversionRateChange: (json['conversionRateChange'] as num).toDouble(),
      estimatedRevenueChange: (json['estimatedRevenueChange'] as num)
          .toDouble(),
    );

Map<String, dynamic> _$$KpiDeltasImplToJson(_$KpiDeltasImpl instance) =>
    <String, dynamic>{
      'totalEnquiriesChange': instance.totalEnquiriesChange,
      'activeEnquiriesChange': instance.activeEnquiriesChange,
      'wonEnquiriesChange': instance.wonEnquiriesChange,
      'lostEnquiriesChange': instance.lostEnquiriesChange,
      'conversionRateChange': instance.conversionRateChange,
      'estimatedRevenueChange': instance.estimatedRevenueChange,
    };

_$SeriesPointImpl _$$SeriesPointImplFromJson(Map<String, dynamic> json) =>
    _$SeriesPointImpl(
      x: DateTime.parse(json['x'] as String),
      count: (json['count'] as num).toInt(),
    );

Map<String, dynamic> _$$SeriesPointImplToJson(_$SeriesPointImpl instance) =>
    <String, dynamic>{
      'x': instance.x.toIso8601String(),
      'count': instance.count,
    };

_$CategoryCountImpl _$$CategoryCountImplFromJson(Map<String, dynamic> json) =>
    _$CategoryCountImpl(
      key: json['key'] as String,
      count: (json['count'] as num).toInt(),
      percentage: (json['percentage'] as num).toDouble(),
    );

Map<String, dynamic> _$$CategoryCountImplToJson(_$CategoryCountImpl instance) =>
    <String, dynamic>{
      'key': instance.key,
      'count': instance.count,
      'percentage': instance.percentage,
    };

_$RecentEnquiryImpl _$$RecentEnquiryImplFromJson(Map<String, dynamic> json) =>
    _$RecentEnquiryImpl(
      id: json['id'] as String,
      date: DateTime.parse(json['date'] as String),
      customerName: json['customerName'] as String,
      eventType: json['eventType'] as String,
      status: json['status'] as String,
      source: json['source'] as String,
      priority: json['priority'] as String,
      totalCost: (json['totalCost'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$$RecentEnquiryImplToJson(_$RecentEnquiryImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'date': instance.date.toIso8601String(),
      'customerName': instance.customerName,
      'eventType': instance.eventType,
      'status': instance.status,
      'source': instance.source,
      'priority': instance.priority,
      'totalCost': instance.totalCost,
    };

_$AnalyticsFiltersImpl _$$AnalyticsFiltersImplFromJson(
  Map<String, dynamic> json,
) => _$AnalyticsFiltersImpl(
  dateRange: DateRange.fromJson(json['dateRange'] as Map<String, dynamic>),
  preset: $enumDecode(_$DateRangePresetEnumMap, json['preset']),
  eventType: json['eventType'] as String?,
  status: json['status'] as String?,
  priority: json['priority'] as String?,
  source: json['source'] as String?,
);

Map<String, dynamic> _$$AnalyticsFiltersImplToJson(
  _$AnalyticsFiltersImpl instance,
) => <String, dynamic>{
  'dateRange': instance.dateRange,
  'preset': _$DateRangePresetEnumMap[instance.preset]!,
  'eventType': instance.eventType,
  'status': instance.status,
  'priority': instance.priority,
  'source': instance.source,
};

const _$DateRangePresetEnumMap = {
  DateRangePreset.today: 'today',
  DateRangePreset.last7Days: 'last7Days',
  DateRangePreset.last30Days: 'last30Days',
  DateRangePreset.last90Days: 'last90Days',
  DateRangePreset.yearToDate: 'yearToDate',
  DateRangePreset.custom: 'custom',
};

_$AnalyticsStateImpl _$$AnalyticsStateImplFromJson(Map<String, dynamic> json) =>
    _$AnalyticsStateImpl(
      filters: AnalyticsFilters.fromJson(
        json['filters'] as Map<String, dynamic>,
      ),
      kpiSummary: json['kpiSummary'] == null
          ? null
          : KpiSummary.fromJson(json['kpiSummary'] as Map<String, dynamic>),
      timeSeries:
          (json['timeSeries'] as List<dynamic>?)
              ?.map((e) => SeriesPoint.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      statusBreakdown:
          (json['statusBreakdown'] as List<dynamic>?)
              ?.map((e) => CategoryCount.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      eventTypeBreakdown:
          (json['eventTypeBreakdown'] as List<dynamic>?)
              ?.map((e) => CategoryCount.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      sourceBreakdown:
          (json['sourceBreakdown'] as List<dynamic>?)
              ?.map((e) => CategoryCount.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      recentEnquiries:
          (json['recentEnquiries'] as List<dynamic>?)
              ?.map((e) => RecentEnquiry.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      topEventTypes:
          (json['topEventTypes'] as List<dynamic>?)
              ?.map((e) => CategoryCount.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      topSources:
          (json['topSources'] as List<dynamic>?)
              ?.map((e) => CategoryCount.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      isLoading: json['isLoading'] as bool? ?? false,
      isRefreshing: json['isRefreshing'] as bool? ?? false,
      error: json['error'] as String?,
    );

Map<String, dynamic> _$$AnalyticsStateImplToJson(
  _$AnalyticsStateImpl instance,
) => <String, dynamic>{
  'filters': instance.filters,
  'kpiSummary': instance.kpiSummary,
  'timeSeries': instance.timeSeries,
  'statusBreakdown': instance.statusBreakdown,
  'eventTypeBreakdown': instance.eventTypeBreakdown,
  'sourceBreakdown': instance.sourceBreakdown,
  'recentEnquiries': instance.recentEnquiries,
  'topEventTypes': instance.topEventTypes,
  'topSources': instance.topSources,
  'isLoading': instance.isLoading,
  'isRefreshing': instance.isRefreshing,
  'error': instance.error,
};
