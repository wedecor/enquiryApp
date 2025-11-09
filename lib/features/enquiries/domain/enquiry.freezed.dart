// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'enquiry.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

Enquiry _$EnquiryFromJson(Map<String, dynamic> json) {
  return _Enquiry.fromJson(json);
}

/// @nodoc
mixin _$Enquiry {
  String get id => throw _privateConstructorUsedError;
  String get customerName => throw _privateConstructorUsedError;
  String? get customerEmail => throw _privateConstructorUsedError;
  String? get customerPhone => throw _privateConstructorUsedError;
  @JsonKey(name: 'eventTypeValue')
  String get eventType => throw _privateConstructorUsedError;
  String? get eventTypeLabel => throw _privateConstructorUsedError;
  DateTime get eventDate => throw _privateConstructorUsedError;
  String? get eventLocation => throw _privateConstructorUsedError;
  int? get guestCount => throw _privateConstructorUsedError;
  String? get budgetRange => throw _privateConstructorUsedError;
  String? get description => throw _privateConstructorUsedError;
  @JsonKey(name: 'statusValue')
  String get status => throw _privateConstructorUsedError;
  String? get statusLabel => throw _privateConstructorUsedError;
  @JsonKey(name: 'paymentStatusValue')
  String? get paymentStatus => throw _privateConstructorUsedError;
  String? get paymentStatusLabel => throw _privateConstructorUsedError;
  double? get totalCost => throw _privateConstructorUsedError;
  double? get advancePaid => throw _privateConstructorUsedError;
  String? get assignedTo => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;
  DateTime? get updatedAt => throw _privateConstructorUsedError;
  String? get createdBy => throw _privateConstructorUsedError;
  @JsonKey(name: 'priorityValue')
  String? get priority => throw _privateConstructorUsedError;
  String? get priorityLabel => throw _privateConstructorUsedError;
  @JsonKey(name: 'sourceValue')
  String? get source => throw _privateConstructorUsedError;
  String? get sourceLabel => throw _privateConstructorUsedError;
  String? get notes =>
      throw _privateConstructorUsedError; // New denormalized and search fields (optional for back-compat)
  String? get customerNameLower => throw _privateConstructorUsedError;
  String? get phoneNormalized => throw _privateConstructorUsedError;
  String? get assigneeName => throw _privateConstructorUsedError;
  String? get createdByName => throw _privateConstructorUsedError;
  DateTime? get statusUpdatedAt => throw _privateConstructorUsedError;
  String? get statusUpdatedBy => throw _privateConstructorUsedError;
  String? get textIndex => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
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
      String? customerEmail,
      String? customerPhone,
      @JsonKey(name: 'eventTypeValue') String eventType,
      String? eventTypeLabel,
      DateTime eventDate,
      String? eventLocation,
      int? guestCount,
      String? budgetRange,
      String? description,
      @JsonKey(name: 'statusValue') String status,
      String? statusLabel,
      @JsonKey(name: 'paymentStatusValue') String? paymentStatus,
      String? paymentStatusLabel,
      double? totalCost,
      double? advancePaid,
      String? assignedTo,
      DateTime createdAt,
      DateTime? updatedAt,
      String? createdBy,
      @JsonKey(name: 'priorityValue') String? priority,
      String? priorityLabel,
      @JsonKey(name: 'sourceValue') String? source,
      String? sourceLabel,
      String? notes,
      String? customerNameLower,
      String? phoneNormalized,
      String? assigneeName,
      String? createdByName,
      DateTime? statusUpdatedAt,
      String? statusUpdatedBy,
      String? textIndex});
}

