// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'enquiry_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$BudgetRangeImpl _$$BudgetRangeImplFromJson(Map<String, dynamic> json) =>
    _$BudgetRangeImpl(
      min: (json['min'] as num?)?.toInt(),
      max: (json['max'] as num?)?.toInt(),
    );

Map<String, dynamic> _$$BudgetRangeImplToJson(_$BudgetRangeImpl instance) =>
    <String, dynamic>{
      'min': instance.min,
      'max': instance.max,
    };

_$PaymentImpl _$$PaymentImplFromJson(Map<String, dynamic> json) =>
    _$PaymentImpl(
      totalAmount: (json['totalAmount'] as num?)?.toInt(),
      advanceAmount: (json['advanceAmount'] as num?)?.toInt(),
      balance: (json['balance'] as num?)?.toInt(),
      confirmedAt: json['confirmedAt'] == null
          ? null
          : DateTime.parse(json['confirmedAt'] as String),
    );

Map<String, dynamic> _$$PaymentImplToJson(_$PaymentImpl instance) =>
    <String, dynamic>{
      'totalAmount': instance.totalAmount,
      'advanceAmount': instance.advanceAmount,
      'balance': instance.balance,
      'confirmedAt': instance.confirmedAt?.toIso8601String(),
    };

_$EnquiryImpl _$$EnquiryImplFromJson(Map<String, dynamic> json) =>
    _$EnquiryImpl(
      id: json['id'] as String,
      customerName: json['customerName'] as String,
      customerPhone: json['customerPhone'] as String,
      customerEmail: json['customerEmail'] as String?,
      eventTypeId: json['eventTypeId'] as String,
      eventTypeLabel: json['eventTypeLabel'] as String,
      eventDate: DateTime.parse(json['eventDate'] as String),
      locationText: json['locationText'] as String,
      guestCount: (json['guestCount'] as num?)?.toInt(),
      budgetRange: json['budgetRange'] == null
          ? null
          : BudgetRange.fromJson(json['budgetRange'] as Map<String, dynamic>),
      status: $enumDecode(_$EnquiryStatusEnumMap, json['status']),
      createdByUid: json['createdByUid'] as String,
      assignedToUid: json['assignedToUid'] as String?,
      assignedAt: json['assignedAt'] == null
          ? null
          : DateTime.parse(json['assignedAt'] as String),
      payment: json['payment'] == null
          ? null
          : Payment.fromJson(json['payment'] as Map<String, dynamic>),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$$EnquiryImplToJson(_$EnquiryImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'customerName': instance.customerName,
      'customerPhone': instance.customerPhone,
      'customerEmail': instance.customerEmail,
      'eventTypeId': instance.eventTypeId,
      'eventTypeLabel': instance.eventTypeLabel,
      'eventDate': instance.eventDate.toIso8601String(),
      'locationText': instance.locationText,
      'guestCount': instance.guestCount,
      'budgetRange': instance.budgetRange,
      'status': _$EnquiryStatusEnumMap[instance.status]!,
      'createdByUid': instance.createdByUid,
      'assignedToUid': instance.assignedToUid,
      'assignedAt': instance.assignedAt?.toIso8601String(),
      'payment': instance.payment,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
    };

const _$EnquiryStatusEnumMap = {
  EnquiryStatus.enquired: 'enquired',
  EnquiryStatus.inTalks: 'inTalks',
  EnquiryStatus.confirmed: 'confirmed',
  EnquiryStatus.notInterested: 'notInterested',
  EnquiryStatus.completed: 'completed',
};
