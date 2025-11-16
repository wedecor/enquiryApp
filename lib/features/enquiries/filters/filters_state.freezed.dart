// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'filters_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

EnquiryFilters _$EnquiryFiltersFromJson(Map<String, dynamic> json) {
  return _EnquiryFilters.fromJson(json);
}

/// @nodoc
mixin _$EnquiryFilters {
  List<String> get statuses => throw _privateConstructorUsedError;
  List<String> get eventTypes => throw _privateConstructorUsedError;
  String? get assigneeId => throw _privateConstructorUsedError;
  FilterDateRange? get dateRange => throw _privateConstructorUsedError;
  String? get searchQuery => throw _privateConstructorUsedError;
  EnquirySortBy get sortBy => throw _privateConstructorUsedError;
  SortOrder get sortOrder => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $EnquiryFiltersCopyWith<EnquiryFilters> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $EnquiryFiltersCopyWith<$Res> {
  factory $EnquiryFiltersCopyWith(EnquiryFilters value, $Res Function(EnquiryFilters) then) =
      _$EnquiryFiltersCopyWithImpl<$Res, EnquiryFilters>;
  @useResult
  $Res call({
    List<String> statuses,
    List<String> eventTypes,
    String? assigneeId,
    FilterDateRange? dateRange,
    String? searchQuery,
    EnquirySortBy sortBy,
    SortOrder sortOrder,
  });

  $FilterDateRangeCopyWith<$Res>? get dateRange;
}

/// @nodoc
class _$EnquiryFiltersCopyWithImpl<$Res, $Val extends EnquiryFilters>
    implements $EnquiryFiltersCopyWith<$Res> {
  _$EnquiryFiltersCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? statuses = null,
    Object? eventTypes = null,
    Object? assigneeId = freezed,
    Object? dateRange = freezed,
    Object? searchQuery = freezed,
    Object? sortBy = null,
    Object? sortOrder = null,
  }) {
    return _then(
      _value.copyWith(
            statuses: null == statuses
                ? _value.statuses
                : statuses // ignore: cast_nullable_to_non_nullable
                      as List<String>,
            eventTypes: null == eventTypes
                ? _value.eventTypes
                : eventTypes // ignore: cast_nullable_to_non_nullable
                      as List<String>,
            assigneeId: freezed == assigneeId
                ? _value.assigneeId
                : assigneeId // ignore: cast_nullable_to_non_nullable
                      as String?,
            dateRange: freezed == dateRange
                ? _value.dateRange
                : dateRange // ignore: cast_nullable_to_non_nullable
                      as FilterDateRange?,
            searchQuery: freezed == searchQuery
                ? _value.searchQuery
                : searchQuery // ignore: cast_nullable_to_non_nullable
                      as String?,
            sortBy: null == sortBy
                ? _value.sortBy
                : sortBy // ignore: cast_nullable_to_non_nullable
                      as EnquirySortBy,
            sortOrder: null == sortOrder
                ? _value.sortOrder
                : sortOrder // ignore: cast_nullable_to_non_nullable
                      as SortOrder,
          )
          as $Val,
    );
  }

  @override
  @pragma('vm:prefer-inline')
  $FilterDateRangeCopyWith<$Res>? get dateRange {
    if (_value.dateRange == null) {
      return null;
    }

    return $FilterDateRangeCopyWith<$Res>(_value.dateRange!, (value) {
      return _then(_value.copyWith(dateRange: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$EnquiryFiltersImplCopyWith<$Res> implements $EnquiryFiltersCopyWith<$Res> {
  factory _$$EnquiryFiltersImplCopyWith(
    _$EnquiryFiltersImpl value,
    $Res Function(_$EnquiryFiltersImpl) then,
  ) = __$$EnquiryFiltersImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    List<String> statuses,
    List<String> eventTypes,
    String? assigneeId,
    FilterDateRange? dateRange,
    String? searchQuery,
    EnquirySortBy sortBy,
    SortOrder sortOrder,
  });

  @override
  $FilterDateRangeCopyWith<$Res>? get dateRange;
}

/// @nodoc
class __$$EnquiryFiltersImplCopyWithImpl<$Res>
    extends _$EnquiryFiltersCopyWithImpl<$Res, _$EnquiryFiltersImpl>
    implements _$$EnquiryFiltersImplCopyWith<$Res> {
  __$$EnquiryFiltersImplCopyWithImpl(
    _$EnquiryFiltersImpl _value,
    $Res Function(_$EnquiryFiltersImpl) _then,
  ) : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? statuses = null,
    Object? eventTypes = null,
    Object? assigneeId = freezed,
    Object? dateRange = freezed,
    Object? searchQuery = freezed,
    Object? sortBy = null,
    Object? sortOrder = null,
  }) {
    return _then(
      _$EnquiryFiltersImpl(
        statuses: null == statuses
            ? _value._statuses
            : statuses // ignore: cast_nullable_to_non_nullable
                  as List<String>,
        eventTypes: null == eventTypes
            ? _value._eventTypes
            : eventTypes // ignore: cast_nullable_to_non_nullable
                  as List<String>,
        assigneeId: freezed == assigneeId
            ? _value.assigneeId
            : assigneeId // ignore: cast_nullable_to_non_nullable
                  as String?,
        dateRange: freezed == dateRange
            ? _value.dateRange
            : dateRange // ignore: cast_nullable_to_non_nullable
                  as FilterDateRange?,
        searchQuery: freezed == searchQuery
            ? _value.searchQuery
            : searchQuery // ignore: cast_nullable_to_non_nullable
                  as String?,
        sortBy: null == sortBy
            ? _value.sortBy
            : sortBy // ignore: cast_nullable_to_non_nullable
                  as EnquirySortBy,
        sortOrder: null == sortOrder
            ? _value.sortOrder
            : sortOrder // ignore: cast_nullable_to_non_nullable
                  as SortOrder,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$EnquiryFiltersImpl implements _EnquiryFilters {
  const _$EnquiryFiltersImpl({
    final List<String> statuses = const [],
    final List<String> eventTypes = const [],
    this.assigneeId,
    this.dateRange,
    this.searchQuery,
    this.sortBy = EnquirySortBy.createdAt,
    this.sortOrder = SortOrder.descending,
  }) : _statuses = statuses,
       _eventTypes = eventTypes;

  factory _$EnquiryFiltersImpl.fromJson(Map<String, dynamic> json) =>
      _$$EnquiryFiltersImplFromJson(json);

  final List<String> _statuses;
  @override
  @JsonKey()
  List<String> get statuses {
    if (_statuses is EqualUnmodifiableListView) return _statuses;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_statuses);
  }

  final List<String> _eventTypes;
  @override
  @JsonKey()
  List<String> get eventTypes {
    if (_eventTypes is EqualUnmodifiableListView) return _eventTypes;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_eventTypes);
  }

  @override
  final String? assigneeId;
  @override
  final FilterDateRange? dateRange;
  @override
  final String? searchQuery;
  @override
  @JsonKey()
  final EnquirySortBy sortBy;
  @override
  @JsonKey()
  final SortOrder sortOrder;

  @override
  String toString() {
    return 'EnquiryFilters(statuses: $statuses, eventTypes: $eventTypes, assigneeId: $assigneeId, dateRange: $dateRange, searchQuery: $searchQuery, sortBy: $sortBy, sortOrder: $sortOrder)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$EnquiryFiltersImpl &&
            const DeepCollectionEquality().equals(other._statuses, _statuses) &&
            const DeepCollectionEquality().equals(other._eventTypes, _eventTypes) &&
            (identical(other.assigneeId, assigneeId) || other.assigneeId == assigneeId) &&
            (identical(other.dateRange, dateRange) || other.dateRange == dateRange) &&
            (identical(other.searchQuery, searchQuery) || other.searchQuery == searchQuery) &&
            (identical(other.sortBy, sortBy) || other.sortBy == sortBy) &&
            (identical(other.sortOrder, sortOrder) || other.sortOrder == sortOrder));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    const DeepCollectionEquality().hash(_statuses),
    const DeepCollectionEquality().hash(_eventTypes),
    assigneeId,
    dateRange,
    searchQuery,
    sortBy,
    sortOrder,
  );

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$EnquiryFiltersImplCopyWith<_$EnquiryFiltersImpl> get copyWith =>
      __$$EnquiryFiltersImplCopyWithImpl<_$EnquiryFiltersImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$EnquiryFiltersImplToJson(this);
  }
}

abstract class _EnquiryFilters implements EnquiryFilters {
  const factory _EnquiryFilters({
    final List<String> statuses,
    final List<String> eventTypes,
    final String? assigneeId,
    final FilterDateRange? dateRange,
    final String? searchQuery,
    final EnquirySortBy sortBy,
    final SortOrder sortOrder,
  }) = _$EnquiryFiltersImpl;

  factory _EnquiryFilters.fromJson(Map<String, dynamic> json) = _$EnquiryFiltersImpl.fromJson;

  @override
  List<String> get statuses;
  @override
  List<String> get eventTypes;
  @override
  String? get assigneeId;
  @override
  FilterDateRange? get dateRange;
  @override
  String? get searchQuery;
  @override
  EnquirySortBy get sortBy;
  @override
  SortOrder get sortOrder;
  @override
  @JsonKey(ignore: true)
  _$$EnquiryFiltersImplCopyWith<_$EnquiryFiltersImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

FilterDateRange _$FilterDateRangeFromJson(Map<String, dynamic> json) {
  return _FilterDateRange.fromJson(json);
}

/// @nodoc
mixin _$FilterDateRange {
  DateTime get start => throw _privateConstructorUsedError;
  DateTime get end => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $FilterDateRangeCopyWith<FilterDateRange> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $FilterDateRangeCopyWith<$Res> {
  factory $FilterDateRangeCopyWith(FilterDateRange value, $Res Function(FilterDateRange) then) =
      _$FilterDateRangeCopyWithImpl<$Res, FilterDateRange>;
  @useResult
  $Res call({DateTime start, DateTime end});
}

/// @nodoc
class _$FilterDateRangeCopyWithImpl<$Res, $Val extends FilterDateRange>
    implements $FilterDateRangeCopyWith<$Res> {
  _$FilterDateRangeCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? start = null, Object? end = null}) {
    return _then(
      _value.copyWith(
            start: null == start
                ? _value.start
                : start // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            end: null == end
                ? _value.end
                : end // ignore: cast_nullable_to_non_nullable
                      as DateTime,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$FilterDateRangeImplCopyWith<$Res> implements $FilterDateRangeCopyWith<$Res> {
  factory _$$FilterDateRangeImplCopyWith(
    _$FilterDateRangeImpl value,
    $Res Function(_$FilterDateRangeImpl) then,
  ) = __$$FilterDateRangeImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({DateTime start, DateTime end});
}

/// @nodoc
class __$$FilterDateRangeImplCopyWithImpl<$Res>
    extends _$FilterDateRangeCopyWithImpl<$Res, _$FilterDateRangeImpl>
    implements _$$FilterDateRangeImplCopyWith<$Res> {
  __$$FilterDateRangeImplCopyWithImpl(
    _$FilterDateRangeImpl _value,
    $Res Function(_$FilterDateRangeImpl) _then,
  ) : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? start = null, Object? end = null}) {
    return _then(
      _$FilterDateRangeImpl(
        start: null == start
            ? _value.start
            : start // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        end: null == end
            ? _value.end
            : end // ignore: cast_nullable_to_non_nullable
                  as DateTime,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$FilterDateRangeImpl implements _FilterDateRange {
  const _$FilterDateRangeImpl({required this.start, required this.end});

  factory _$FilterDateRangeImpl.fromJson(Map<String, dynamic> json) =>
      _$$FilterDateRangeImplFromJson(json);

  @override
  final DateTime start;
  @override
  final DateTime end;

  @override
  String toString() {
    return 'FilterDateRange(start: $start, end: $end)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$FilterDateRangeImpl &&
            (identical(other.start, start) || other.start == start) &&
            (identical(other.end, end) || other.end == end));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, start, end);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$FilterDateRangeImplCopyWith<_$FilterDateRangeImpl> get copyWith =>
      __$$FilterDateRangeImplCopyWithImpl<_$FilterDateRangeImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$FilterDateRangeImplToJson(this);
  }
}

abstract class _FilterDateRange implements FilterDateRange {
  const factory _FilterDateRange({required final DateTime start, required final DateTime end}) =
      _$FilterDateRangeImpl;

  factory _FilterDateRange.fromJson(Map<String, dynamic> json) = _$FilterDateRangeImpl.fromJson;

  @override
  DateTime get start;
  @override
  DateTime get end;
  @override
  @JsonKey(ignore: true)
  _$$FilterDateRangeImplCopyWith<_$FilterDateRangeImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

SavedView _$SavedViewFromJson(Map<String, dynamic> json) {
  return _SavedView.fromJson(json);
}

/// @nodoc
mixin _$SavedView {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  EnquiryFilters get filters => throw _privateConstructorUsedError;
  bool get isDefault => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;
  DateTime get updatedAt => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $SavedViewCopyWith<SavedView> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SavedViewCopyWith<$Res> {
  factory $SavedViewCopyWith(SavedView value, $Res Function(SavedView) then) =
      _$SavedViewCopyWithImpl<$Res, SavedView>;
  @useResult
  $Res call({
    String id,
    String name,
    EnquiryFilters filters,
    bool isDefault,
    DateTime createdAt,
    DateTime updatedAt,
  });

  $EnquiryFiltersCopyWith<$Res> get filters;
}

/// @nodoc
class _$SavedViewCopyWithImpl<$Res, $Val extends SavedView> implements $SavedViewCopyWith<$Res> {
  _$SavedViewCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? filters = null,
    Object? isDefault = null,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
            filters: null == filters
                ? _value.filters
                : filters // ignore: cast_nullable_to_non_nullable
                      as EnquiryFilters,
            isDefault: null == isDefault
                ? _value.isDefault
                : isDefault // ignore: cast_nullable_to_non_nullable
                      as bool,
            createdAt: null == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            updatedAt: null == updatedAt
                ? _value.updatedAt
                : updatedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
          )
          as $Val,
    );
  }

  @override
  @pragma('vm:prefer-inline')
  $EnquiryFiltersCopyWith<$Res> get filters {
    return $EnquiryFiltersCopyWith<$Res>(_value.filters, (value) {
      return _then(_value.copyWith(filters: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$SavedViewImplCopyWith<$Res> implements $SavedViewCopyWith<$Res> {
  factory _$$SavedViewImplCopyWith(_$SavedViewImpl value, $Res Function(_$SavedViewImpl) then) =
      __$$SavedViewImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String name,
    EnquiryFilters filters,
    bool isDefault,
    DateTime createdAt,
    DateTime updatedAt,
  });

  @override
  $EnquiryFiltersCopyWith<$Res> get filters;
}

/// @nodoc
class __$$SavedViewImplCopyWithImpl<$Res> extends _$SavedViewCopyWithImpl<$Res, _$SavedViewImpl>
    implements _$$SavedViewImplCopyWith<$Res> {
  __$$SavedViewImplCopyWithImpl(_$SavedViewImpl _value, $Res Function(_$SavedViewImpl) _then)
    : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? filters = null,
    Object? isDefault = null,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(
      _$SavedViewImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        filters: null == filters
            ? _value.filters
            : filters // ignore: cast_nullable_to_non_nullable
                  as EnquiryFilters,
        isDefault: null == isDefault
            ? _value.isDefault
            : isDefault // ignore: cast_nullable_to_non_nullable
                  as bool,
        createdAt: null == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        updatedAt: null == updatedAt
            ? _value.updatedAt
            : updatedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$SavedViewImpl implements _SavedView {
  const _$SavedViewImpl({
    required this.id,
    required this.name,
    required this.filters,
    this.isDefault = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory _$SavedViewImpl.fromJson(Map<String, dynamic> json) => _$$SavedViewImplFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  final EnquiryFilters filters;
  @override
  @JsonKey()
  final bool isDefault;
  @override
  final DateTime createdAt;
  @override
  final DateTime updatedAt;

  @override
  String toString() {
    return 'SavedView(id: $id, name: $name, filters: $filters, isDefault: $isDefault, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SavedViewImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.filters, filters) || other.filters == filters) &&
            (identical(other.isDefault, isDefault) || other.isDefault == isDefault) &&
            (identical(other.createdAt, createdAt) || other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, id, name, filters, isDefault, createdAt, updatedAt);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$SavedViewImplCopyWith<_$SavedViewImpl> get copyWith =>
      __$$SavedViewImplCopyWithImpl<_$SavedViewImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$SavedViewImplToJson(this);
  }
}

abstract class _SavedView implements SavedView {
  const factory _SavedView({
    required final String id,
    required final String name,
    required final EnquiryFilters filters,
    final bool isDefault,
    required final DateTime createdAt,
    required final DateTime updatedAt,
  }) = _$SavedViewImpl;

  factory _SavedView.fromJson(Map<String, dynamic> json) = _$SavedViewImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  EnquiryFilters get filters;
  @override
  bool get isDefault;
  @override
  DateTime get createdAt;
  @override
  DateTime get updatedAt;
  @override
  @JsonKey(ignore: true)
  _$$SavedViewImplCopyWith<_$SavedViewImpl> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$SavedViewsState {
  List<SavedView> get views => throw _privateConstructorUsedError;
  bool get isLoading => throw _privateConstructorUsedError;
  String? get error => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $SavedViewsStateCopyWith<SavedViewsState> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SavedViewsStateCopyWith<$Res> {
  factory $SavedViewsStateCopyWith(SavedViewsState value, $Res Function(SavedViewsState) then) =
      _$SavedViewsStateCopyWithImpl<$Res, SavedViewsState>;
  @useResult
  $Res call({List<SavedView> views, bool isLoading, String? error});
}

/// @nodoc
class _$SavedViewsStateCopyWithImpl<$Res, $Val extends SavedViewsState>
    implements $SavedViewsStateCopyWith<$Res> {
  _$SavedViewsStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? views = null, Object? isLoading = null, Object? error = freezed}) {
    return _then(
      _value.copyWith(
            views: null == views
                ? _value.views
                : views // ignore: cast_nullable_to_non_nullable
                      as List<SavedView>,
            isLoading: null == isLoading
                ? _value.isLoading
                : isLoading // ignore: cast_nullable_to_non_nullable
                      as bool,
            error: freezed == error
                ? _value.error
                : error // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$SavedViewsStateImplCopyWith<$Res> implements $SavedViewsStateCopyWith<$Res> {
  factory _$$SavedViewsStateImplCopyWith(
    _$SavedViewsStateImpl value,
    $Res Function(_$SavedViewsStateImpl) then,
  ) = __$$SavedViewsStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({List<SavedView> views, bool isLoading, String? error});
}

/// @nodoc
class __$$SavedViewsStateImplCopyWithImpl<$Res>
    extends _$SavedViewsStateCopyWithImpl<$Res, _$SavedViewsStateImpl>
    implements _$$SavedViewsStateImplCopyWith<$Res> {
  __$$SavedViewsStateImplCopyWithImpl(
    _$SavedViewsStateImpl _value,
    $Res Function(_$SavedViewsStateImpl) _then,
  ) : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? views = null, Object? isLoading = null, Object? error = freezed}) {
    return _then(
      _$SavedViewsStateImpl(
        views: null == views
            ? _value._views
            : views // ignore: cast_nullable_to_non_nullable
                  as List<SavedView>,
        isLoading: null == isLoading
            ? _value.isLoading
            : isLoading // ignore: cast_nullable_to_non_nullable
                  as bool,
        error: freezed == error
            ? _value.error
            : error // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc

class _$SavedViewsStateImpl implements _SavedViewsState {
  const _$SavedViewsStateImpl({
    final List<SavedView> views = const [],
    this.isLoading = false,
    this.error,
  }) : _views = views;

  final List<SavedView> _views;
  @override
  @JsonKey()
  List<SavedView> get views {
    if (_views is EqualUnmodifiableListView) return _views;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_views);
  }

  @override
  @JsonKey()
  final bool isLoading;
  @override
  final String? error;

  @override
  String toString() {
    return 'SavedViewsState(views: $views, isLoading: $isLoading, error: $error)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SavedViewsStateImpl &&
            const DeepCollectionEquality().equals(other._views, _views) &&
            (identical(other.isLoading, isLoading) || other.isLoading == isLoading) &&
            (identical(other.error, error) || other.error == error));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, const DeepCollectionEquality().hash(_views), isLoading, error);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$SavedViewsStateImplCopyWith<_$SavedViewsStateImpl> get copyWith =>
      __$$SavedViewsStateImplCopyWithImpl<_$SavedViewsStateImpl>(this, _$identity);
}

abstract class _SavedViewsState implements SavedViewsState {
  const factory _SavedViewsState({
    final List<SavedView> views,
    final bool isLoading,
    final String? error,
  }) = _$SavedViewsStateImpl;

  @override
  List<SavedView> get views;
  @override
  bool get isLoading;
  @override
  String? get error;
  @override
  @JsonKey(ignore: true)
  _$$SavedViewsStateImplCopyWith<_$SavedViewsStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