/// @nodoc
class _$EnquiryCopyWithImpl<$Res, $Val extends Enquiry>
    implements $EnquiryCopyWith<$Res> {
  _$EnquiryCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? customerName = null,
    Object? customerEmail = freezed,
    Object? customerPhone = freezed,
    Object? eventType = null,
    Object? eventTypeLabel = freezed,
    Object? eventDate = null,
    Object? eventLocation = freezed,
    Object? guestCount = freezed,
    Object? budgetRange = freezed,
    Object? description = freezed,
    Object? status = null,
    Object? statusLabel = freezed,
    Object? paymentStatus = freezed,
    Object? paymentStatusLabel = freezed,
    Object? totalCost = freezed,
    Object? advancePaid = freezed,
    Object? assignedTo = freezed,
    Object? createdAt = null,
    Object? updatedAt = freezed,
    Object? createdBy = freezed,
    Object? priority = freezed,
    Object? priorityLabel = freezed,
    Object? source = freezed,
    Object? sourceLabel = freezed,
    Object? notes = freezed,
    Object? customerNameLower = freezed,
    Object? phoneNormalized = freezed,
    Object? assigneeName = freezed,
    Object? createdByName = freezed,
    Object? statusUpdatedAt = freezed,
    Object? statusUpdatedBy = freezed,
    Object? textIndex = freezed,
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
      customerEmail: freezed == customerEmail
          ? _value.customerEmail
          : customerEmail // ignore: cast_nullable_to_non_nullable
              as String?,
      customerPhone: freezed == customerPhone
          ? _value.customerPhone
          : customerPhone // ignore: cast_nullable_to_non_nullable
              as String?,
      eventType: null == eventType
          ? _value.eventType
          : eventType // ignore: cast_nullable_to_non_nullable
              as String,
      eventTypeLabel: freezed == eventTypeLabel
          ? _value.eventTypeLabel
          : eventTypeLabel // ignore: cast_nullable_to_non_nullable
              as String?,
      eventDate: null == eventDate
          ? _value.eventDate
          : eventDate // ignore: cast_nullable_to_non_nullable
              as DateTime,
      eventLocation: freezed == eventLocation
          ? _value.eventLocation
          : eventLocation // ignore: cast_nullable_to_non_nullable
              as String?,
      guestCount: freezed == guestCount
          ? _value.guestCount
          : guestCount // ignore: cast_nullable_to_non_nullable
              as int?,
      budgetRange: freezed == budgetRange
          ? _value.budgetRange
          : budgetRange // ignore: cast_nullable_to_non_nullable
              as String?,
      description: freezed == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      statusLabel: freezed == statusLabel
          ? _value.statusLabel
          : statusLabel // ignore: cast_nullable_to_non_nullable
              as String?,
      paymentStatus: freezed == paymentStatus
          ? _value.paymentStatus
          : paymentStatus // ignore: cast_nullable_to_non_nullable
              as String?,
      paymentStatusLabel: freezed == paymentStatusLabel
          ? _value.paymentStatusLabel
          : paymentStatusLabel // ignore: cast_nullable_to_non_nullable
              as String?,
      totalCost: freezed == totalCost
          ? _value.totalCost
          : totalCost // ignore: cast_nullable_to_non_nullable
              as double?,
      advancePaid: freezed == advancePaid
          ? _value.advancePaid
          : advancePaid // ignore: cast_nullable_to_non_nullable
              as double?,
      assignedTo: freezed == assignedTo
          ? _value.assignedTo
          : assignedTo // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updatedAt: freezed == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      createdBy: freezed == createdBy
          ? _value.createdBy
          : createdBy // ignore: cast_nullable_to_non_nullable
              as String?,
      priority: freezed == priority
          ? _value.priority
          : priority // ignore: cast_nullable_to_non_nullable
              as String?,
      priorityLabel: freezed == priorityLabel
          ? _value.priorityLabel
          : priorityLabel // ignore: cast_nullable_to_non_nullable
              as String?,
      source: freezed == source
          ? _value.source
          : source // ignore: cast_nullable_to_non_nullable
              as String?,
      sourceLabel: freezed == sourceLabel
          ? _value.sourceLabel
          : sourceLabel // ignore: cast_nullable_to_non_nullable
              as String?,
      notes: freezed == notes
          ? _value.notes
          : notes // ignore: cast_nullable_to_non_nullable
              as String?,
      customerNameLower: freezed == customerNameLower
          ? _value.customerNameLower
          : customerNameLower // ignore: cast_nullable_to_non_nullable
              as String?,
      phoneNormalized: freezed == phoneNormalized
          ? _value.phoneNormalized
          : phoneNormalized // ignore: cast_nullable_to_non_nullable
              as String?,
      assigneeName: freezed == assigneeName
          ? _value.assigneeName
          : assigneeName // ignore: cast_nullable_to_non_nullable
              as String?,
      createdByName: freezed == createdByName
          ? _value.createdByName
          : createdByName // ignore: cast_nullable_to_non_nullable
              as String?,
      statusUpdatedAt: freezed == statusUpdatedAt
          ? _value.statusUpdatedAt
          : statusUpdatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      statusUpdatedBy: freezed == statusUpdatedBy
          ? _value.statusUpdatedBy
          : statusUpdatedBy // ignore: cast_nullable_to_non_nullable
              as String?,
      textIndex: freezed == textIndex
          ? _value.textIndex
          : textIndex // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
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
      String? customerEmail,
      String? customerPhone,
      @JsonKey(name: 'eventTypeValue') String eventType,
      String? eventTypeLabel,
      DateTime eventDate,
      String? eventLocation,
      int? guestCount,
      String? budgetRange,
      String? description,
      @JsonKey(name: 'statusValue') String status,
      String? statusLabel,
      @JsonKey(name: 'paymentStatusValue') String? paymentStatus,
      String? paymentStatusLabel,
      double? totalCost,
      double? advancePaid,
      String? assignedTo,
      DateTime createdAt,
      DateTime? updatedAt,
      String? createdBy,
      @JsonKey(name: 'priorityValue') String? priority,
      String? priorityLabel,
      @JsonKey(name: 'sourceValue') String? source,
      String? sourceLabel,
      String? notes,
      String? customerNameLower,
      String? phoneNormalized,
      String? assigneeName,
      String? createdByName,
      DateTime? statusUpdatedAt,
      String? statusUpdatedBy,
      String? textIndex});
}

