import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'app_config.freezed.dart';
part 'app_config.g.dart';

@freezed
class AppGeneralConfig with _$AppGeneralConfig {
  const factory AppGeneralConfig({
    @Default('WeDecor Events') String companyName,
    String? logoUrl,
    @Default('INR') String currency,
    @Default('Asia/Kolkata') String timezone,
    @Default(18.0) double vatPercent,
    DateTime? updatedAt,
  }) = _AppGeneralConfig;

  factory AppGeneralConfig.fromJson(Map<String, dynamic> json) => _$AppGeneralConfigFromJson(json);

  factory AppGeneralConfig.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    if (data == null) return const AppGeneralConfig();

    return AppGeneralConfig.fromJson({
      ...data,
      'updatedAt': (data['updatedAt'] as Timestamp?)?.toDate(),
    });
  }
}

extension AppGeneralConfigFirestore on AppGeneralConfig {
  Map<String, dynamic> toFirestore() {
    final json = toJson();
    json['updatedAt'] = FieldValue.serverTimestamp();
    return json;
  }
}

@freezed
class AppNotificationConfig with _$AppNotificationConfig {
  const factory AppNotificationConfig({
    @Default(true) bool emailInvitesEnabled,
    @Default('connect2wedecor@gmail.com') String replyToEmail,
    @Default(3) int reminderDaysDefault,
    DateTime? updatedAt,
  }) = _AppNotificationConfig;

  factory AppNotificationConfig.fromJson(Map<String, dynamic> json) =>
      _$AppNotificationConfigFromJson(json);

  factory AppNotificationConfig.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    if (data == null) return const AppNotificationConfig();

    return AppNotificationConfig.fromJson({
      ...data,
      'updatedAt': (data['updatedAt'] as Timestamp?)?.toDate(),
    });
  }
}

extension AppNotificationConfigFirestore on AppNotificationConfig {
  Map<String, dynamic> toFirestore() {
    final json = toJson();
    json['updatedAt'] = FieldValue.serverTimestamp();
    return json;
  }
}

@freezed
class AppSecurityConfig with _$AppSecurityConfig {
  const factory AppSecurityConfig({
    @Default(['wedecor.com']) List<String> allowedDomains,
    @Default(false) bool requireFirstLoginReset,
    DateTime? updatedAt,
  }) = _AppSecurityConfig;

  factory AppSecurityConfig.fromJson(Map<String, dynamic> json) =>
      _$AppSecurityConfigFromJson(json);

  factory AppSecurityConfig.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    if (data == null) return const AppSecurityConfig();

    return AppSecurityConfig.fromJson({
      ...data,
      'updatedAt': (data['updatedAt'] as Timestamp?)?.toDate(),
    });
  }
}

extension AppSecurityConfigFirestore on AppSecurityConfig {
  Map<String, dynamic> toFirestore() {
    final json = toJson();
    json['updatedAt'] = FieldValue.serverTimestamp();
    return json;
  }
}

