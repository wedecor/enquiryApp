// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_notification.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$AppNotificationImpl _$$AppNotificationImplFromJson(Map<String, dynamic> json) =>
    _$AppNotificationImpl(
      id: json['id'] as String,
      type: $enumDecode(_$NotificationTypeEnumMap, json['type']),
      title: json['title'] as String,
      body: json['body'] as String,
      enquiryId: json['enquiryId'] as String?,
      userId: json['userId'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      read: json['read'] as bool? ?? false,
      archived: json['archived'] as bool? ?? false,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$$AppNotificationImplToJson(_$AppNotificationImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': _$NotificationTypeEnumMap[instance.type]!,
      'title': instance.title,
      'body': instance.body,
      'enquiryId': instance.enquiryId,
      'userId': instance.userId,
      'createdAt': instance.createdAt.toIso8601String(),
      'read': instance.read,
      'archived': instance.archived,
      'metadata': instance.metadata,
    };

const _$NotificationTypeEnumMap = {
  NotificationType.enquiryUpdate: 'enquiryUpdate',
  NotificationType.newEnquiry: 'newEnquiry',
  NotificationType.assignment: 'assignment',
  NotificationType.statusChange: 'statusChange',
  NotificationType.paymentUpdate: 'paymentUpdate',
};