/// @nodoc
class __$$EnquiryImplCopyWithImpl<$Res>
    extends _$EnquiryCopyWithImpl<$Res, _$EnquiryImpl>
    implements _$$EnquiryImplCopyWith<$Res> {
  __$$EnquiryImplCopyWithImpl(
      _$EnquiryImpl _value, $Res Function(_$EnquiryImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? customerName = null,
    Object? customerEmail = freezed,
    Object? customerPhone = freezed,
    Object? eventType = null,
    Object? eventTypeLabel = freezed,
    Object? eventDate = null,
    Object? eventLocation = freezed,
    Object? guestCount = freezed,
    Object? budgetRange = freezed,
    Object? description = freezed,
    Object? status = null,
    Object? statusLabel = freezed,
    Object? paymentStatus = freezed,
    Object? paymentStatusLabel = freezed,
    Object? totalCost = freezed,
    Object? advancePaid = freezed,
    Object? assignedTo = freezed,
    Object? createdAt = null,
    Object? updatedAt = freezed,
    Object? createdBy = freezed,
    Object? priority = freezed,
    Object? priorityLabel = freezed,
    Object? source = freezed,
    Object? sourceLabel = freezed,
    Object? notes = freezed,
    Object? customerNameLower = freezed,
    Object? phoneNormalized = freezed,
    Object? assigneeName = freezed,
    Object? createdByName = freezed,
    Object? statusUpdatedAt = freezed,
    Object? statusUpdatedBy = freezed,
    Object? textIndex = freezed,
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
      customerEmail: freezed == customerEmail
          ? _value.customerEmail
          : customerEmail // ignore: cast_nullable_to_non_nullable
              as String?,
      customerPhone: freezed == customerPhone
          ? _value.customerPhone
          : customerPhone // ignore: cast_nullable_to_non_nullable
              as String?,
      eventType: null == eventType
          ? _value.eventType
          : eventType // ignore: cast_nullable_to_non_nullable
              as String,
      eventTypeLabel: freezed == eventTypeLabel
          ? _value.eventTypeLabel
          : eventTypeLabel // ignore: cast_nullable_to_non_nullable
              as String?,
      eventDate: null == eventDate
          ? _value.eventDate
          : eventDate // ignore: cast_nullable_to_non_nullable
              as DateTime,
      eventLocation: freezed == eventLocation
          ? _value.eventLocation
          : eventLocation // ignore: cast_nullable_to_non_nullable
              as String?,
      guestCount: freezed == guestCount
          ? _value.guestCount
          : guestCount // ignore: cast_nullable_to_non_nullable
              as int?,
      budgetRange: freezed == budgetRange
          ? _value.budgetRange
          : budgetRange // ignore: cast_nullable_to_non_nullable
              as String?,
      description: freezed == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      statusLabel: freezed == statusLabel
          ? _value.statusLabel
          : statusLabel // ignore: cast_nullable_to_non_nullable
              as String?,
      paymentStatus: freezed == paymentStatus
          ? _value.paymentStatus
          : paymentStatus // ignore: cast_nullable_to_non_nullable
              as String?,
      paymentStatusLabel: freezed == paymentStatusLabel
          ? _value.paymentStatusLabel
          : paymentStatusLabel // ignore: cast_nullable_to_non_nullable
              as String?,
      totalCost: freezed == totalCost
          ? _value.totalCost
          : totalCost // ignore: cast_nullable_to_non_nullable
              as double?,
      advancePaid: freezed == advancePaid
          ? _value.advancePaid
          : advancePaid // ignore: cast_nullable_to_non_nullable
              as double?,
      assignedTo: freezed == assignedTo
          ? _value.assignedTo
          : assignedTo // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updatedAt: freezed == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      createdBy: freezed == createdBy
          ? _value.createdBy
          : createdBy // ignore: cast_nullable_to_non_nullable
              as String?,
      priority: freezed == priority
          ? _value.priority
          : priority // ignore: cast_nullable_to_non_nullable
              as String?,
      priorityLabel: freezed == priorityLabel
          ? _value.priorityLabel
          : priorityLabel // ignore: cast_nullable_to_non_nullable
              as String?,
      source: freezed == source
          ? _value.source
          : source // ignore: cast_nullable_to_non_nullable
              as String?,
      sourceLabel: freezed == sourceLabel
          ? _value.sourceLabel
          : sourceLabel // ignore: cast_nullable_to_non_nullable
              as String?,
      notes: freezed == notes
          ? _value.notes
          : notes // ignore: cast_nullable_to_non_nullable
              as String?,
      customerNameLower: freezed == customerNameLower
          ? _value.customerNameLower
          : customerNameLower // ignore: cast_nullable_to_non_nullable
              as String?,
      phoneNormalized: freezed == phoneNormalized
          ? _value.phoneNormalized
          : phoneNormalized // ignore: cast_nullable_to_non_nullable
              as String?,
      assigneeName: freezed == assigneeName
          ? _value.assigneeName
          : assigneeName // ignore: cast_nullable_to_non_nullable
              as String?,
      createdByName: freezed == createdByName
          ? _value.createdByName
          : createdByName // ignore: cast_nullable_to_non_nullable
              as String?,
      statusUpdatedAt: freezed == statusUpdatedAt
          ? _value.statusUpdatedAt
          : statusUpdatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      statusUpdatedBy: freezed == statusUpdatedBy
          ? _value.statusUpdatedBy
          : statusUpdatedBy // ignore: cast_nullable_to_non_nullable
              as String?,
      textIndex: freezed == textIndex
          ? _value.textIndex
          : textIndex // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$EnquiryImpl extends _Enquiry {
  const _$EnquiryImpl(
      {required this.id,
      required this.customerName,
      this.customerEmail,
      this.customerPhone,
      @JsonKey(name: 'eventTypeValue') required this.eventType,
      this.eventTypeLabel,
      required this.eventDate,
      this.eventLocation,
      this.guestCount,
      this.budgetRange,
      this.description,
      @JsonKey(name: 'statusValue') this.status = 'new',
      this.statusLabel,
      @JsonKey(name: 'paymentStatusValue') this.paymentStatus,
      this.paymentStatusLabel,
      this.totalCost,
      this.advancePaid,
      this.assignedTo,
      required this.createdAt,
      this.updatedAt,
      this.createdBy,
      @JsonKey(name: 'priorityValue') this.priority,
      this.priorityLabel,
      @JsonKey(name: 'sourceValue') this.source,
      this.sourceLabel,
      this.notes,
      this.customerNameLower,
      this.phoneNormalized,
      this.assigneeName,
      this.createdByName,
      this.statusUpdatedAt,
      this.statusUpdatedBy,
      this.textIndex})
      : super._();

  factory _$EnquiryImpl.fromJson(Map<String, dynamic> json) =>
      _$$EnquiryImplFromJson(json);

  @override
  final String id;
  @override
  final String customerName;
  @override
  final String? customerEmail;
  @override
  final String? customerPhone;
  @override
  @JsonKey(name: 'eventTypeValue')
  final String eventType;
  @override
  final String? eventTypeLabel;
  @override
  final DateTime eventDate;
  @override
  final String? eventLocation;
  @override
  final int? guestCount;
  @override
  final String? budgetRange;
  @override
  final String? description;
  @override
  @JsonKey(name: 'statusValue')
  final String status;
  @override
  final String? statusLabel;
  @override
  @JsonKey(name: 'paymentStatusValue')
  final String? paymentStatus;
  @override
  final String? paymentStatusLabel;
  @override
  final double? totalCost;
  @override
  final double? advancePaid;
  @override
  final String? assignedTo;
  @override
  final DateTime createdAt;
  @override
  final DateTime? updatedAt;
  @override
  final String? createdBy;
  @override
  @JsonKey(name: 'priorityValue')
  final String? priority;
  @override
  final String? priorityLabel;
  @override
  @JsonKey(name: 'sourceValue')
  final String? source;
  @override
  final String? sourceLabel;
  @override
  final String? notes;
// New denormalized and search fields (optional for back-compat)
  @override
  final String? customerNameLower;
  @override
  final String? phoneNormalized;
  @override
  final String? assigneeName;
  @override
  final String? createdByName;
  @override
  final DateTime? statusUpdatedAt;
  @override
  final String? statusUpdatedBy;
  @override
  final String? textIndex;

  @override
  String toString() {
    return 'Enquiry(id: $id, customerName: $customerName, customerEmail: $customerEmail, customerPhone: $customerPhone, eventType: $eventType, eventTypeLabel: $eventTypeLabel, eventDate: $eventDate, eventLocation: $eventLocation, guestCount: $guestCount, budgetRange: $budgetRange, description: $description, status: $status, statusLabel: $statusLabel, paymentStatus: $paymentStatus, paymentStatusLabel: $paymentStatusLabel, totalCost: $totalCost, advancePaid: $advancePaid, assignedTo: $assignedTo, createdAt: $createdAt, updatedAt: $updatedAt, createdBy: $createdBy, priority: $priority, priorityLabel: $priorityLabel, source: $source, sourceLabel: $sourceLabel, notes: $notes, customerNameLower: $customerNameLower, phoneNormalized: $phoneNormalized, assigneeName: $assigneeName, createdByName: $createdByName, statusUpdatedAt: $statusUpdatedAt, statusUpdatedBy: $statusUpdatedBy, textIndex: $textIndex)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$EnquiryImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.customerName, customerName) ||
                other.customerName == customerName) &&
            (identical(other.customerEmail, customerEmail) ||
                other.customerEmail == customerEmail) &&
            (identical(other.customerPhone, customerPhone) ||
                other.customerPhone == customerPhone) &&
            (identical(other.eventType, eventType) ||
                other.eventType == eventType) &&
            (identical(other.eventTypeLabel, eventTypeLabel) ||
                other.eventTypeLabel == eventTypeLabel) &&
            (identical(other.eventDate, eventDate) ||
                other.eventDate == eventDate) &&
            (identical(other.eventLocation, eventLocation) ||
                other.eventLocation == eventLocation) &&
            (identical(other.guestCount, guestCount) ||
                other.guestCount == guestCount) &&
            (identical(other.budgetRange, budgetRange) ||
                other.budgetRange == budgetRange) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.statusLabel, statusLabel) ||
                other.statusLabel == statusLabel) &&
            (identical(other.paymentStatus, paymentStatus) ||
                other.paymentStatus == paymentStatus) &&
            (identical(other.paymentStatusLabel, paymentStatusLabel) ||
                other.paymentStatusLabel == paymentStatusLabel) &&
            (identical(other.totalCost, totalCost) ||
                other.totalCost == totalCost) &&
            (identical(other.advancePaid, advancePaid) ||
                other.advancePaid == advancePaid) &&
            (identical(other.assignedTo, assignedTo) ||
                other.assignedTo == assignedTo) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt) &&
            (identical(other.createdBy, createdBy) ||
                other.createdBy == createdBy) &&
            (identical(other.priority, priority) ||
                other.priority == priority) &&
            (identical(other.priorityLabel, priorityLabel) ||
                other.priorityLabel == priorityLabel) &&
            (identical(other.source, source) || other.source == source) &&
            (identical(other.sourceLabel, sourceLabel) ||
                other.sourceLabel == sourceLabel) &&
            (identical(other.notes, notes) || other.notes == notes) &&
            (identical(other.customerNameLower, customerNameLower) ||
                other.customerNameLower == customerNameLower) &&
            (identical(other.phoneNormalized, phoneNormalized) ||
                other.phoneNormalized == phoneNormalized) &&
            (identical(other.assigneeName, assigneeName) ||
                other.assigneeName == assigneeName) &&
            (identical(other.createdByName, createdByName) ||
                other.createdByName == createdByName) &&
            (identical(other.statusUpdatedAt, statusUpdatedAt) ||
                other.statusUpdatedAt == statusUpdatedAt) &&
            (identical(other.statusUpdatedBy, statusUpdatedBy) ||
                other.statusUpdatedBy == statusUpdatedBy) &&
            (identical(other.textIndex, textIndex) ||
                other.textIndex == textIndex));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hashAll([
        runtimeType,
        id,
        customerName,
        customerEmail,
        customerPhone,
        eventType,
        eventTypeLabel,
        eventDate,
        eventLocation,
        guestCount,
        budgetRange,
        description,
        status,
        statusLabel,
        paymentStatus,
        paymentStatusLabel,
        totalCost,
        advancePaid,
        assignedTo,
        createdAt,
        updatedAt,
        createdBy,
        priority,
        priorityLabel,
        source,
        sourceLabel,
        notes,
        customerNameLower,
        phoneNormalized,
        assigneeName,
        createdByName,
        statusUpdatedAt,
        statusUpdatedBy,
        textIndex
      ]);

  @JsonKey(ignore: true)
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

