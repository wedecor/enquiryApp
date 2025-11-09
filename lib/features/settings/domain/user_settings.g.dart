// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_settings.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$UserSettingsImpl _$$UserSettingsImplFromJson(Map<String, dynamic> json) =>
    _$UserSettingsImpl(
      theme: json['theme'] as String? ?? 'system',
      language: json['language'] as String? ?? 'en',
      timezone: json['timezone'] as String? ?? 'Asia/Kolkata',
      dashboard: json['dashboard'] == null
          ? const DashboardSettings()
          : DashboardSettings.fromJson(
              json['dashboard'] as Map<String, dynamic>),
      notifications: json['notifications'] == null
          ? const NotificationSettings()
          : NotificationSettings.fromJson(
              json['notifications'] as Map<String, dynamic>),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$$UserSettingsImplToJson(_$UserSettingsImpl instance) =>
    <String, dynamic>{
      'theme': instance.theme,
      'language': instance.language,
      'timezone': instance.timezone,
      'dashboard': instance.dashboard,
      'notifications': instance.notifications,
      'updatedAt': instance.updatedAt?.toIso8601String(),
    };

_$DashboardSettingsImpl _$$DashboardSettingsImplFromJson(
        Map<String, dynamic> json) =>
    _$DashboardSettingsImpl(
      dateRange: json['dateRange'] as String? ?? '30d',
      statusTabs: (json['statusTabs'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const ['new', 'in_talks', 'quote_sent'],
      columns: (json['columns'] as List<dynamic>?)
              ?.map((e) => ColumnSettings.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [
            ColumnSettings(id: 'customer', visible: true, order: 0),
            ColumnSettings(id: 'eventType', visible: true, order: 1),
            ColumnSettings(id: 'status', visible: true, order: 2),
            ColumnSettings(id: 'priority', visible: true, order: 3),
            ColumnSettings(id: 'createdAt', visible: true, order: 4)
          ],
    );

Map<String, dynamic> _$$DashboardSettingsImplToJson(
        _$DashboardSettingsImpl instance) =>
    <String, dynamic>{
      'dateRange': instance.dateRange,
      'statusTabs': instance.statusTabs,
      'columns': instance.columns,
    };

_$ColumnSettingsImpl _$$ColumnSettingsImplFromJson(Map<String, dynamic> json) =>
    _$ColumnSettingsImpl(
      id: json['id'] as String,
      visible: json['visible'] as bool? ?? true,
      order: (json['order'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$$ColumnSettingsImplToJson(
        _$ColumnSettingsImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'visible': instance.visible,
      'order': instance.order,
    };

_$NotificationSettingsImpl _$$NotificationSettingsImplFromJson(
        Map<String, dynamic> json) =>
    _$NotificationSettingsImpl(
      pushEnabled: json['pushEnabled'] as bool? ?? true,
      emailEnabled: json['emailEnabled'] as bool? ?? false,
      channels: json['channels'] == null
          ? const NotificationChannels()
          : NotificationChannels.fromJson(
              json['channels'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$$NotificationSettingsImplToJson(
        _$NotificationSettingsImpl instance) =>
    <String, dynamic>{
      'pushEnabled': instance.pushEnabled,
      'emailEnabled': instance.emailEnabled,
      'channels': instance.channels,
    };

_$NotificationChannelsImpl _$$NotificationChannelsImplFromJson(
        Map<String, dynamic> json) =>
    _$NotificationChannelsImpl(
      assignment: json['assignment'] as bool? ?? true,
      statusChange: json['statusChange'] as bool? ?? true,
      payment: json['payment'] as bool? ?? true,
      reminders: json['reminders'] as bool? ?? true,
    );

Map<String, dynamic> _$$NotificationChannelsImplToJson(
        _$NotificationChannelsImpl instance) =>
    <String, dynamic>{
      'assignment': instance.assignment,
      'statusChange': instance.statusChange,
      'payment': instance.payment,
      'reminders': instance.reminders,
    };
