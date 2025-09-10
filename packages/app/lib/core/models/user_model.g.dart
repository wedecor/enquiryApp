// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$AppUserImpl _$$AppUserImplFromJson(Map<String, dynamic> json) =>
    _$AppUserImpl(
      uid: json['uid'] as String,
      email: json['email'] as String,
      displayName: json['displayName'] as String?,
      phone: json['phone'] as String?,
      role: $enumDecode(_$AppRoleEnumMap, json['role']),
      isApproved: json['isApproved'] as bool,
      isActive: json['isActive'] as bool,
      fcmTokens: (json['fcmTokens'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const <String>[],
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$$AppUserImplToJson(_$AppUserImpl instance) =>
    <String, dynamic>{
      'uid': instance.uid,
      'email': instance.email,
      'displayName': instance.displayName,
      'phone': instance.phone,
      'role': _$AppRoleEnumMap[instance.role]!,
      'isApproved': instance.isApproved,
      'isActive': instance.isActive,
      'fcmTokens': instance.fcmTokens,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
    };

const _$AppRoleEnumMap = {
  AppRole.admin: 'admin',
  AppRole.partner: 'partner',
  AppRole.staff: 'staff',
  AppRole.pending: 'pending',
};