abstract class _Enquiry extends Enquiry {
  const factory _Enquiry(
      {required final String id,
      required final String customerName,
      final String? customerEmail,
      final String? customerPhone,
      @JsonKey(name: 'eventTypeValue') required final String eventType,
      final String? eventTypeLabel,
      required final DateTime eventDate,
      final String? eventLocation,
      final int? guestCount,
      final String? budgetRange,
      final String? description,
      @JsonKey(name: 'statusValue') final String status,
      final String? statusLabel,
      @JsonKey(name: 'paymentStatusValue') final String? paymentStatus,
      final String? paymentStatusLabel,
      final double? totalCost,
      final double? advancePaid,
      final String? assignedTo,
      required final DateTime createdAt,
      final DateTime? updatedAt,
      final String? createdBy,
      @JsonKey(name: 'priorityValue') final String? priority,
      final String? priorityLabel,
      @JsonKey(name: 'sourceValue') final String? source,
      final String? sourceLabel,
      final String? notes,
      final String? customerNameLower,
      final String? phoneNormalized,
      final String? assigneeName,
      final String? createdByName,
      final DateTime? statusUpdatedAt,
      final String? statusUpdatedBy,
      final String? textIndex}) = _$EnquiryImpl;
  const _Enquiry._() : super._();

  factory _Enquiry.fromJson(Map<String, dynamic> json) = _$EnquiryImpl.fromJson;

