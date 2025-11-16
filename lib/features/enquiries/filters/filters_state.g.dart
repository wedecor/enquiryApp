// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'filters_state.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$EnquiryFiltersImpl _$$EnquiryFiltersImplFromJson(
  Map<String, dynamic> json,
) => _$EnquiryFiltersImpl(
  statuses: (json['statuses'] as List<dynamic>?)?.map((e) => e as String).toList() ?? const [],
  eventTypes: (json['eventTypes'] as List<dynamic>?)?.map((e) => e as String).toList() ?? const [],
  assigneeId: json['assigneeId'] as String?,
  dateRange: json['dateRange'] == null
      ? null
      : FilterDateRange.fromJson(json['dateRange'] as Map<String, dynamic>),
  searchQuery: json['searchQuery'] as String?,
  sortBy: $enumDecodeNullable(_$EnquirySortByEnumMap, json['sortBy']) ?? EnquirySortBy.createdAt,
  sortOrder: $enumDecodeNullable(_$SortOrderEnumMap, json['sortOrder']) ?? SortOrder.descending,
);

Map<String, dynamic> _$$EnquiryFiltersImplToJson(_$EnquiryFiltersImpl instance) =>
    <String, dynamic>{
      'statuses': instance.statuses,
      'eventTypes': instance.eventTypes,
      'assigneeId': instance.assigneeId,
      'dateRange': instance.dateRange,
      'searchQuery': instance.searchQuery,
      'sortBy': _$EnquirySortByEnumMap[instance.sortBy]!,
      'sortOrder': _$SortOrderEnumMap[instance.sortOrder]!,
    };

const _$EnquirySortByEnumMap = {
  EnquirySortBy.createdAt: 'createdAt',
  EnquirySortBy.updatedAt: 'updatedAt',
  EnquirySortBy.eventDate: 'eventDate',
  EnquirySortBy.customerName: 'customerName',
  EnquirySortBy.eventType: 'eventType',
  EnquirySortBy.status: 'status',
  EnquirySortBy.priority: 'priority',
};

const _$SortOrderEnumMap = {SortOrder.ascending: 'ascending', SortOrder.descending: 'descending'};

_$FilterDateRangeImpl _$$FilterDateRangeImplFromJson(Map<String, dynamic> json) =>
    _$FilterDateRangeImpl(
      start: DateTime.parse(json['start'] as String),
      end: DateTime.parse(json['end'] as String),
    );

Map<String, dynamic> _$$FilterDateRangeImplToJson(_$FilterDateRangeImpl instance) =>
    <String, dynamic>{
      'start': instance.start.toIso8601String(),
      'end': instance.end.toIso8601String(),
    };

_$SavedViewImpl _$$SavedViewImplFromJson(Map<String, dynamic> json) => _$SavedViewImpl(
  id: json['id'] as String,
  name: json['name'] as String,
  filters: EnquiryFilters.fromJson(json['filters'] as Map<String, dynamic>),
  isDefault: json['isDefault'] as bool? ?? false,
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: DateTime.parse(json['updatedAt'] as String),
);

Map<String, dynamic> _$$SavedViewImplToJson(_$SavedViewImpl instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'filters': instance.filters,
  'isDefault': instance.isDefault,
  'createdAt': instance.createdAt.toIso8601String(),
  'updatedAt': instance.updatedAt.toIso8601String(),
};
