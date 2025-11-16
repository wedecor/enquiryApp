// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_config.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$AppGeneralConfigImpl _$$AppGeneralConfigImplFromJson(Map<String, dynamic> json) =>
    _$AppGeneralConfigImpl(
      companyName: json['companyName'] as String? ?? 'WeDecor Events',
      logoUrl: json['logoUrl'] as String?,
      currency: json['currency'] as String? ?? 'INR',
      timezone: json['timezone'] as String? ?? 'Asia/Kolkata',
      vatPercent: (json['vatPercent'] as num?)?.toDouble() ?? 18.0,
      googleReviewLink:
          json['googleReviewLink'] as String? ?? 'https://share.google/qba1n2A4MKJiUy3PA',
      instagramHandle: json['instagramHandle'] as String? ?? '@wedecorbangalore',
      websiteUrl: json['websiteUrl'] as String? ?? 'https://www.wedecorevents.com/',
      updatedAt: json['updatedAt'] == null ? null : DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$$AppGeneralConfigImplToJson(_$AppGeneralConfigImpl instance) =>
    <String, dynamic>{
      'companyName': instance.companyName,
      'logoUrl': instance.logoUrl,
      'currency': instance.currency,
      'timezone': instance.timezone,
      'vatPercent': instance.vatPercent,
      'googleReviewLink': instance.googleReviewLink,
      'instagramHandle': instance.instagramHandle,
      'websiteUrl': instance.websiteUrl,
      'updatedAt': instance.updatedAt?.toIso8601String(),
    };

_$AppNotificationConfigImpl _$$AppNotificationConfigImplFromJson(Map<String, dynamic> json) =>
    _$AppNotificationConfigImpl(
      emailInvitesEnabled: json['emailInvitesEnabled'] as bool? ?? true,
      replyToEmail: json['replyToEmail'] as String? ?? 'connect2wedecor@gmail.com',
      reminderDaysDefault: (json['reminderDaysDefault'] as num?)?.toInt() ?? 3,
      updatedAt: json['updatedAt'] == null ? null : DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$$AppNotificationConfigImplToJson(_$AppNotificationConfigImpl instance) =>
    <String, dynamic>{
      'emailInvitesEnabled': instance.emailInvitesEnabled,
      'replyToEmail': instance.replyToEmail,
      'reminderDaysDefault': instance.reminderDaysDefault,
      'updatedAt': instance.updatedAt?.toIso8601String(),
    };

_$AppSecurityConfigImpl _$$AppSecurityConfigImplFromJson(Map<String, dynamic> json) =>
    _$AppSecurityConfigImpl(
      allowedDomains:
          (json['allowedDomains'] as List<dynamic>?)?.map((e) => e as String).toList() ??
          const ['wedecor.com'],
      requireFirstLoginReset: json['requireFirstLoginReset'] as bool? ?? false,
      updatedAt: json['updatedAt'] == null ? null : DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$$AppSecurityConfigImplToJson(_$AppSecurityConfigImpl instance) =>
    <String, dynamic>{
      'allowedDomains': instance.allowedDomains,
      'requireFirstLoginReset': instance.requireFirstLoginReset,
      'updatedAt': instance.updatedAt?.toIso8601String(),
    };
