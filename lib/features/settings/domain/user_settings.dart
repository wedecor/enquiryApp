import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_settings.freezed.dart';
part 'user_settings.g.dart';

@freezed
class UserSettings with _$UserSettings {
  const factory UserSettings({
    @Default('system') String theme,
    @Default('en') String language,
    @Default('Asia/Kolkata') String timezone,
    @Default(DashboardSettings()) DashboardSettings dashboard,
    @Default(NotificationSettings()) NotificationSettings notifications,
    DateTime? updatedAt,
  }) = _UserSettings;

  factory UserSettings.fromJson(Map<String, dynamic> json) => _$UserSettingsFromJson(json);

  factory UserSettings.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    if (data == null) return const UserSettings();

    return UserSettings.fromJson({
      ...data,
      'updatedAt': (data['updatedAt'] as Timestamp?)?.toDate(),
    });
  }
}

extension UserSettingsFirestore on UserSettings {
  Map<String, dynamic> toFirestore() {
    final json = toJson();
    json['updatedAt'] = FieldValue.serverTimestamp();
    return json;
  }
}

@freezed
class DashboardSettings with _$DashboardSettings {
  const factory DashboardSettings({
    @Default('30d') String dateRange,
    @Default(['new', 'in_talks', 'quotation_sent']) List<String> statusTabs,
    @Default([
      ColumnSettings(id: 'customer', visible: true, order: 0),
      ColumnSettings(id: 'eventType', visible: true, order: 1),
      ColumnSettings(id: 'status', visible: true, order: 2),
      ColumnSettings(id: 'priority', visible: true, order: 3),
      ColumnSettings(id: 'createdAt', visible: true, order: 4),
    ])
    List<ColumnSettings> columns,
  }) = _DashboardSettings;

  factory DashboardSettings.fromJson(Map<String, dynamic> json) =>
      _$DashboardSettingsFromJson(json);
}

@freezed
class ColumnSettings with _$ColumnSettings {
  const factory ColumnSettings({
    required String id,
    @Default(true) bool visible,
    @Default(0) int order,
  }) = _ColumnSettings;

  factory ColumnSettings.fromJson(Map<String, dynamic> json) => _$ColumnSettingsFromJson(json);
}

@freezed
class NotificationSettings with _$NotificationSettings {
  const factory NotificationSettings({
    @Default(true) bool pushEnabled,
    @Default(false) bool emailEnabled,
    @Default(NotificationChannels()) NotificationChannels channels,
  }) = _NotificationSettings;

  factory NotificationSettings.fromJson(Map<String, dynamic> json) =>
      _$NotificationSettingsFromJson(json);
}

@freezed
class NotificationChannels with _$NotificationChannels {
  const factory NotificationChannels({
    @Default(true) bool assignment,
    @Default(true) bool statusChange,
    @Default(true) bool payment,
    @Default(true) bool reminders,
  }) = _NotificationChannels;

  factory NotificationChannels.fromJson(Map<String, dynamic> json) =>
      _$NotificationChannelsFromJson(json);
}
