// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'enquiry_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

BudgetRange _$BudgetRangeFromJson(Map<String, dynamic> json) {
  return _BudgetRange.fromJson(json);
}

/// @nodoc
mixin _$BudgetRange {
  int? get min => throw _privateConstructorUsedError;
  int? get max => throw _privateConstructorUsedError;

  /// Serializes this BudgetRange to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of BudgetRange
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $BudgetRangeCopyWith<BudgetRange> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $BudgetRangeCopyWith<$Res> {
  factory $BudgetRangeCopyWith(
          BudgetRange value, $Res Function(BudgetRange) then) =
      _$BudgetRangeCopyWithImpl<$Res, BudgetRange>;
  @useResult
  $Res call({int? min, int? max});
}

/// @nodoc
class _$BudgetRangeCopyWithImpl<$Res, $Val extends BudgetRange>
    implements $BudgetRangeCopyWith<$Res> {
  _$BudgetRangeCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of BudgetRange
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? min = freezed,
    Object? max = freezed,
  }) {
    return _then(_value.copyWith(
      min: freezed == min
          ? _value.min
          : min // ignore: cast_nullable_to_non_nullable
              as int?,
      max: freezed == max
          ? _value.max
          : max // ignore: cast_nullable_to_non_nullable
              as int?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$BudgetRangeImplCopyWith<$Res>
    implements $BudgetRangeCopyWith<$Res> {
  factory _$$BudgetRangeImplCopyWith(
          _$BudgetRangeImpl value, $Res Function(_$BudgetRangeImpl) then) =
      __$$BudgetRangeImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({int? min, int? max});
}

/// @nodoc
class __$$BudgetRangeImplCopyWithImpl<$Res>
    extends _$BudgetRangeCopyWithImpl<$Res, _$BudgetRangeImpl>
    implements _$$BudgetRangeImplCopyWith<$Res> {
  __$$BudgetRangeImplCopyWithImpl(
      _$BudgetRangeImpl _value, $Res Function(_$BudgetRangeImpl) _then)
      : super(_value, _then);

  /// Create a copy of BudgetRange
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? min = freezed,
    Object? max = freezed,
  }) {
    return _then(_$BudgetRangeImpl(
      min: freezed == min
          ? _value.min
          : min // ignore: cast_nullable_to_non_nullable
              as int?,
      max: freezed == max
          ? _value.max
          : max // ignore: cast_nullable_to_non_nullable
              as int?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$BudgetRangeImpl implements _BudgetRange {
  const _$BudgetRangeImpl({this.min, this.max});

  factory _$BudgetRangeImpl.fromJson(Map<String, dynamic> json) =>
      _$$BudgetRangeImplFromJson(json);

  @override
  final int? min;
  @override
  final int? max;

  @override
  String toString() {
    return 'BudgetRange(min: $min, max: $max)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$BudgetRangeImpl &&
            (identical(other.min, min) || other.min == min) &&
            (identical(other.max, max) || other.max == max));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, min, max);

  /// Create a copy of BudgetRange
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$BudgetRangeImplCopyWith<_$BudgetRangeImpl> get copyWith =>
      __$$BudgetRangeImplCopyWithImpl<_$BudgetRangeImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$BudgetRangeImplToJson(
      this,
    );
  }
}

abstract class _BudgetRange implements BudgetRange {
  const factory _BudgetRange({final int? min, final int? max}) =
      _$BudgetRangeImpl;

  factory _BudgetRange.fromJson(Map<String, dynamic> json) =
      _$BudgetRangeImpl.fromJson;

  @override
  int? get min;
  @override
  int? get max;

  /// Create a copy of BudgetRange
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$BudgetRangeImplCopyWith<_$BudgetRangeImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

Payment _$PaymentFromJson(Map<String, dynamic> json) {
  return _Payment.fromJson(json);
}

/// @nodoc
mixin _$Payment {
  int? get totalAmount => throw _privateConstructorUsedError;
  int? get advanceAmount => throw _privateConstructorUsedError;
  int? get balance => throw _privateConstructorUsedError;
  DateTime? get confirmedAt => throw _privateConstructorUsedError;

  /// Serializes this Payment to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Payment
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PaymentCopyWith<Payment> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PaymentCopyWith<$Res> {
  factory $PaymentCopyWith(Payment value, $Res Function(Payment) then) =
      _$PaymentCopyWithImpl<$Res, Payment>;
  @useResult
  $Res call(
      {int? totalAmount,
      int? advanceAmount,
      int? balance,
      DateTime? confirmedAt});
}

/// @nodoc
class _$PaymentCopyWithImpl<$Res, $Val extends Payment>
    implements $PaymentCopyWith<$Res> {
  _$PaymentCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Payment
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? totalAmount = freezed,
    Object? advanceAmount = freezed,
    Object? balance = freezed,
    Object? confirmedAt = freezed,
  }) {
    return _then(_value.copyWith(
      totalAmount: freezed == totalAmount
          ? _value.totalAmount
          : totalAmount // ignore: cast_nullable_to_non_nullable
              as int?,
      advanceAmount: freezed == advanceAmount
          ? _value.advanceAmount
          : advanceAmount // ignore: cast_nullable_to_non_nullable
              as int?,
      balance: freezed == balance
          ? _value.balance
          : balance // ignore: cast_nullable_to_non_nullable
              as int?,
      confirmedAt: freezed == confirmedAt
          ? _value.confirmedAt
          : confirmedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$PaymentImplCopyWith<$Res> implements $PaymentCopyWith<$Res> {
  factory _$$PaymentImplCopyWith(
          _$PaymentImpl value, $Res Function(_$PaymentImpl) then) =
      __$$PaymentImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int? totalAmount,
      int? advanceAmount,
      int? balance,
      DateTime? confirmedAt});
}

/// @nodoc
class __$$PaymentImplCopyWithImpl<$Res>
    extends _$PaymentCopyWithImpl<$Res, _$PaymentImpl>
    implements _$$PaymentImplCopyWith<$Res> {
  __$$PaymentImplCopyWithImpl(
      _$PaymentImpl _value, $Res Function(_$PaymentImpl) _then)
      : super(_value, _then);

  /// Create a copy of Payment
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? totalAmount = freezed,
    Object? advanceAmount = freezed,
    Object? balance = freezed,
    Object? confirmedAt = freezed,
  }) {
    return _then(_$PaymentImpl(
      totalAmount: freezed == totalAmount
          ? _value.totalAmount
          : totalAmount // ignore: cast_nullable_to_non_nullable
              as int?,
      advanceAmount: freezed == advanceAmount
          ? _value.advanceAmount
          : advanceAmount // ignore: cast_nullable_to_non_nullable
              as int?,
      balance: freezed == balance
          ? _value.balance
          : balance // ignore: cast_nullable_to_non_nullable
              as int?,
      confirmedAt: freezed == confirmedAt
          ? _value.confirmedAt
          : confirmedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$PaymentImpl implements _Payment {
  const _$PaymentImpl(
      {this.totalAmount, this.advanceAmount, this.balance, this.confirmedAt});

  factory _$PaymentImpl.fromJson(Map<String, dynamic> json) =>
      _$$PaymentImplFromJson(json);

  @override
  final int? totalAmount;
  @override
  final int? advanceAmount;
  @override
  final int? balance;
  @override
  final DateTime? confirmedAt;

  @override
  String toString() {
    return 'Payment(totalAmount: $totalAmount, advanceAmount: $advanceAmount, balance: $balance, confirmedAt: $confirmedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PaymentImpl &&
            (identical(other.totalAmount, totalAmount) ||
                other.totalAmount == totalAmount) &&
            (identical(other.advanceAmount, advanceAmount) ||
                other.advanceAmount == advanceAmount) &&
            (identical(other.balance, balance) || other.balance == balance) &&
            (identical(other.confirmedAt, confirmedAt) ||
                other.confirmedAt == confirmedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType, totalAmount, advanceAmount, balance, confirmedAt);

  /// Create a copy of Payment
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PaymentImplCopyWith<_$PaymentImpl> get copyWith =>
      __$$PaymentImplCopyWithImpl<_$PaymentImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PaymentImplToJson(
      this,
    );
  }
}

abstract class _Payment implements Payment {
  const factory _Payment(
      {final int? totalAmount,
      final int? advanceAmount,
      final int? balance,
      final DateTime? confirmedAt}) = _$PaymentImpl;

  factory _Payment.fromJson(Map<String, dynamic> json) = _$PaymentImpl.fromJson;

  @override
  int? get totalAmount;
  @override
  int? get advanceAmount;
  @override
  int? get balance;
  @override
  DateTime? get confirmedAt;

  /// Create a copy of Payment
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PaymentImplCopyWith<_$PaymentImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

Enquiry _$EnquiryFromJson(Map<String, dynamic> json) {
  return _Enquiry.fromJson(json);
}

/// @nodoc
mixin _$Enquiry {
  String get id => throw _privateConstructorUsedError;
  String get customerName => throw _privateConstructorUsedError;
  String get customerPhone => throw _privateConstructorUsedError;
  String? get customerEmail => throw _privateConstructorUsedError;
  String get eventTypeId => throw _privateConstructorUsedError;
  String get eventTypeLabel => throw _privateConstructorUsedError;
  DateTime get eventDate => throw _privateConstructorUsedError;
  String get locationText => throw _privateConstructorUsedError;
  int? get guestCount => throw _privateConstructorUsedError;
  BudgetRange? get budgetRange => throw _privateConstructorUsedError;
  EnquiryStatus get status => throw _privateConstructorUsedError;
  String get createdByUid => throw _privateConstructorUsedError;
  String? get assignedToUid => throw _privateConstructorUsedError;
  DateTime? get assignedAt => throw _privateConstructorUsedError;
  Payment? get payment => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;
  DateTime get updatedAt => throw _privateConstructorUsedError;

  /// Serializes this Enquiry to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Enquiry
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $EnquiryCopyWith<Enquiry> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $EnquiryCopyWith<$Res> {
  factory $EnquiryCopyWith(Enquiry value, $Res Function(Enquiry) then) =
      _$EnquiryCopyWithImpl<$Res, Enquiry>;
  @useResult
  $Res call(
      {String id,
      String customerName,
      String customerPhone,
      String? customerEmail,
      String eventTypeId,
      String eventTypeLabel,
      DateTime eventDate,
      String locationText,
      int? guestCount,
      BudgetRange? budgetRange,
      EnquiryStatus status,
      String createdByUid,
      String? assignedToUid,
      DateTime? assignedAt,
      Payment? payment,
      DateTime createdAt,
      DateTime updatedAt});

  $BudgetRangeCopyWith<$Res>? get budgetRange;
  $PaymentCopyWith<$Res>? get payment;
}

/// @nodoc
class _$EnquiryCopyWithImpl<$Res, $Val extends Enquiry>
    implements $EnquiryCopyWith<$Res> {
  _$EnquiryCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Enquiry
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? customerName = null,
    Object? customerPhone = null,
    Object? customerEmail = freezed,
    Object? eventTypeId = null,
    Object? eventTypeLabel = null,
    Object? eventDate = null,
    Object? locationText = null,
    Object? guestCount = freezed,
    Object? budgetRange = freezed,
    Object? status = null,
    Object? createdByUid = null,
    Object? assignedToUid = freezed,
    Object? assignedAt = freezed,
    Object? payment = freezed,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      customerName: null == customerName
          ? _value.customerName
          : customerName // ignore: cast_nullable_to_non_nullable
              as String,
      customerPhone: null == customerPhone
          ? _value.customerPhone
          : customerPhone // ignore: cast_nullable_to_non_nullable
              as String,
      customerEmail: freezed == customerEmail
          ? _value.customerEmail
          : customerEmail // ignore: cast_nullable_to_non_nullable
              as String?,
      eventTypeId: null == eventTypeId
          ? _value.eventTypeId
          : eventTypeId // ignore: cast_nullable_to_non_nullable
              as String,
      eventTypeLabel: null == eventTypeLabel
          ? _value.eventTypeLabel
          : eventTypeLabel // ignore: cast_nullable_to_non_nullable
              as String,
      eventDate: null == eventDate
          ? _value.eventDate
          : eventDate // ignore: cast_nullable_to_non_nullable
              as DateTime,
      locationText: null == locationText
          ? _value.locationText
          : locationText // ignore: cast_nullable_to_non_nullable
              as String,
      guestCount: freezed == guestCount
          ? _value.guestCount
          : guestCount // ignore: cast_nullable_to_non_nullable
              as int?,
      budgetRange: freezed == budgetRange
          ? _value.budgetRange
          : budgetRange // ignore: cast_nullable_to_non_nullable
              as BudgetRange?,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as EnquiryStatus,
      createdByUid: null == createdByUid
          ? _value.createdByUid
          : createdByUid // ignore: cast_nullable_to_non_nullable
              as String,
      assignedToUid: freezed == assignedToUid
          ? _value.assignedToUid
          : assignedToUid // ignore: cast_nullable_to_non_nullable
              as String?,
      assignedAt: freezed == assignedAt
          ? _value.assignedAt
          : assignedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      payment: freezed == payment
          ? _value.payment
          : payment // ignore: cast_nullable_to_non_nullable
              as Payment?,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updatedAt: null == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ) as $Val);
  }

  /// Create a copy of Enquiry
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $BudgetRangeCopyWith<$Res>? get budgetRange {
    if (_value.budgetRange == null) {
      return null;
    }

    return $BudgetRangeCopyWith<$Res>(_value.budgetRange!, (value) {
      return _then(_value.copyWith(budgetRange: value) as $Val);
    });
  }

  /// Create a copy of Enquiry
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $PaymentCopyWith<$Res>? get payment {
    if (_value.payment == null) {
      return null;
    }

    return $PaymentCopyWith<$Res>(_value.payment!, (value) {
      return _then(_value.copyWith(payment: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$EnquiryImplCopyWith<$Res> implements $EnquiryCopyWith<$Res> {
  factory _$$EnquiryImplCopyWith(
          _$EnquiryImpl value, $Res Function(_$EnquiryImpl) then) =
      __$$EnquiryImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String customerName,
      String customerPhone,
      String? customerEmail,
      String eventTypeId,
      String eventTypeLabel,
      DateTime eventDate,
      String locationText,
      int? guestCount,
      BudgetRange? budgetRange,
      EnquiryStatus status,
      String createdByUid,
      String? assignedToUid,
      DateTime? assignedAt,
      Payment? payment,
      DateTime createdAt,
      DateTime updatedAt});

  @override
  $BudgetRangeCopyWith<$Res>? get budgetRange;
  @override
  $PaymentCopyWith<$Res>? get payment;
}

/// @nodoc
class __$$EnquiryImplCopyWithImpl<$Res>
    extends _$EnquiryCopyWithImpl<$Res, _$EnquiryImpl>
    implements _$$EnquiryImplCopyWith<$Res> {
  __$$EnquiryImplCopyWithImpl(
      _$EnquiryImpl _value, $Res Function(_$EnquiryImpl) _then)
      : super(_value, _then);

  /// Create a copy of Enquiry
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? customerName = null,
    Object? customerPhone = null,
    Object? customerEmail = freezed,
    Object? eventTypeId = null,
    Object? eventTypeLabel = null,
    Object? eventDate = null,
    Object? locationText = null,
    Object? guestCount = freezed,
    Object? budgetRange = freezed,
    Object? status = null,
    Object? createdByUid = null,
    Object? assignedToUid = freezed,
    Object? assignedAt = freezed,
    Object? payment = freezed,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(_$EnquiryImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      customerName: null == customerName
          ? _value.customerName
          : customerName // ignore: cast_nullable_to_non_nullable
              as String,
      customerPhone: null == customerPhone
          ? _value.customerPhone
          : customerPhone // ignore: cast_nullable_to_non_nullable
              as String,
      customerEmail: freezed == customerEmail
          ? _value.customerEmail
          : customerEmail // ignore: cast_nullable_to_non_nullable
              as String?,
      eventTypeId: null == eventTypeId
          ? _value.eventTypeId
          : eventTypeId // ignore: cast_nullable_to_non_nullable
              as String,
      eventTypeLabel: null == eventTypeLabel
          ? _value.eventTypeLabel
          : eventTypeLabel // ignore: cast_nullable_to_non_nullable
              as String,
      eventDate: null == eventDate
          ? _value.eventDate
          : eventDate // ignore: cast_nullable_to_non_nullable
              as DateTime,
      locationText: null == locationText
          ? _value.locationText
          : locationText // ignore: cast_nullable_to_non_nullable
              as String,
      guestCount: freezed == guestCount
          ? _value.guestCount
          : guestCount // ignore: cast_nullable_to_non_nullable
              as int?,
      budgetRange: freezed == budgetRange
          ? _value.budgetRange
          : budgetRange // ignore: cast_nullable_to_non_nullable
              as BudgetRange?,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as EnquiryStatus,
      createdByUid: null == createdByUid
          ? _value.createdByUid
          : createdByUid // ignore: cast_nullable_to_non_nullable
              as String,
      assignedToUid: freezed == assignedToUid
          ? _value.assignedToUid
          : assignedToUid // ignore: cast_nullable_to_non_nullable
              as String?,
      assignedAt: freezed == assignedAt
          ? _value.assignedAt
          : assignedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      payment: freezed == payment
          ? _value.payment
          : payment // ignore: cast_nullable_to_non_nullable
              as Payment?,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updatedAt: null == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$EnquiryImpl implements _Enquiry {
  const _$EnquiryImpl(
      {required this.id,
      required this.customerName,
      required this.customerPhone,
      this.customerEmail,
      required this.eventTypeId,
      required this.eventTypeLabel,
      required this.eventDate,
      required this.locationText,
      this.guestCount,
      this.budgetRange,
      required this.status,
      required this.createdByUid,
      this.assignedToUid,
      this.assignedAt,
      this.payment,
      required this.createdAt,
      required this.updatedAt});

  factory _$EnquiryImpl.fromJson(Map<String, dynamic> json) =>
      _$$EnquiryImplFromJson(json);

  @override
  final String id;
  @override
  final String customerName;
  @override
  final String customerPhone;
  @override
  final String? customerEmail;
  @override
  final String eventTypeId;
  @override
  final String eventTypeLabel;
  @override
  final DateTime eventDate;
  @override
  final String locationText;
  @override
  final int? guestCount;
  @override
  final BudgetRange? budgetRange;
  @override
  final EnquiryStatus status;
  @override
  final String createdByUid;
  @override
  final String? assignedToUid;
  @override
  final DateTime? assignedAt;
  @override
  final Payment? payment;
  @override
  final DateTime createdAt;
  @override
  final DateTime updatedAt;

  @override
  String toString() {
    return 'Enquiry(id: $id, customerName: $customerName, customerPhone: $customerPhone, customerEmail: $customerEmail, eventTypeId: $eventTypeId, eventTypeLabel: $eventTypeLabel, eventDate: $eventDate, locationText: $locationText, guestCount: $guestCount, budgetRange: $budgetRange, status: $status, createdByUid: $createdByUid, assignedToUid: $assignedToUid, assignedAt: $assignedAt, payment: $payment, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$EnquiryImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.customerName, customerName) ||
                other.customerName == customerName) &&
            (identical(other.customerPhone, customerPhone) ||
                other.customerPhone == customerPhone) &&
            (identical(other.customerEmail, customerEmail) ||
                other.customerEmail == customerEmail) &&
            (identical(other.eventTypeId, eventTypeId) ||
                other.eventTypeId == eventTypeId) &&
            (identical(other.eventTypeLabel, eventTypeLabel) ||
                other.eventTypeLabel == eventTypeLabel) &&
            (identical(other.eventDate, eventDate) ||
                other.eventDate == eventDate) &&
            (identical(other.locationText, locationText) ||
                other.locationText == locationText) &&
            (identical(other.guestCount, guestCount) ||
                other.guestCount == guestCount) &&
            (identical(other.budgetRange, budgetRange) ||
                other.budgetRange == budgetRange) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.createdByUid, createdByUid) ||
                other.createdByUid == createdByUid) &&
            (identical(other.assignedToUid, assignedToUid) ||
                other.assignedToUid == assignedToUid) &&
            (identical(other.assignedAt, assignedAt) ||
                other.assignedAt == assignedAt) &&
            (identical(other.payment, payment) || other.payment == payment) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      customerName,
      customerPhone,
      customerEmail,
      eventTypeId,
      eventTypeLabel,
      eventDate,
      locationText,
      guestCount,
      budgetRange,
      status,
      createdByUid,
      assignedToUid,
      assignedAt,
      payment,
      createdAt,
      updatedAt);

  /// Create a copy of Enquiry
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$EnquiryImplCopyWith<_$EnquiryImpl> get copyWith =>
      __$$EnquiryImplCopyWithImpl<_$EnquiryImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$EnquiryImplToJson(
      this,
    );
  }
}

abstract class _Enquiry implements Enquiry {
  const factory _Enquiry(
      {required final String id,
      required final String customerName,
      required final String customerPhone,
      final String? customerEmail,
      required final String eventTypeId,
      required final String eventTypeLabel,
      required final DateTime eventDate,
      required final String locationText,
      final int? guestCount,
      final BudgetRange? budgetRange,
      required final EnquiryStatus status,
      required final String createdByUid,
      final String? assignedToUid,
      final DateTime? assignedAt,
      final Payment? payment,
      required final DateTime createdAt,
      required final DateTime updatedAt}) = _$EnquiryImpl;

  factory _Enquiry.fromJson(Map<String, dynamic> json) = _$EnquiryImpl.fromJson;

  @override
  String get id;
  @override
  String get customerName;
  @override
  String get customerPhone;
  @override
  String? get customerEmail;
  @override
  String get eventTypeId;
  @override
  String get eventTypeLabel;
  @override
  DateTime get eventDate;
  @override
  String get locationText;
  @override
  int? get guestCount;
  @override
  BudgetRange? get budgetRange;
  @override
  EnquiryStatus get status;
  @override
  String get createdByUid;
  @override
  String? get assignedToUid;
  @override
  DateTime? get assignedAt;
  @override
  Payment? get payment;
  @override
  DateTime get createdAt;
  @override
  DateTime get updatedAt;

  /// Create a copy of Enquiry
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$EnquiryImplCopyWith<_$EnquiryImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
