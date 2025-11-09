// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'analytics_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

DateRange _$DateRangeFromJson(Map<String, dynamic> json) {
  return _DateRange.fromJson(json);
}

/// @nodoc
mixin _$DateRange {
  DateTime get start => throw _privateConstructorUsedError;
  DateTime get end => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $DateRangeCopyWith<DateRange> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DateRangeCopyWith<$Res> {
  factory $DateRangeCopyWith(DateRange value, $Res Function(DateRange) then) =
      _$DateRangeCopyWithImpl<$Res, DateRange>;
  @useResult
  $Res call({DateTime start, DateTime end});
}

/// @nodoc
class _$DateRangeCopyWithImpl<$Res, $Val extends DateRange>
    implements $DateRangeCopyWith<$Res> {
  _$DateRangeCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? start = null,
    Object? end = null,
  }) {
    return _then(_value.copyWith(
      start: null == start
          ? _value.start
          : start // ignore: cast_nullable_to_non_nullable
              as DateTime,
      end: null == end
          ? _value.end
          : end // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$DateRangeImplCopyWith<$Res>
    implements $DateRangeCopyWith<$Res> {
  factory _$$DateRangeImplCopyWith(
          _$DateRangeImpl value, $Res Function(_$DateRangeImpl) then) =
      __$$DateRangeImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({DateTime start, DateTime end});
}

/// @nodoc
class __$$DateRangeImplCopyWithImpl<$Res>
    extends _$DateRangeCopyWithImpl<$Res, _$DateRangeImpl>
    implements _$$DateRangeImplCopyWith<$Res> {
  __$$DateRangeImplCopyWithImpl(
      _$DateRangeImpl _value, $Res Function(_$DateRangeImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? start = null,
    Object? end = null,
  }) {
    return _then(_$DateRangeImpl(
      start: null == start
          ? _value.start
          : start // ignore: cast_nullable_to_non_nullable
              as DateTime,
      end: null == end
          ? _value.end
          : end // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$DateRangeImpl implements _DateRange {
  const _$DateRangeImpl({required this.start, required this.end});

  factory _$DateRangeImpl.fromJson(Map<String, dynamic> json) =>
      _$$DateRangeImplFromJson(json);

  @override
  final DateTime start;
  @override
  final DateTime end;

  @override
  String toString() {
    return 'DateRange(start: $start, end: $end)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DateRangeImpl &&
            (identical(other.start, start) || other.start == start) &&
            (identical(other.end, end) || other.end == end));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, start, end);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$DateRangeImplCopyWith<_$DateRangeImpl> get copyWith =>
      __$$DateRangeImplCopyWithImpl<_$DateRangeImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$DateRangeImplToJson(
      this,
    );
  }
}

abstract class _DateRange implements DateRange {
  const factory _DateRange(
      {required final DateTime start,
      required final DateTime end}) = _$DateRangeImpl;

  factory _DateRange.fromJson(Map<String, dynamic> json) =
      _$DateRangeImpl.fromJson;

  @override
  DateTime get start;
  @override
  DateTime get end;
  @override
  @JsonKey(ignore: true)
  _$$DateRangeImplCopyWith<_$DateRangeImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

KpiSummary _$KpiSummaryFromJson(Map<String, dynamic> json) {
  return _KpiSummary.fromJson(json);
}

/// @nodoc
mixin _$KpiSummary {
  int get totalEnquiries => throw _privateConstructorUsedError;
  int get activeEnquiries => throw _privateConstructorUsedError;
  int get wonEnquiries => throw _privateConstructorUsedError;
  int get lostEnquiries => throw _privateConstructorUsedError;
  double get conversionRate => throw _privateConstructorUsedError;
  double get estimatedRevenue => throw _privateConstructorUsedError;
  KpiDeltas get deltas => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $KpiSummaryCopyWith<KpiSummary> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $KpiSummaryCopyWith<$Res> {
  factory $KpiSummaryCopyWith(
          KpiSummary value, $Res Function(KpiSummary) then) =
      _$KpiSummaryCopyWithImpl<$Res, KpiSummary>;
  @useResult
  $Res call(
      {int totalEnquiries,
      int activeEnquiries,
      int wonEnquiries,
      int lostEnquiries,
      double conversionRate,
      double estimatedRevenue,
      KpiDeltas deltas});

  $KpiDeltasCopyWith<$Res> get deltas;
}

/// @nodoc
class _$KpiSummaryCopyWithImpl<$Res, $Val extends KpiSummary>
    implements $KpiSummaryCopyWith<$Res> {
  _$KpiSummaryCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? totalEnquiries = null,
    Object? activeEnquiries = null,
    Object? wonEnquiries = null,
    Object? lostEnquiries = null,
    Object? conversionRate = null,
    Object? estimatedRevenue = null,
    Object? deltas = null,
  }) {
    return _then(_value.copyWith(
      totalEnquiries: null == totalEnquiries
          ? _value.totalEnquiries
          : totalEnquiries // ignore: cast_nullable_to_non_nullable
              as int,
      activeEnquiries: null == activeEnquiries
          ? _value.activeEnquiries
          : activeEnquiries // ignore: cast_nullable_to_non_nullable
              as int,
      wonEnquiries: null == wonEnquiries
          ? _value.wonEnquiries
          : wonEnquiries // ignore: cast_nullable_to_non_nullable
              as int,
      lostEnquiries: null == lostEnquiries
          ? _value.lostEnquiries
          : lostEnquiries // ignore: cast_nullable_to_non_nullable
              as int,
      conversionRate: null == conversionRate
          ? _value.conversionRate
          : conversionRate // ignore: cast_nullable_to_non_nullable
              as double,
      estimatedRevenue: null == estimatedRevenue
          ? _value.estimatedRevenue
          : estimatedRevenue // ignore: cast_nullable_to_non_nullable
              as double,
      deltas: null == deltas
          ? _value.deltas
          : deltas // ignore: cast_nullable_to_non_nullable
              as KpiDeltas,
    ) as $Val);
  }

  @override
  @pragma('vm:prefer-inline')
  $KpiDeltasCopyWith<$Res> get deltas {
    return $KpiDeltasCopyWith<$Res>(_value.deltas, (value) {
      return _then(_value.copyWith(deltas: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$KpiSummaryImplCopyWith<$Res>
    implements $KpiSummaryCopyWith<$Res> {
  factory _$$KpiSummaryImplCopyWith(
          _$KpiSummaryImpl value, $Res Function(_$KpiSummaryImpl) then) =
      __$$KpiSummaryImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int totalEnquiries,
      int activeEnquiries,
      int wonEnquiries,
      int lostEnquiries,
      double conversionRate,
      double estimatedRevenue,
      KpiDeltas deltas});

  @override
  $KpiDeltasCopyWith<$Res> get deltas;
}

/// @nodoc
class __$$KpiSummaryImplCopyWithImpl<$Res>
    extends _$KpiSummaryCopyWithImpl<$Res, _$KpiSummaryImpl>
    implements _$$KpiSummaryImplCopyWith<$Res> {
  __$$KpiSummaryImplCopyWithImpl(
      _$KpiSummaryImpl _value, $Res Function(_$KpiSummaryImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? totalEnquiries = null,
    Object? activeEnquiries = null,
    Object? wonEnquiries = null,
    Object? lostEnquiries = null,
    Object? conversionRate = null,
    Object? estimatedRevenue = null,
    Object? deltas = null,
  }) {
    return _then(_$KpiSummaryImpl(
      totalEnquiries: null == totalEnquiries
          ? _value.totalEnquiries
          : totalEnquiries // ignore: cast_nullable_to_non_nullable
              as int,
      activeEnquiries: null == activeEnquiries
          ? _value.activeEnquiries
          : activeEnquiries // ignore: cast_nullable_to_non_nullable
              as int,
      wonEnquiries: null == wonEnquiries
          ? _value.wonEnquiries
          : wonEnquiries // ignore: cast_nullable_to_non_nullable
              as int,
      lostEnquiries: null == lostEnquiries
          ? _value.lostEnquiries
          : lostEnquiries // ignore: cast_nullable_to_non_nullable
              as int,
      conversionRate: null == conversionRate
          ? _value.conversionRate
          : conversionRate // ignore: cast_nullable_to_non_nullable
              as double,
      estimatedRevenue: null == estimatedRevenue
          ? _value.estimatedRevenue
          : estimatedRevenue // ignore: cast_nullable_to_non_nullable
              as double,
      deltas: null == deltas
          ? _value.deltas
          : deltas // ignore: cast_nullable_to_non_nullable
              as KpiDeltas,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$KpiSummaryImpl implements _KpiSummary {
  const _$KpiSummaryImpl(
      {required this.totalEnquiries,
      required this.activeEnquiries,
      required this.wonEnquiries,
      required this.lostEnquiries,
      required this.conversionRate,
      required this.estimatedRevenue,
      required this.deltas});

  factory _$KpiSummaryImpl.fromJson(Map<String, dynamic> json) =>
      _$$KpiSummaryImplFromJson(json);

  @override
  final int totalEnquiries;
  @override
  final int activeEnquiries;
  @override
  final int wonEnquiries;
  @override
  final int lostEnquiries;
  @override
  final double conversionRate;
  @override
  final double estimatedRevenue;
  @override
  final KpiDeltas deltas;

  @override
  String toString() {
    return 'KpiSummary(totalEnquiries: $totalEnquiries, activeEnquiries: $activeEnquiries, wonEnquiries: $wonEnquiries, lostEnquiries: $lostEnquiries, conversionRate: $conversionRate, estimatedRevenue: $estimatedRevenue, deltas: $deltas)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$KpiSummaryImpl &&
            (identical(other.totalEnquiries, totalEnquiries) ||
                other.totalEnquiries == totalEnquiries) &&
            (identical(other.activeEnquiries, activeEnquiries) ||
                other.activeEnquiries == activeEnquiries) &&
            (identical(other.wonEnquiries, wonEnquiries) ||
                other.wonEnquiries == wonEnquiries) &&
            (identical(other.lostEnquiries, lostEnquiries) ||
                other.lostEnquiries == lostEnquiries) &&
            (identical(other.conversionRate, conversionRate) ||
                other.conversionRate == conversionRate) &&
            (identical(other.estimatedRevenue, estimatedRevenue) ||
                other.estimatedRevenue == estimatedRevenue) &&
            (identical(other.deltas, deltas) || other.deltas == deltas));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, totalEnquiries, activeEnquiries,
      wonEnquiries, lostEnquiries, conversionRate, estimatedRevenue, deltas);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$KpiSummaryImplCopyWith<_$KpiSummaryImpl> get copyWith =>
      __$$KpiSummaryImplCopyWithImpl<_$KpiSummaryImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$KpiSummaryImplToJson(
      this,
    );
  }
}

abstract class _KpiSummary implements KpiSummary {
  const factory _KpiSummary(
      {required final int totalEnquiries,
      required final int activeEnquiries,
      required final int wonEnquiries,
      required final int lostEnquiries,
      required final double conversionRate,
      required final double estimatedRevenue,
      required final KpiDeltas deltas}) = _$KpiSummaryImpl;

  factory _KpiSummary.fromJson(Map<String, dynamic> json) =
      _$KpiSummaryImpl.fromJson;

  @override
  int get totalEnquiries;
  @override
  int get activeEnquiries;
  @override
  int get wonEnquiries;
  @override
  int get lostEnquiries;
  @override
  double get conversionRate;
  @override
  double get estimatedRevenue;
  @override
  KpiDeltas get deltas;
  @override
  @JsonKey(ignore: true)
  _$$KpiSummaryImplCopyWith<_$KpiSummaryImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

KpiDeltas _$KpiDeltasFromJson(Map<String, dynamic> json) {
  return _KpiDeltas.fromJson(json);
}

/// @nodoc
mixin _$KpiDeltas {
  double get totalEnquiriesChange => throw _privateConstructorUsedError;
  double get activeEnquiriesChange => throw _privateConstructorUsedError;
  double get wonEnquiriesChange => throw _privateConstructorUsedError;
  double get lostEnquiriesChange => throw _privateConstructorUsedError;
  double get conversionRateChange => throw _privateConstructorUsedError;
  double get estimatedRevenueChange => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $KpiDeltasCopyWith<KpiDeltas> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $KpiDeltasCopyWith<$Res> {
  factory $KpiDeltasCopyWith(KpiDeltas value, $Res Function(KpiDeltas) then) =
      _$KpiDeltasCopyWithImpl<$Res, KpiDeltas>;
  @useResult
  $Res call(
      {double totalEnquiriesChange,
      double activeEnquiriesChange,
      double wonEnquiriesChange,
      double lostEnquiriesChange,
      double conversionRateChange,
      double estimatedRevenueChange});
}

/// @nodoc
class _$KpiDeltasCopyWithImpl<$Res, $Val extends KpiDeltas>
    implements $KpiDeltasCopyWith<$Res> {
  _$KpiDeltasCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? totalEnquiriesChange = null,
    Object? activeEnquiriesChange = null,
    Object? wonEnquiriesChange = null,
    Object? lostEnquiriesChange = null,
    Object? conversionRateChange = null,
    Object? estimatedRevenueChange = null,
  }) {
    return _then(_value.copyWith(
      totalEnquiriesChange: null == totalEnquiriesChange
          ? _value.totalEnquiriesChange
          : totalEnquiriesChange // ignore: cast_nullable_to_non_nullable
              as double,
      activeEnquiriesChange: null == activeEnquiriesChange
          ? _value.activeEnquiriesChange
          : activeEnquiriesChange // ignore: cast_nullable_to_non_nullable
              as double,
      wonEnquiriesChange: null == wonEnquiriesChange
          ? _value.wonEnquiriesChange
          : wonEnquiriesChange // ignore: cast_nullable_to_non_nullable
              as double,
      lostEnquiriesChange: null == lostEnquiriesChange
          ? _value.lostEnquiriesChange
          : lostEnquiriesChange // ignore: cast_nullable_to_non_nullable
              as double,
      conversionRateChange: null == conversionRateChange
          ? _value.conversionRateChange
          : conversionRateChange // ignore: cast_nullable_to_non_nullable
              as double,
      estimatedRevenueChange: null == estimatedRevenueChange
          ? _value.estimatedRevenueChange
          : estimatedRevenueChange // ignore: cast_nullable_to_non_nullable
              as double,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$KpiDeltasImplCopyWith<$Res>
    implements $KpiDeltasCopyWith<$Res> {
  factory _$$KpiDeltasImplCopyWith(
          _$KpiDeltasImpl value, $Res Function(_$KpiDeltasImpl) then) =
      __$$KpiDeltasImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {double totalEnquiriesChange,
      double activeEnquiriesChange,
      double wonEnquiriesChange,
      double lostEnquiriesChange,
      double conversionRateChange,
      double estimatedRevenueChange});
}

/// @nodoc
class __$$KpiDeltasImplCopyWithImpl<$Res>
    extends _$KpiDeltasCopyWithImpl<$Res, _$KpiDeltasImpl>
    implements _$$KpiDeltasImplCopyWith<$Res> {
  __$$KpiDeltasImplCopyWithImpl(
      _$KpiDeltasImpl _value, $Res Function(_$KpiDeltasImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? totalEnquiriesChange = null,
    Object? activeEnquiriesChange = null,
    Object? wonEnquiriesChange = null,
    Object? lostEnquiriesChange = null,
    Object? conversionRateChange = null,
    Object? estimatedRevenueChange = null,
  }) {
    return _then(_$KpiDeltasImpl(
      totalEnquiriesChange: null == totalEnquiriesChange
          ? _value.totalEnquiriesChange
          : totalEnquiriesChange // ignore: cast_nullable_to_non_nullable
              as double,
      activeEnquiriesChange: null == activeEnquiriesChange
          ? _value.activeEnquiriesChange
          : activeEnquiriesChange // ignore: cast_nullable_to_non_nullable
              as double,
      wonEnquiriesChange: null == wonEnquiriesChange
          ? _value.wonEnquiriesChange
          : wonEnquiriesChange // ignore: cast_nullable_to_non_nullable
              as double,
      lostEnquiriesChange: null == lostEnquiriesChange
          ? _value.lostEnquiriesChange
          : lostEnquiriesChange // ignore: cast_nullable_to_non_nullable
              as double,
      conversionRateChange: null == conversionRateChange
          ? _value.conversionRateChange
          : conversionRateChange // ignore: cast_nullable_to_non_nullable
              as double,
      estimatedRevenueChange: null == estimatedRevenueChange
          ? _value.estimatedRevenueChange
          : estimatedRevenueChange // ignore: cast_nullable_to_non_nullable
              as double,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$KpiDeltasImpl implements _KpiDeltas {
  const _$KpiDeltasImpl(
      {required this.totalEnquiriesChange,
      required this.activeEnquiriesChange,
      required this.wonEnquiriesChange,
      required this.lostEnquiriesChange,
      required this.conversionRateChange,
      required this.estimatedRevenueChange});

  factory _$KpiDeltasImpl.fromJson(Map<String, dynamic> json) =>
      _$$KpiDeltasImplFromJson(json);

  @override
  final double totalEnquiriesChange;
  @override
  final double activeEnquiriesChange;
  @override
  final double wonEnquiriesChange;
  @override
  final double lostEnquiriesChange;
  @override
  final double conversionRateChange;
  @override
  final double estimatedRevenueChange;

  @override
  String toString() {
    return 'KpiDeltas(totalEnquiriesChange: $totalEnquiriesChange, activeEnquiriesChange: $activeEnquiriesChange, wonEnquiriesChange: $wonEnquiriesChange, lostEnquiriesChange: $lostEnquiriesChange, conversionRateChange: $conversionRateChange, estimatedRevenueChange: $estimatedRevenueChange)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$KpiDeltasImpl &&
            (identical(other.totalEnquiriesChange, totalEnquiriesChange) ||
                other.totalEnquiriesChange == totalEnquiriesChange) &&
            (identical(other.activeEnquiriesChange, activeEnquiriesChange) ||
                other.activeEnquiriesChange == activeEnquiriesChange) &&
            (identical(other.wonEnquiriesChange, wonEnquiriesChange) ||
                other.wonEnquiriesChange == wonEnquiriesChange) &&
            (identical(other.lostEnquiriesChange, lostEnquiriesChange) ||
                other.lostEnquiriesChange == lostEnquiriesChange) &&
            (identical(other.conversionRateChange, conversionRateChange) ||
                other.conversionRateChange == conversionRateChange) &&
            (identical(other.estimatedRevenueChange, estimatedRevenueChange) ||
                other.estimatedRevenueChange == estimatedRevenueChange));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      totalEnquiriesChange,
      activeEnquiriesChange,
      wonEnquiriesChange,
      lostEnquiriesChange,
      conversionRateChange,
      estimatedRevenueChange);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$KpiDeltasImplCopyWith<_$KpiDeltasImpl> get copyWith =>
      __$$KpiDeltasImplCopyWithImpl<_$KpiDeltasImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$KpiDeltasImplToJson(
      this,
    );
  }
}

abstract class _KpiDeltas implements KpiDeltas {
  const factory _KpiDeltas(
      {required final double totalEnquiriesChange,
      required final double activeEnquiriesChange,
      required final double wonEnquiriesChange,
      required final double lostEnquiriesChange,
      required final double conversionRateChange,
      required final double estimatedRevenueChange}) = _$KpiDeltasImpl;

  factory _KpiDeltas.fromJson(Map<String, dynamic> json) =
      _$KpiDeltasImpl.fromJson;

  @override
  double get totalEnquiriesChange;
  @override
  double get activeEnquiriesChange;
  @override
  double get wonEnquiriesChange;
  @override
  double get lostEnquiriesChange;
  @override
  double get conversionRateChange;
  @override
  double get estimatedRevenueChange;
  @override
  @JsonKey(ignore: true)
  _$$KpiDeltasImplCopyWith<_$KpiDeltasImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

SeriesPoint _$SeriesPointFromJson(Map<String, dynamic> json) {
  return _SeriesPoint.fromJson(json);
}

/// @nodoc
mixin _$SeriesPoint {
  DateTime get x => throw _privateConstructorUsedError;
  int get count => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $SeriesPointCopyWith<SeriesPoint> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SeriesPointCopyWith<$Res> {
  factory $SeriesPointCopyWith(
          SeriesPoint value, $Res Function(SeriesPoint) then) =
      _$SeriesPointCopyWithImpl<$Res, SeriesPoint>;
  @useResult
  $Res call({DateTime x, int count});
}

/// @nodoc
class _$SeriesPointCopyWithImpl<$Res, $Val extends SeriesPoint>
    implements $SeriesPointCopyWith<$Res> {
  _$SeriesPointCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? x = null,
    Object? count = null,
  }) {
    return _then(_value.copyWith(
      x: null == x
          ? _value.x
          : x // ignore: cast_nullable_to_non_nullable
              as DateTime,
      count: null == count
          ? _value.count
          : count // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$SeriesPointImplCopyWith<$Res>
    implements $SeriesPointCopyWith<$Res> {
  factory _$$SeriesPointImplCopyWith(
          _$SeriesPointImpl value, $Res Function(_$SeriesPointImpl) then) =
      __$$SeriesPointImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({DateTime x, int count});
}

/// @nodoc
class __$$SeriesPointImplCopyWithImpl<$Res>
    extends _$SeriesPointCopyWithImpl<$Res, _$SeriesPointImpl>
    implements _$$SeriesPointImplCopyWith<$Res> {
  __$$SeriesPointImplCopyWithImpl(
      _$SeriesPointImpl _value, $Res Function(_$SeriesPointImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? x = null,
    Object? count = null,
  }) {
    return _then(_$SeriesPointImpl(
      x: null == x
          ? _value.x
          : x // ignore: cast_nullable_to_non_nullable
              as DateTime,
      count: null == count
          ? _value.count
          : count // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$SeriesPointImpl implements _SeriesPoint {
  const _$SeriesPointImpl({required this.x, required this.count});

  factory _$SeriesPointImpl.fromJson(Map<String, dynamic> json) =>
      _$$SeriesPointImplFromJson(json);

  @override
  final DateTime x;
  @override
  final int count;

  @override
  String toString() {
    return 'SeriesPoint(x: $x, count: $count)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SeriesPointImpl &&
            (identical(other.x, x) || other.x == x) &&
            (identical(other.count, count) || other.count == count));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, x, count);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$SeriesPointImplCopyWith<_$SeriesPointImpl> get copyWith =>
      __$$SeriesPointImplCopyWithImpl<_$SeriesPointImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$SeriesPointImplToJson(
      this,
    );
  }
}

abstract class _SeriesPoint implements SeriesPoint {
  const factory _SeriesPoint(
      {required final DateTime x,
      required final int count}) = _$SeriesPointImpl;

  factory _SeriesPoint.fromJson(Map<String, dynamic> json) =
      _$SeriesPointImpl.fromJson;

  @override
  DateTime get x;
  @override
  int get count;
  @override
  @JsonKey(ignore: true)
  _$$SeriesPointImplCopyWith<_$SeriesPointImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

CategoryCount _$CategoryCountFromJson(Map<String, dynamic> json) {
  return _CategoryCount.fromJson(json);
}

/// @nodoc
mixin _$CategoryCount {
  String get key => throw _privateConstructorUsedError;
  int get count => throw _privateConstructorUsedError;
  double get percentage => throw _privateConstructorUsedError;
  String? get label => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $CategoryCountCopyWith<CategoryCount> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CategoryCountCopyWith<$Res> {
  factory $CategoryCountCopyWith(
          CategoryCount value, $Res Function(CategoryCount) then) =
      _$CategoryCountCopyWithImpl<$Res, CategoryCount>;
  @useResult
  $Res call({String key, int count, double percentage, String? label});
}

/// @nodoc
class _$CategoryCountCopyWithImpl<$Res, $Val extends CategoryCount>
    implements $CategoryCountCopyWith<$Res> {
  _$CategoryCountCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? key = null,
    Object? count = null,
    Object? percentage = null,
    Object? label = freezed,
  }) {
    return _then(_value.copyWith(
      key: null == key
          ? _value.key
          : key // ignore: cast_nullable_to_non_nullable
              as String,
      count: null == count
          ? _value.count
          : count // ignore: cast_nullable_to_non_nullable
              as int,
      percentage: null == percentage
          ? _value.percentage
          : percentage // ignore: cast_nullable_to_non_nullable
              as double,
      label: freezed == label
          ? _value.label
          : label // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$CategoryCountImplCopyWith<$Res>
    implements $CategoryCountCopyWith<$Res> {
  factory _$$CategoryCountImplCopyWith(
          _$CategoryCountImpl value, $Res Function(_$CategoryCountImpl) then) =
      __$$CategoryCountImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String key, int count, double percentage, String? label});
}

/// @nodoc
class __$$CategoryCountImplCopyWithImpl<$Res>
    extends _$CategoryCountCopyWithImpl<$Res, _$CategoryCountImpl>
    implements _$$CategoryCountImplCopyWith<$Res> {
  __$$CategoryCountImplCopyWithImpl(
      _$CategoryCountImpl _value, $Res Function(_$CategoryCountImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? key = null,
    Object? count = null,
    Object? percentage = null,
    Object? label = freezed,
  }) {
    return _then(_$CategoryCountImpl(
      key: null == key
          ? _value.key
          : key // ignore: cast_nullable_to_non_nullable
              as String,
      count: null == count
          ? _value.count
          : count // ignore: cast_nullable_to_non_nullable
              as int,
      percentage: null == percentage
          ? _value.percentage
          : percentage // ignore: cast_nullable_to_non_nullable
              as double,
      label: freezed == label
          ? _value.label
          : label // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$CategoryCountImpl implements _CategoryCount {
  const _$CategoryCountImpl(
      {required this.key,
      required this.count,
      required this.percentage,
      this.label});

  factory _$CategoryCountImpl.fromJson(Map<String, dynamic> json) =>
      _$$CategoryCountImplFromJson(json);

  @override
  final String key;
  @override
  final int count;
  @override
  final double percentage;
  @override
  final String? label;

  @override
  String toString() {
    return 'CategoryCount(key: $key, count: $count, percentage: $percentage, label: $label)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CategoryCountImpl &&
            (identical(other.key, key) || other.key == key) &&
            (identical(other.count, count) || other.count == count) &&
            (identical(other.percentage, percentage) ||
                other.percentage == percentage) &&
            (identical(other.label, label) || other.label == label));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, key, count, percentage, label);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$CategoryCountImplCopyWith<_$CategoryCountImpl> get copyWith =>
      __$$CategoryCountImplCopyWithImpl<_$CategoryCountImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$CategoryCountImplToJson(
      this,
    );
  }
}

abstract class _CategoryCount implements CategoryCount {
  const factory _CategoryCount(
      {required final String key,
      required final int count,
      required final double percentage,
      final String? label}) = _$CategoryCountImpl;

  factory _CategoryCount.fromJson(Map<String, dynamic> json) =
      _$CategoryCountImpl.fromJson;

  @override
  String get key;
  @override
  int get count;
  @override
  double get percentage;
  @override
  String? get label;
  @override
  @JsonKey(ignore: true)
  _$$CategoryCountImplCopyWith<_$CategoryCountImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

RecentEnquiry _$RecentEnquiryFromJson(Map<String, dynamic> json) {
  return _RecentEnquiry.fromJson(json);
}

/// @nodoc
mixin _$RecentEnquiry {
  String get id => throw _privateConstructorUsedError;
  DateTime get date => throw _privateConstructorUsedError;
  String get customerName => throw _privateConstructorUsedError;
  String get eventType => throw _privateConstructorUsedError;
  String get status => throw _privateConstructorUsedError;
  String get source => throw _privateConstructorUsedError;
  String get priority => throw _privateConstructorUsedError;
  double? get totalCost => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $RecentEnquiryCopyWith<RecentEnquiry> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $RecentEnquiryCopyWith<$Res> {
  factory $RecentEnquiryCopyWith(
          RecentEnquiry value, $Res Function(RecentEnquiry) then) =
      _$RecentEnquiryCopyWithImpl<$Res, RecentEnquiry>;
  @useResult
  $Res call(
      {String id,
      DateTime date,
      String customerName,
      String eventType,
      String status,
      String source,
      String priority,
      double? totalCost});
}

/// @nodoc
class _$RecentEnquiryCopyWithImpl<$Res, $Val extends RecentEnquiry>
    implements $RecentEnquiryCopyWith<$Res> {
  _$RecentEnquiryCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? date = null,
    Object? customerName = null,
    Object? eventType = null,
    Object? status = null,
    Object? source = null,
    Object? priority = null,
    Object? totalCost = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      date: null == date
          ? _value.date
          : date // ignore: cast_nullable_to_non_nullable
              as DateTime,
      customerName: null == customerName
          ? _value.customerName
          : customerName // ignore: cast_nullable_to_non_nullable
              as String,
      eventType: null == eventType
          ? _value.eventType
          : eventType // ignore: cast_nullable_to_non_nullable
              as String,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      source: null == source
          ? _value.source
          : source // ignore: cast_nullable_to_non_nullable
              as String,
      priority: null == priority
          ? _value.priority
          : priority // ignore: cast_nullable_to_non_nullable
              as String,
      totalCost: freezed == totalCost
          ? _value.totalCost
          : totalCost // ignore: cast_nullable_to_non_nullable
              as double?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$RecentEnquiryImplCopyWith<$Res>
    implements $RecentEnquiryCopyWith<$Res> {
  factory _$$RecentEnquiryImplCopyWith(
          _$RecentEnquiryImpl value, $Res Function(_$RecentEnquiryImpl) then) =
      __$$RecentEnquiryImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      DateTime date,
      String customerName,
      String eventType,
      String status,
      String source,
      String priority,
      double? totalCost});
}

/// @nodoc
class __$$RecentEnquiryImplCopyWithImpl<$Res>
    extends _$RecentEnquiryCopyWithImpl<$Res, _$RecentEnquiryImpl>
    implements _$$RecentEnquiryImplCopyWith<$Res> {
  __$$RecentEnquiryImplCopyWithImpl(
      _$RecentEnquiryImpl _value, $Res Function(_$RecentEnquiryImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? date = null,
    Object? customerName = null,
    Object? eventType = null,
    Object? status = null,
    Object? source = null,
    Object? priority = null,
    Object? totalCost = freezed,
  }) {
    return _then(_$RecentEnquiryImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      date: null == date
          ? _value.date
          : date // ignore: cast_nullable_to_non_nullable
              as DateTime,
      customerName: null == customerName
          ? _value.customerName
          : customerName // ignore: cast_nullable_to_non_nullable
              as String,
      eventType: null == eventType
          ? _value.eventType
          : eventType // ignore: cast_nullable_to_non_nullable
              as String,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      source: null == source
          ? _value.source
          : source // ignore: cast_nullable_to_non_nullable
              as String,
      priority: null == priority
          ? _value.priority
          : priority // ignore: cast_nullable_to_non_nullable
              as String,
      totalCost: freezed == totalCost
          ? _value.totalCost
          : totalCost // ignore: cast_nullable_to_non_nullable
              as double?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$RecentEnquiryImpl implements _RecentEnquiry {
  const _$RecentEnquiryImpl(
      {required this.id,
      required this.date,
      required this.customerName,
      required this.eventType,
      required this.status,
      required this.source,
      required this.priority,
      this.totalCost});

  factory _$RecentEnquiryImpl.fromJson(Map<String, dynamic> json) =>
      _$$RecentEnquiryImplFromJson(json);

  @override
  final String id;
  @override
  final DateTime date;
  @override
  final String customerName;
  @override
  final String eventType;
  @override
  final String status;
  @override
  final String source;
  @override
  final String priority;
  @override
  final double? totalCost;

  @override
  String toString() {
    return 'RecentEnquiry(id: $id, date: $date, customerName: $customerName, eventType: $eventType, status: $status, source: $source, priority: $priority, totalCost: $totalCost)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$RecentEnquiryImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.date, date) || other.date == date) &&
            (identical(other.customerName, customerName) ||
                other.customerName == customerName) &&
            (identical(other.eventType, eventType) ||
                other.eventType == eventType) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.source, source) || other.source == source) &&
            (identical(other.priority, priority) ||
                other.priority == priority) &&
            (identical(other.totalCost, totalCost) ||
                other.totalCost == totalCost));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, id, date, customerName,
      eventType, status, source, priority, totalCost);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$RecentEnquiryImplCopyWith<_$RecentEnquiryImpl> get copyWith =>
      __$$RecentEnquiryImplCopyWithImpl<_$RecentEnquiryImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$RecentEnquiryImplToJson(
      this,
    );
  }
}

abstract class _RecentEnquiry implements RecentEnquiry {
  const factory _RecentEnquiry(
      {required final String id,
      required final DateTime date,
      required final String customerName,
      required final String eventType,
      required final String status,
      required final String source,
      required final String priority,
      final double? totalCost}) = _$RecentEnquiryImpl;

  factory _RecentEnquiry.fromJson(Map<String, dynamic> json) =
      _$RecentEnquiryImpl.fromJson;

  @override
  String get id;
  @override
  DateTime get date;
  @override
  String get customerName;
  @override
  String get eventType;
  @override
  String get status;
  @override
  String get source;
  @override
  String get priority;
  @override
  double? get totalCost;
  @override
  @JsonKey(ignore: true)
  _$$RecentEnquiryImplCopyWith<_$RecentEnquiryImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

AnalyticsFilters _$AnalyticsFiltersFromJson(Map<String, dynamic> json) {
  return _AnalyticsFilters.fromJson(json);
}

/// @nodoc
mixin _$AnalyticsFilters {
  DateRange get dateRange => throw _privateConstructorUsedError;
  DateRangePreset get preset => throw _privateConstructorUsedError;
  String? get eventType => throw _privateConstructorUsedError;
  String? get status => throw _privateConstructorUsedError;
  String? get priority => throw _privateConstructorUsedError;
  String? get source => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $AnalyticsFiltersCopyWith<AnalyticsFilters> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AnalyticsFiltersCopyWith<$Res> {
  factory $AnalyticsFiltersCopyWith(
          AnalyticsFilters value, $Res Function(AnalyticsFilters) then) =
      _$AnalyticsFiltersCopyWithImpl<$Res, AnalyticsFilters>;
  @useResult
  $Res call(
      {DateRange dateRange,
      DateRangePreset preset,
      String? eventType,
      String? status,
      String? priority,
      String? source});

  $DateRangeCopyWith<$Res> get dateRange;
}

/// @nodoc
class _$AnalyticsFiltersCopyWithImpl<$Res, $Val extends AnalyticsFilters>
    implements $AnalyticsFiltersCopyWith<$Res> {
  _$AnalyticsFiltersCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? dateRange = null,
    Object? preset = null,
    Object? eventType = freezed,
    Object? status = freezed,
    Object? priority = freezed,
    Object? source = freezed,
  }) {
    return _then(_value.copyWith(
      dateRange: null == dateRange
          ? _value.dateRange
          : dateRange // ignore: cast_nullable_to_non_nullable
              as DateRange,
      preset: null == preset
          ? _value.preset
          : preset // ignore: cast_nullable_to_non_nullable
              as DateRangePreset,
      eventType: freezed == eventType
          ? _value.eventType
          : eventType // ignore: cast_nullable_to_non_nullable
              as String?,
      status: freezed == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String?,
      priority: freezed == priority
          ? _value.priority
          : priority // ignore: cast_nullable_to_non_nullable
              as String?,
      source: freezed == source
          ? _value.source
          : source // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }

  @override
  @pragma('vm:prefer-inline')
  $DateRangeCopyWith<$Res> get dateRange {
    return $DateRangeCopyWith<$Res>(_value.dateRange, (value) {
      return _then(_value.copyWith(dateRange: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$AnalyticsFiltersImplCopyWith<$Res>
    implements $AnalyticsFiltersCopyWith<$Res> {
  factory _$$AnalyticsFiltersImplCopyWith(_$AnalyticsFiltersImpl value,
          $Res Function(_$AnalyticsFiltersImpl) then) =
      __$$AnalyticsFiltersImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {DateRange dateRange,
      DateRangePreset preset,
      String? eventType,
      String? status,
      String? priority,
      String? source});

  @override
  $DateRangeCopyWith<$Res> get dateRange;
}

/// @nodoc
class __$$AnalyticsFiltersImplCopyWithImpl<$Res>
    extends _$AnalyticsFiltersCopyWithImpl<$Res, _$AnalyticsFiltersImpl>
    implements _$$AnalyticsFiltersImplCopyWith<$Res> {
  __$$AnalyticsFiltersImplCopyWithImpl(_$AnalyticsFiltersImpl _value,
      $Res Function(_$AnalyticsFiltersImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? dateRange = null,
    Object? preset = null,
    Object? eventType = freezed,
    Object? status = freezed,
    Object? priority = freezed,
    Object? source = freezed,
  }) {
    return _then(_$AnalyticsFiltersImpl(
      dateRange: null == dateRange
          ? _value.dateRange
          : dateRange // ignore: cast_nullable_to_non_nullable
              as DateRange,
      preset: null == preset
          ? _value.preset
          : preset // ignore: cast_nullable_to_non_nullable
              as DateRangePreset,
      eventType: freezed == eventType
          ? _value.eventType
          : eventType // ignore: cast_nullable_to_non_nullable
              as String?,
      status: freezed == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String?,
      priority: freezed == priority
          ? _value.priority
          : priority // ignore: cast_nullable_to_non_nullable
              as String?,
      source: freezed == source
          ? _value.source
          : source // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$AnalyticsFiltersImpl implements _AnalyticsFilters {
  const _$AnalyticsFiltersImpl(
      {required this.dateRange,
      required this.preset,
      this.eventType,
      this.status,
      this.priority,
      this.source});

  factory _$AnalyticsFiltersImpl.fromJson(Map<String, dynamic> json) =>
      _$$AnalyticsFiltersImplFromJson(json);

  @override
  final DateRange dateRange;
  @override
  final DateRangePreset preset;
  @override
  final String? eventType;
  @override
  final String? status;
  @override
  final String? priority;
  @override
  final String? source;

  @override
  String toString() {
    return 'AnalyticsFilters(dateRange: $dateRange, preset: $preset, eventType: $eventType, status: $status, priority: $priority, source: $source)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AnalyticsFiltersImpl &&
            (identical(other.dateRange, dateRange) ||
                other.dateRange == dateRange) &&
            (identical(other.preset, preset) || other.preset == preset) &&
            (identical(other.eventType, eventType) ||
                other.eventType == eventType) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.priority, priority) ||
                other.priority == priority) &&
            (identical(other.source, source) || other.source == source));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType, dateRange, preset, eventType, status, priority, source);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$AnalyticsFiltersImplCopyWith<_$AnalyticsFiltersImpl> get copyWith =>
      __$$AnalyticsFiltersImplCopyWithImpl<_$AnalyticsFiltersImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$AnalyticsFiltersImplToJson(
      this,
    );
  }
}

abstract class _AnalyticsFilters implements AnalyticsFilters {
  const factory _AnalyticsFilters(
      {required final DateRange dateRange,
      required final DateRangePreset preset,
      final String? eventType,
      final String? status,
      final String? priority,
      final String? source}) = _$AnalyticsFiltersImpl;

  factory _AnalyticsFilters.fromJson(Map<String, dynamic> json) =
      _$AnalyticsFiltersImpl.fromJson;

  @override
  DateRange get dateRange;
  @override
  DateRangePreset get preset;
  @override
  String? get eventType;
  @override
  String? get status;
  @override
  String? get priority;
  @override
  String? get source;
  @override
  @JsonKey(ignore: true)
  _$$AnalyticsFiltersImplCopyWith<_$AnalyticsFiltersImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

AnalyticsState _$AnalyticsStateFromJson(Map<String, dynamic> json) {
  return _AnalyticsState.fromJson(json);
}

/// @nodoc
mixin _$AnalyticsState {
  AnalyticsFilters get filters => throw _privateConstructorUsedError;
  KpiSummary? get kpiSummary => throw _privateConstructorUsedError;
  List<SeriesPoint> get timeSeries => throw _privateConstructorUsedError;
  List<CategoryCount> get statusBreakdown => throw _privateConstructorUsedError;
  List<CategoryCount> get eventTypeBreakdown =>
      throw _privateConstructorUsedError;
  List<CategoryCount> get sourceBreakdown => throw _privateConstructorUsedError;
  List<RecentEnquiry> get recentEnquiries => throw _privateConstructorUsedError;
  List<CategoryCount> get topEventTypes => throw _privateConstructorUsedError;
  List<CategoryCount> get topSources => throw _privateConstructorUsedError;
  bool get isLoading => throw _privateConstructorUsedError;
  bool get isRefreshing => throw _privateConstructorUsedError;
  String? get error => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $AnalyticsStateCopyWith<AnalyticsState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AnalyticsStateCopyWith<$Res> {
  factory $AnalyticsStateCopyWith(
          AnalyticsState value, $Res Function(AnalyticsState) then) =
      _$AnalyticsStateCopyWithImpl<$Res, AnalyticsState>;
  @useResult
  $Res call(
      {AnalyticsFilters filters,
      KpiSummary? kpiSummary,
      List<SeriesPoint> timeSeries,
      List<CategoryCount> statusBreakdown,
      List<CategoryCount> eventTypeBreakdown,
      List<CategoryCount> sourceBreakdown,
      List<RecentEnquiry> recentEnquiries,
      List<CategoryCount> topEventTypes,
      List<CategoryCount> topSources,
      bool isLoading,
      bool isRefreshing,
      String? error});

  $AnalyticsFiltersCopyWith<$Res> get filters;
  $KpiSummaryCopyWith<$Res>? get kpiSummary;
}

/// @nodoc
class _$AnalyticsStateCopyWithImpl<$Res, $Val extends AnalyticsState>
    implements $AnalyticsStateCopyWith<$Res> {
  _$AnalyticsStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? filters = null,
    Object? kpiSummary = freezed,
    Object? timeSeries = null,
    Object? statusBreakdown = null,
    Object? eventTypeBreakdown = null,
    Object? sourceBreakdown = null,
    Object? recentEnquiries = null,
    Object? topEventTypes = null,
    Object? topSources = null,
    Object? isLoading = null,
    Object? isRefreshing = null,
    Object? error = freezed,
  }) {
    return _then(_value.copyWith(
      filters: null == filters
          ? _value.filters
          : filters // ignore: cast_nullable_to_non_nullable
              as AnalyticsFilters,
      kpiSummary: freezed == kpiSummary
          ? _value.kpiSummary
          : kpiSummary // ignore: cast_nullable_to_non_nullable
              as KpiSummary?,
      timeSeries: null == timeSeries
          ? _value.timeSeries
          : timeSeries // ignore: cast_nullable_to_non_nullable
              as List<SeriesPoint>,
      statusBreakdown: null == statusBreakdown
          ? _value.statusBreakdown
          : statusBreakdown // ignore: cast_nullable_to_non_nullable
              as List<CategoryCount>,
      eventTypeBreakdown: null == eventTypeBreakdown
          ? _value.eventTypeBreakdown
          : eventTypeBreakdown // ignore: cast_nullable_to_non_nullable
              as List<CategoryCount>,
      sourceBreakdown: null == sourceBreakdown
          ? _value.sourceBreakdown
          : sourceBreakdown // ignore: cast_nullable_to_non_nullable
              as List<CategoryCount>,
      recentEnquiries: null == recentEnquiries
          ? _value.recentEnquiries
          : recentEnquiries // ignore: cast_nullable_to_non_nullable
              as List<RecentEnquiry>,
      topEventTypes: null == topEventTypes
          ? _value.topEventTypes
          : topEventTypes // ignore: cast_nullable_to_non_nullable
              as List<CategoryCount>,
      topSources: null == topSources
          ? _value.topSources
          : topSources // ignore: cast_nullable_to_non_nullable
              as List<CategoryCount>,
      isLoading: null == isLoading
          ? _value.isLoading
          : isLoading // ignore: cast_nullable_to_non_nullable
              as bool,
      isRefreshing: null == isRefreshing
          ? _value.isRefreshing
          : isRefreshing // ignore: cast_nullable_to_non_nullable
              as bool,
      error: freezed == error
          ? _value.error
          : error // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }

  @override
  @pragma('vm:prefer-inline')
  $AnalyticsFiltersCopyWith<$Res> get filters {
    return $AnalyticsFiltersCopyWith<$Res>(_value.filters, (value) {
      return _then(_value.copyWith(filters: value) as $Val);
    });
  }

  @override
  @pragma('vm:prefer-inline')
  $KpiSummaryCopyWith<$Res>? get kpiSummary {
    if (_value.kpiSummary == null) {
      return null;
    }

    return $KpiSummaryCopyWith<$Res>(_value.kpiSummary!, (value) {
      return _then(_value.copyWith(kpiSummary: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$AnalyticsStateImplCopyWith<$Res>
    implements $AnalyticsStateCopyWith<$Res> {
  factory _$$AnalyticsStateImplCopyWith(_$AnalyticsStateImpl value,
          $Res Function(_$AnalyticsStateImpl) then) =
      __$$AnalyticsStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {AnalyticsFilters filters,
      KpiSummary? kpiSummary,
      List<SeriesPoint> timeSeries,
      List<CategoryCount> statusBreakdown,
      List<CategoryCount> eventTypeBreakdown,
      List<CategoryCount> sourceBreakdown,
      List<RecentEnquiry> recentEnquiries,
      List<CategoryCount> topEventTypes,
      List<CategoryCount> topSources,
      bool isLoading,
      bool isRefreshing,
      String? error});

  @override
  $AnalyticsFiltersCopyWith<$Res> get filters;
  @override
  $KpiSummaryCopyWith<$Res>? get kpiSummary;
}

/// @nodoc
class __$$AnalyticsStateImplCopyWithImpl<$Res>
    extends _$AnalyticsStateCopyWithImpl<$Res, _$AnalyticsStateImpl>
    implements _$$AnalyticsStateImplCopyWith<$Res> {
  __$$AnalyticsStateImplCopyWithImpl(
      _$AnalyticsStateImpl _value, $Res Function(_$AnalyticsStateImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? filters = null,
    Object? kpiSummary = freezed,
    Object? timeSeries = null,
    Object? statusBreakdown = null,
    Object? eventTypeBreakdown = null,
    Object? sourceBreakdown = null,
    Object? recentEnquiries = null,
    Object? topEventTypes = null,
    Object? topSources = null,
    Object? isLoading = null,
    Object? isRefreshing = null,
    Object? error = freezed,
  }) {
    return _then(_$AnalyticsStateImpl(
      filters: null == filters
          ? _value.filters
          : filters // ignore: cast_nullable_to_non_nullable
              as AnalyticsFilters,
      kpiSummary: freezed == kpiSummary
          ? _value.kpiSummary
          : kpiSummary // ignore: cast_nullable_to_non_nullable
              as KpiSummary?,
      timeSeries: null == timeSeries
          ? _value._timeSeries
          : timeSeries // ignore: cast_nullable_to_non_nullable
              as List<SeriesPoint>,
      statusBreakdown: null == statusBreakdown
          ? _value._statusBreakdown
          : statusBreakdown // ignore: cast_nullable_to_non_nullable
              as List<CategoryCount>,
      eventTypeBreakdown: null == eventTypeBreakdown
          ? _value._eventTypeBreakdown
          : eventTypeBreakdown // ignore: cast_nullable_to_non_nullable
              as List<CategoryCount>,
      sourceBreakdown: null == sourceBreakdown
          ? _value._sourceBreakdown
          : sourceBreakdown // ignore: cast_nullable_to_non_nullable
              as List<CategoryCount>,
      recentEnquiries: null == recentEnquiries
          ? _value._recentEnquiries
          : recentEnquiries // ignore: cast_nullable_to_non_nullable
              as List<RecentEnquiry>,
      topEventTypes: null == topEventTypes
          ? _value._topEventTypes
          : topEventTypes // ignore: cast_nullable_to_non_nullable
              as List<CategoryCount>,
      topSources: null == topSources
          ? _value._topSources
          : topSources // ignore: cast_nullable_to_non_nullable
              as List<CategoryCount>,
      isLoading: null == isLoading
          ? _value.isLoading
          : isLoading // ignore: cast_nullable_to_non_nullable
              as bool,
      isRefreshing: null == isRefreshing
          ? _value.isRefreshing
          : isRefreshing // ignore: cast_nullable_to_non_nullable
              as bool,
      error: freezed == error
          ? _value.error
          : error // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$AnalyticsStateImpl implements _AnalyticsState {
  const _$AnalyticsStateImpl(
      {required this.filters,
      this.kpiSummary,
      final List<SeriesPoint> timeSeries = const [],
      final List<CategoryCount> statusBreakdown = const [],
      final List<CategoryCount> eventTypeBreakdown = const [],
      final List<CategoryCount> sourceBreakdown = const [],
      final List<RecentEnquiry> recentEnquiries = const [],
      final List<CategoryCount> topEventTypes = const [],
      final List<CategoryCount> topSources = const [],
      this.isLoading = false,
      this.isRefreshing = false,
      this.error})
      : _timeSeries = timeSeries,
        _statusBreakdown = statusBreakdown,
        _eventTypeBreakdown = eventTypeBreakdown,
        _sourceBreakdown = sourceBreakdown,
        _recentEnquiries = recentEnquiries,
        _topEventTypes = topEventTypes,
        _topSources = topSources;

  factory _$AnalyticsStateImpl.fromJson(Map<String, dynamic> json) =>
      _$$AnalyticsStateImplFromJson(json);

  @override
  final AnalyticsFilters filters;
  @override
  final KpiSummary? kpiSummary;
  final List<SeriesPoint> _timeSeries;
  @override
  @JsonKey()
  List<SeriesPoint> get timeSeries {
    if (_timeSeries is EqualUnmodifiableListView) return _timeSeries;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_timeSeries);
  }

  final List<CategoryCount> _statusBreakdown;
  @override
  @JsonKey()
  List<CategoryCount> get statusBreakdown {
    if (_statusBreakdown is EqualUnmodifiableListView) return _statusBreakdown;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_statusBreakdown);
  }

  final List<CategoryCount> _eventTypeBreakdown;
  @override
  @JsonKey()
  List<CategoryCount> get eventTypeBreakdown {
    if (_eventTypeBreakdown is EqualUnmodifiableListView)
      return _eventTypeBreakdown;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_eventTypeBreakdown);
  }

  final List<CategoryCount> _sourceBreakdown;
  @override
  @JsonKey()
  List<CategoryCount> get sourceBreakdown {
    if (_sourceBreakdown is EqualUnmodifiableListView) return _sourceBreakdown;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_sourceBreakdown);
  }

  final List<RecentEnquiry> _recentEnquiries;
  @override
  @JsonKey()
  List<RecentEnquiry> get recentEnquiries {
    if (_recentEnquiries is EqualUnmodifiableListView) return _recentEnquiries;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_recentEnquiries);
  }

  final List<CategoryCount> _topEventTypes;
  @override
  @JsonKey()
  List<CategoryCount> get topEventTypes {
    if (_topEventTypes is EqualUnmodifiableListView) return _topEventTypes;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_topEventTypes);
  }

  final List<CategoryCount> _topSources;
  @override
  @JsonKey()
  List<CategoryCount> get topSources {
    if (_topSources is EqualUnmodifiableListView) return _topSources;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_topSources);
  }

  @override
  @JsonKey()
  final bool isLoading;
  @override
  @JsonKey()
  final bool isRefreshing;
  @override
  final String? error;

  @override
  String toString() {
    return 'AnalyticsState(filters: $filters, kpiSummary: $kpiSummary, timeSeries: $timeSeries, statusBreakdown: $statusBreakdown, eventTypeBreakdown: $eventTypeBreakdown, sourceBreakdown: $sourceBreakdown, recentEnquiries: $recentEnquiries, topEventTypes: $topEventTypes, topSources: $topSources, isLoading: $isLoading, isRefreshing: $isRefreshing, error: $error)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AnalyticsStateImpl &&
            (identical(other.filters, filters) || other.filters == filters) &&
            (identical(other.kpiSummary, kpiSummary) ||
                other.kpiSummary == kpiSummary) &&
            const DeepCollectionEquality()
                .equals(other._timeSeries, _timeSeries) &&
            const DeepCollectionEquality()
                .equals(other._statusBreakdown, _statusBreakdown) &&
            const DeepCollectionEquality()
                .equals(other._eventTypeBreakdown, _eventTypeBreakdown) &&
            const DeepCollectionEquality()
                .equals(other._sourceBreakdown, _sourceBreakdown) &&
            const DeepCollectionEquality()
                .equals(other._recentEnquiries, _recentEnquiries) &&
            const DeepCollectionEquality()
                .equals(other._topEventTypes, _topEventTypes) &&
            const DeepCollectionEquality()
                .equals(other._topSources, _topSources) &&
            (identical(other.isLoading, isLoading) ||
                other.isLoading == isLoading) &&
            (identical(other.isRefreshing, isRefreshing) ||
                other.isRefreshing == isRefreshing) &&
            (identical(other.error, error) || other.error == error));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      filters,
      kpiSummary,
      const DeepCollectionEquality().hash(_timeSeries),
      const DeepCollectionEquality().hash(_statusBreakdown),
      const DeepCollectionEquality().hash(_eventTypeBreakdown),
      const DeepCollectionEquality().hash(_sourceBreakdown),
      const DeepCollectionEquality().hash(_recentEnquiries),
      const DeepCollectionEquality().hash(_topEventTypes),
      const DeepCollectionEquality().hash(_topSources),
      isLoading,
      isRefreshing,
      error);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$AnalyticsStateImplCopyWith<_$AnalyticsStateImpl> get copyWith =>
      __$$AnalyticsStateImplCopyWithImpl<_$AnalyticsStateImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$AnalyticsStateImplToJson(
      this,
    );
  }
}

abstract class _AnalyticsState implements AnalyticsState {
  const factory _AnalyticsState(
      {required final AnalyticsFilters filters,
      final KpiSummary? kpiSummary,
      final List<SeriesPoint> timeSeries,
      final List<CategoryCount> statusBreakdown,
      final List<CategoryCount> eventTypeBreakdown,
      final List<CategoryCount> sourceBreakdown,
      final List<RecentEnquiry> recentEnquiries,
      final List<CategoryCount> topEventTypes,
      final List<CategoryCount> topSources,
      final bool isLoading,
      final bool isRefreshing,
      final String? error}) = _$AnalyticsStateImpl;

  factory _AnalyticsState.fromJson(Map<String, dynamic> json) =
      _$AnalyticsStateImpl.fromJson;

  @override
  AnalyticsFilters get filters;
  @override
  KpiSummary? get kpiSummary;
  @override
  List<SeriesPoint> get timeSeries;
  @override
  List<CategoryCount> get statusBreakdown;
  @override
  List<CategoryCount> get eventTypeBreakdown;
  @override
  List<CategoryCount> get sourceBreakdown;
  @override
  List<RecentEnquiry> get recentEnquiries;
  @override
  List<CategoryCount> get topEventTypes;
  @override
  List<CategoryCount> get topSources;
  @override
  bool get isLoading;
  @override
  bool get isRefreshing;
  @override
  String? get error;
  @override
  @JsonKey(ignore: true)
  _$$AnalyticsStateImplCopyWith<_$AnalyticsStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