  @override
  String get id;
  @override
  String get customerName;
  @override
  String? get customerEmail;
  @override
  String? get customerPhone;
  @override
  @JsonKey(name: 'eventTypeValue')
  String get eventType;
  @override
  String? get eventTypeLabel;
  @override
  DateTime get eventDate;
  @override
  String? get eventLocation;
  @override
  int? get guestCount;
  @override
  String? get budgetRange;
  @override
  String? get description;
  @override
  @JsonKey(name: 'statusValue')
  String get status;
  @override
  String? get statusLabel;
  @override
  @JsonKey(name: 'paymentStatusValue')
  String? get paymentStatus;
  @override
  String? get paymentStatusLabel;
  @override
  double? get totalCost;
  @override
  double? get advancePaid;
  @override
  String? get assignedTo;
  @override
  DateTime get createdAt;
  @override
  DateTime? get updatedAt;
  @override
  String? get createdBy;
  @override
  @JsonKey(name: 'priorityValue')
  String? get priority;
  @override
  String? get priorityLabel;
  @override
  @JsonKey(name: 'sourceValue')
  String? get source;
  @override
  String? get sourceLabel;
  @override
  String? get notes;
  @override // New denormalized and search fields (optional for back-compat)
  String? get customerNameLower;
  @override
  String? get phoneNormalized;
  @override
  String? get assigneeName;
  @override
  String? get createdByName;
  @override
  DateTime? get statusUpdatedAt;
  @override
  String? get statusUpdatedBy;
  @override
  String? get textIndex;
  @override
  @JsonKey(ignore: true)
  _$$EnquiryImplCopyWith<_$EnquiryImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
