// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'user_settings.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

UserSettings _$UserSettingsFromJson(Map<String, dynamic> json) {
  return _UserSettings.fromJson(json);
}

/// @nodoc
mixin _$UserSettings {
  String get theme => throw _privateConstructorUsedError;
  String get language => throw _privateConstructorUsedError;
  String get timezone => throw _privateConstructorUsedError;
  DashboardSettings get dashboard => throw _privateConstructorUsedError;
  NotificationSettings get notifications => throw _privateConstructorUsedError;
  DateTime? get updatedAt => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $UserSettingsCopyWith<UserSettings> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $UserSettingsCopyWith<$Res> {
  factory $UserSettingsCopyWith(UserSettings value, $Res Function(UserSettings) then) =
      _$UserSettingsCopyWithImpl<$Res, UserSettings>;
  @useResult
  $Res call({
    String theme,
    String language,
    String timezone,
    DashboardSettings dashboard,
    NotificationSettings notifications,
    DateTime? updatedAt,
  });

  $DashboardSettingsCopyWith<$Res> get dashboard;
  $NotificationSettingsCopyWith<$Res> get notifications;
}

/// @nodoc
class _$UserSettingsCopyWithImpl<$Res, $Val extends UserSettings>
    implements $UserSettingsCopyWith<$Res> {
  _$UserSettingsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? theme = null,
    Object? language = null,
    Object? timezone = null,
    Object? dashboard = null,
    Object? notifications = null,
    Object? updatedAt = freezed,
  }) {
    return _then(
      _value.copyWith(
            theme: null == theme
                ? _value.theme
                : theme // ignore: cast_nullable_to_non_nullable
                      as String,
            language: null == language
                ? _value.language
                : language // ignore: cast_nullable_to_non_nullable
                      as String,
            timezone: null == timezone
                ? _value.timezone
                : timezone // ignore: cast_nullable_to_non_nullable
                      as String,
            dashboard: null == dashboard
                ? _value.dashboard
                : dashboard // ignore: cast_nullable_to_non_nullable
                      as DashboardSettings,
            notifications: null == notifications
                ? _value.notifications
                : notifications // ignore: cast_nullable_to_non_nullable
                      as NotificationSettings,
            updatedAt: freezed == updatedAt
                ? _value.updatedAt
                : updatedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
          )
          as $Val,
    );
  }

  @override
  @pragma('vm:prefer-inline')
  $DashboardSettingsCopyWith<$Res> get dashboard {
    return $DashboardSettingsCopyWith<$Res>(_value.dashboard, (value) {
      return _then(_value.copyWith(dashboard: value) as $Val);
    });
  }

  @override
  @pragma('vm:prefer-inline')
  $NotificationSettingsCopyWith<$Res> get notifications {
    return $NotificationSettingsCopyWith<$Res>(_value.notifications, (value) {
      return _then(_value.copyWith(notifications: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$UserSettingsImplCopyWith<$Res> implements $UserSettingsCopyWith<$Res> {
  factory _$$UserSettingsImplCopyWith(
    _$UserSettingsImpl value,
    $Res Function(_$UserSettingsImpl) then,
  ) = __$$UserSettingsImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String theme,
    String language,
    String timezone,
    DashboardSettings dashboard,
    NotificationSettings notifications,
    DateTime? updatedAt,
  });

  @override
  $DashboardSettingsCopyWith<$Res> get dashboard;
  @override
  $NotificationSettingsCopyWith<$Res> get notifications;
}

/// @nodoc
class __$$UserSettingsImplCopyWithImpl<$Res>
    extends _$UserSettingsCopyWithImpl<$Res, _$UserSettingsImpl>
    implements _$$UserSettingsImplCopyWith<$Res> {
  __$$UserSettingsImplCopyWithImpl(
    _$UserSettingsImpl _value,
    $Res Function(_$UserSettingsImpl) _then,
  ) : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? theme = null,
    Object? language = null,
    Object? timezone = null,
    Object? dashboard = null,
    Object? notifications = null,
    Object? updatedAt = freezed,
  }) {
    return _then(
      _$UserSettingsImpl(
        theme: null == theme
            ? _value.theme
            : theme // ignore: cast_nullable_to_non_nullable
                  as String,
        language: null == language
            ? _value.language
            : language // ignore: cast_nullable_to_non_nullable
                  as String,
        timezone: null == timezone
            ? _value.timezone
            : timezone // ignore: cast_nullable_to_non_nullable
                  as String,
        dashboard: null == dashboard
            ? _value.dashboard
            : dashboard // ignore: cast_nullable_to_non_nullable
                  as DashboardSettings,
        notifications: null == notifications
            ? _value.notifications
            : notifications // ignore: cast_nullable_to_non_nullable
                  as NotificationSettings,
        updatedAt: freezed == updatedAt
            ? _value.updatedAt
            : updatedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$UserSettingsImpl implements _UserSettings {
  const _$UserSettingsImpl({
    this.theme = 'system',
    this.language = 'en',
    this.timezone = 'Asia/Kolkata',
    this.dashboard = const DashboardSettings(),
    this.notifications = const NotificationSettings(),
    this.updatedAt,
  });

  factory _$UserSettingsImpl.fromJson(Map<String, dynamic> json) =>
      _$$UserSettingsImplFromJson(json);

  @override
  @JsonKey()
  final String theme;
  @override
  @JsonKey()
  final String language;
  @override
  @JsonKey()
  final String timezone;
  @override
  @JsonKey()
  final DashboardSettings dashboard;
  @override
  @JsonKey()
  final NotificationSettings notifications;
  @override
  final DateTime? updatedAt;

  @override
  String toString() {
    return 'UserSettings(theme: $theme, language: $language, timezone: $timezone, dashboard: $dashboard, notifications: $notifications, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UserSettingsImpl &&
            (identical(other.theme, theme) || other.theme == theme) &&
            (identical(other.language, language) || other.language == language) &&
            (identical(other.timezone, timezone) || other.timezone == timezone) &&
            (identical(other.dashboard, dashboard) || other.dashboard == dashboard) &&
            (identical(other.notifications, notifications) ||
                other.notifications == notifications) &&
            (identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode =>
      Object.hash(runtimeType, theme, language, timezone, dashboard, notifications, updatedAt);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$UserSettingsImplCopyWith<_$UserSettingsImpl> get copyWith =>
      __$$UserSettingsImplCopyWithImpl<_$UserSettingsImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$UserSettingsImplToJson(this);
  }
}

abstract class _UserSettings implements UserSettings {
  const factory _UserSettings({
    final String theme,
    final String language,
    final String timezone,
    final DashboardSettings dashboard,
    final NotificationSettings notifications,
    final DateTime? updatedAt,
  }) = _$UserSettingsImpl;

  factory _UserSettings.fromJson(Map<String, dynamic> json) = _$UserSettingsImpl.fromJson;

  @override
  String get theme;
  @override
  String get language;
  @override
  String get timezone;
  @override
  DashboardSettings get dashboard;
  @override
  NotificationSettings get notifications;
  @override
  DateTime? get updatedAt;
  @override
  @JsonKey(ignore: true)
  _$$UserSettingsImplCopyWith<_$UserSettingsImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

DashboardSettings _$DashboardSettingsFromJson(Map<String, dynamic> json) {
  return _DashboardSettings.fromJson(json);
}

/// @nodoc
mixin _$DashboardSettings {
  String get dateRange => throw _privateConstructorUsedError;
  List<String> get statusTabs => throw _privateConstructorUsedError;
  List<ColumnSettings> get columns => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $DashboardSettingsCopyWith<DashboardSettings> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DashboardSettingsCopyWith<$Res> {
  factory $DashboardSettingsCopyWith(
    DashboardSettings value,
    $Res Function(DashboardSettings) then,
  ) = _$DashboardSettingsCopyWithImpl<$Res, DashboardSettings>;
  @useResult
  $Res call({String dateRange, List<String> statusTabs, List<ColumnSettings> columns});
}

/// @nodoc
class _$DashboardSettingsCopyWithImpl<$Res, $Val extends DashboardSettings>
    implements $DashboardSettingsCopyWith<$Res> {
  _$DashboardSettingsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? dateRange = null, Object? statusTabs = null, Object? columns = null}) {
    return _then(
      _value.copyWith(
            dateRange: null == dateRange
                ? _value.dateRange
                : dateRange // ignore: cast_nullable_to_non_nullable
                      as String,
            statusTabs: null == statusTabs
                ? _value.statusTabs
                : statusTabs // ignore: cast_nullable_to_non_nullable
                      as List<String>,
            columns: null == columns
                ? _value.columns
                : columns // ignore: cast_nullable_to_non_nullable
                      as List<ColumnSettings>,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$DashboardSettingsImplCopyWith<$Res> implements $DashboardSettingsCopyWith<$Res> {
  factory _$$DashboardSettingsImplCopyWith(
    _$DashboardSettingsImpl value,
    $Res Function(_$DashboardSettingsImpl) then,
  ) = __$$DashboardSettingsImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String dateRange, List<String> statusTabs, List<ColumnSettings> columns});
}

/// @nodoc
class __$$DashboardSettingsImplCopyWithImpl<$Res>
    extends _$DashboardSettingsCopyWithImpl<$Res, _$DashboardSettingsImpl>
    implements _$$DashboardSettingsImplCopyWith<$Res> {
  __$$DashboardSettingsImplCopyWithImpl(
    _$DashboardSettingsImpl _value,
    $Res Function(_$DashboardSettingsImpl) _then,
  ) : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? dateRange = null, Object? statusTabs = null, Object? columns = null}) {
    return _then(
      _$DashboardSettingsImpl(
        dateRange: null == dateRange
            ? _value.dateRange
            : dateRange // ignore: cast_nullable_to_non_nullable
                  as String,
        statusTabs: null == statusTabs
            ? _value._statusTabs
            : statusTabs // ignore: cast_nullable_to_non_nullable
                  as List<String>,
        columns: null == columns
            ? _value._columns
            : columns // ignore: cast_nullable_to_non_nullable
                  as List<ColumnSettings>,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$DashboardSettingsImpl implements _DashboardSettings {
  const _$DashboardSettingsImpl({
    this.dateRange = '30d',
    final List<String> statusTabs = const ['new', 'in_talks', 'quote_sent'],
    final List<ColumnSettings> columns = const [
      ColumnSettings(id: 'customer', visible: true, order: 0),
      ColumnSettings(id: 'eventType', visible: true, order: 1),
      ColumnSettings(id: 'status', visible: true, order: 2),
      ColumnSettings(id: 'priority', visible: true, order: 3),
      ColumnSettings(id: 'createdAt', visible: true, order: 4),
    ],
  }) : _statusTabs = statusTabs,
       _columns = columns;

  factory _$DashboardSettingsImpl.fromJson(Map<String, dynamic> json) =>
      _$$DashboardSettingsImplFromJson(json);

  @override
  @JsonKey()
  final String dateRange;
  final List<String> _statusTabs;
  @override
  @JsonKey()
  List<String> get statusTabs {
    if (_statusTabs is EqualUnmodifiableListView) return _statusTabs;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_statusTabs);
  }

  final List<ColumnSettings> _columns;
  @override
  @JsonKey()
  List<ColumnSettings> get columns {
    if (_columns is EqualUnmodifiableListView) return _columns;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_columns);
  }

  @override
  String toString() {
    return 'DashboardSettings(dateRange: $dateRange, statusTabs: $statusTabs, columns: $columns)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DashboardSettingsImpl &&
            (identical(other.dateRange, dateRange) || other.dateRange == dateRange) &&
            const DeepCollectionEquality().equals(other._statusTabs, _statusTabs) &&
            const DeepCollectionEquality().equals(other._columns, _columns));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    dateRange,
    const DeepCollectionEquality().hash(_statusTabs),
    const DeepCollectionEquality().hash(_columns),
  );

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$DashboardSettingsImplCopyWith<_$DashboardSettingsImpl> get copyWith =>
      __$$DashboardSettingsImplCopyWithImpl<_$DashboardSettingsImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$DashboardSettingsImplToJson(this);
  }
}

abstract class _DashboardSettings implements DashboardSettings {
  const factory _DashboardSettings({
    final String dateRange,
    final List<String> statusTabs,
    final List<ColumnSettings> columns,
  }) = _$DashboardSettingsImpl;

  factory _DashboardSettings.fromJson(Map<String, dynamic> json) = _$DashboardSettingsImpl.fromJson;

  @override
  String get dateRange;
  @override
  List<String> get statusTabs;
  @override
  List<ColumnSettings> get columns;
  @override
  @JsonKey(ignore: true)
  _$$DashboardSettingsImplCopyWith<_$DashboardSettingsImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ColumnSettings _$ColumnSettingsFromJson(Map<String, dynamic> json) {
  return _ColumnSettings.fromJson(json);
}

/// @nodoc
mixin _$ColumnSettings {
  String get id => throw _privateConstructorUsedError;
  bool get visible => throw _privateConstructorUsedError;
  int get order => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $ColumnSettingsCopyWith<ColumnSettings> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ColumnSettingsCopyWith<$Res> {
  factory $ColumnSettingsCopyWith(ColumnSettings value, $Res Function(ColumnSettings) then) =
      _$ColumnSettingsCopyWithImpl<$Res, ColumnSettings>;
  @useResult
  $Res call({String id, bool visible, int order});
}

/// @nodoc
class _$ColumnSettingsCopyWithImpl<$Res, $Val extends ColumnSettings>
    implements $ColumnSettingsCopyWith<$Res> {
  _$ColumnSettingsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? id = null, Object? visible = null, Object? order = null}) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            visible: null == visible
                ? _value.visible
                : visible // ignore: cast_nullable_to_non_nullable
                      as bool,
            order: null == order
                ? _value.order
                : order // ignore: cast_nullable_to_non_nullable
                      as int,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ColumnSettingsImplCopyWith<$Res> implements $ColumnSettingsCopyWith<$Res> {
  factory _$$ColumnSettingsImplCopyWith(
    _$ColumnSettingsImpl value,
    $Res Function(_$ColumnSettingsImpl) then,
  ) = __$$ColumnSettingsImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String id, bool visible, int order});
}

/// @nodoc
class __$$ColumnSettingsImplCopyWithImpl<$Res>
    extends _$ColumnSettingsCopyWithImpl<$Res, _$ColumnSettingsImpl>
    implements _$$ColumnSettingsImplCopyWith<$Res> {
  __$$ColumnSettingsImplCopyWithImpl(
    _$ColumnSettingsImpl _value,
    $Res Function(_$ColumnSettingsImpl) _then,
  ) : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? id = null, Object? visible = null, Object? order = null}) {
    return _then(
      _$ColumnSettingsImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        visible: null == visible
            ? _value.visible
            : visible // ignore: cast_nullable_to_non_nullable
                  as bool,
        order: null == order
            ? _value.order
            : order // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$ColumnSettingsImpl implements _ColumnSettings {
  const _$ColumnSettingsImpl({required this.id, this.visible = true, this.order = 0});

  factory _$ColumnSettingsImpl.fromJson(Map<String, dynamic> json) =>
      _$$ColumnSettingsImplFromJson(json);

  @override
  final String id;
  @override
  @JsonKey()
  final bool visible;
  @override
  @JsonKey()
  final int order;

  @override
  String toString() {
    return 'ColumnSettings(id: $id, visible: $visible, order: $order)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ColumnSettingsImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.visible, visible) || other.visible == visible) &&
            (identical(other.order, order) || other.order == order));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, id, visible, order);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$ColumnSettingsImplCopyWith<_$ColumnSettingsImpl> get copyWith =>
      __$$ColumnSettingsImplCopyWithImpl<_$ColumnSettingsImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ColumnSettingsImplToJson(this);
  }
}

abstract class _ColumnSettings implements ColumnSettings {
  const factory _ColumnSettings({required final String id, final bool visible, final int order}) =
      _$ColumnSettingsImpl;

  factory _ColumnSettings.fromJson(Map<String, dynamic> json) = _$ColumnSettingsImpl.fromJson;

  @override
  String get id;
  @override
  bool get visible;
  @override
  int get order;
  @override
  @JsonKey(ignore: true)
  _$$ColumnSettingsImplCopyWith<_$ColumnSettingsImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

NotificationSettings _$NotificationSettingsFromJson(Map<String, dynamic> json) {
  return _NotificationSettings.fromJson(json);
}

/// @nodoc
mixin _$NotificationSettings {
  bool get pushEnabled => throw _privateConstructorUsedError;
  bool get emailEnabled => throw _privateConstructorUsedError;
  NotificationChannels get channels => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $NotificationSettingsCopyWith<NotificationSettings> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $NotificationSettingsCopyWith<$Res> {
  factory $NotificationSettingsCopyWith(
    NotificationSettings value,
    $Res Function(NotificationSettings) then,
  ) = _$NotificationSettingsCopyWithImpl<$Res, NotificationSettings>;
  @useResult
  $Res call({bool pushEnabled, bool emailEnabled, NotificationChannels channels});

  $NotificationChannelsCopyWith<$Res> get channels;
}

/// @nodoc
class _$NotificationSettingsCopyWithImpl<$Res, $Val extends NotificationSettings>
    implements $NotificationSettingsCopyWith<$Res> {
  _$NotificationSettingsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? pushEnabled = null, Object? emailEnabled = null, Object? channels = null}) {
    return _then(
      _value.copyWith(
            pushEnabled: null == pushEnabled
                ? _value.pushEnabled
                : pushEnabled // ignore: cast_nullable_to_non_nullable
                      as bool,
            emailEnabled: null == emailEnabled
                ? _value.emailEnabled
                : emailEnabled // ignore: cast_nullable_to_non_nullable
                      as bool,
            channels: null == channels
                ? _value.channels
                : channels // ignore: cast_nullable_to_non_nullable
                      as NotificationChannels,
          )
          as $Val,
    );
  }

  @override
  @pragma('vm:prefer-inline')
  $NotificationChannelsCopyWith<$Res> get channels {
    return $NotificationChannelsCopyWith<$Res>(_value.channels, (value) {
      return _then(_value.copyWith(channels: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$NotificationSettingsImplCopyWith<$Res>
    implements $NotificationSettingsCopyWith<$Res> {
  factory _$$NotificationSettingsImplCopyWith(
    _$NotificationSettingsImpl value,
    $Res Function(_$NotificationSettingsImpl) then,
  ) = __$$NotificationSettingsImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({bool pushEnabled, bool emailEnabled, NotificationChannels channels});

  @override
  $NotificationChannelsCopyWith<$Res> get channels;
}

/// @nodoc
class __$$NotificationSettingsImplCopyWithImpl<$Res>
    extends _$NotificationSettingsCopyWithImpl<$Res, _$NotificationSettingsImpl>
    implements _$$NotificationSettingsImplCopyWith<$Res> {
  __$$NotificationSettingsImplCopyWithImpl(
    _$NotificationSettingsImpl _value,
    $Res Function(_$NotificationSettingsImpl) _then,
  ) : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? pushEnabled = null, Object? emailEnabled = null, Object? channels = null}) {
    return _then(
      _$NotificationSettingsImpl(
        pushEnabled: null == pushEnabled
            ? _value.pushEnabled
            : pushEnabled // ignore: cast_nullable_to_non_nullable
                  as bool,
        emailEnabled: null == emailEnabled
            ? _value.emailEnabled
            : emailEnabled // ignore: cast_nullable_to_non_nullable
                  as bool,
        channels: null == channels
            ? _value.channels
            : channels // ignore: cast_nullable_to_non_nullable
                  as NotificationChannels,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$NotificationSettingsImpl implements _NotificationSettings {
  const _$NotificationSettingsImpl({
    this.pushEnabled = true,
    this.emailEnabled = false,
    this.channels = const NotificationChannels(),
  });

  factory _$NotificationSettingsImpl.fromJson(Map<String, dynamic> json) =>
      _$$NotificationSettingsImplFromJson(json);

  @override
  @JsonKey()
  final bool pushEnabled;
  @override
  @JsonKey()
  final bool emailEnabled;
  @override
  @JsonKey()
  final NotificationChannels channels;

  @override
  String toString() {
    return 'NotificationSettings(pushEnabled: $pushEnabled, emailEnabled: $emailEnabled, channels: $channels)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$NotificationSettingsImpl &&
            (identical(other.pushEnabled, pushEnabled) || other.pushEnabled == pushEnabled) &&
            (identical(other.emailEnabled, emailEnabled) || other.emailEnabled == emailEnabled) &&
            (identical(other.channels, channels) || other.channels == channels));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, pushEnabled, emailEnabled, channels);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$NotificationSettingsImplCopyWith<_$NotificationSettingsImpl> get copyWith =>
      __$$NotificationSettingsImplCopyWithImpl<_$NotificationSettingsImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$NotificationSettingsImplToJson(this);
  }
}

abstract class _NotificationSettings implements NotificationSettings {
  const factory _NotificationSettings({
    final bool pushEnabled,
    final bool emailEnabled,
    final NotificationChannels channels,
  }) = _$NotificationSettingsImpl;

  factory _NotificationSettings.fromJson(Map<String, dynamic> json) =
      _$NotificationSettingsImpl.fromJson;

  @override
  bool get pushEnabled;
  @override
  bool get emailEnabled;
  @override
  NotificationChannels get channels;
  @override
  @JsonKey(ignore: true)
  _$$NotificationSettingsImplCopyWith<_$NotificationSettingsImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

NotificationChannels _$NotificationChannelsFromJson(Map<String, dynamic> json) {
  return _NotificationChannels.fromJson(json);
}

/// @nodoc
mixin _$NotificationChannels {
  bool get assignment => throw _privateConstructorUsedError;
  bool get statusChange => throw _privateConstructorUsedError;
  bool get payment => throw _privateConstructorUsedError;
  bool get reminders => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $NotificationChannelsCopyWith<NotificationChannels> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $NotificationChannelsCopyWith<$Res> {
  factory $NotificationChannelsCopyWith(
    NotificationChannels value,
    $Res Function(NotificationChannels) then,
  ) = _$NotificationChannelsCopyWithImpl<$Res, NotificationChannels>;
  @useResult
  $Res call({bool assignment, bool statusChange, bool payment, bool reminders});
}

/// @nodoc
class _$NotificationChannelsCopyWithImpl<$Res, $Val extends NotificationChannels>
    implements $NotificationChannelsCopyWith<$Res> {
  _$NotificationChannelsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? assignment = null,
    Object? statusChange = null,
    Object? payment = null,
    Object? reminders = null,
  }) {
    return _then(
      _value.copyWith(
            assignment: null == assignment
                ? _value.assignment
                : assignment // ignore: cast_nullable_to_non_nullable
                      as bool,
            statusChange: null == statusChange
                ? _value.statusChange
                : statusChange // ignore: cast_nullable_to_non_nullable
                      as bool,
            payment: null == payment
                ? _value.payment
                : payment // ignore: cast_nullable_to_non_nullable
                      as bool,
            reminders: null == reminders
                ? _value.reminders
                : reminders // ignore: cast_nullable_to_non_nullable
                      as bool,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$NotificationChannelsImplCopyWith<$Res>
    implements $NotificationChannelsCopyWith<$Res> {
  factory _$$NotificationChannelsImplCopyWith(
    _$NotificationChannelsImpl value,
    $Res Function(_$NotificationChannelsImpl) then,
  ) = __$$NotificationChannelsImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({bool assignment, bool statusChange, bool payment, bool reminders});
}

/// @nodoc
class __$$NotificationChannelsImplCopyWithImpl<$Res>
    extends _$NotificationChannelsCopyWithImpl<$Res, _$NotificationChannelsImpl>
    implements _$$NotificationChannelsImplCopyWith<$Res> {
  __$$NotificationChannelsImplCopyWithImpl(
    _$NotificationChannelsImpl _value,
    $Res Function(_$NotificationChannelsImpl) _then,
  ) : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? assignment = null,
    Object? statusChange = null,
    Object? payment = null,
    Object? reminders = null,
  }) {
    return _then(
      _$NotificationChannelsImpl(
        assignment: null == assignment
            ? _value.assignment
            : assignment // ignore: cast_nullable_to_non_nullable
                  as bool,
        statusChange: null == statusChange
            ? _value.statusChange
            : statusChange // ignore: cast_nullable_to_non_nullable
                  as bool,
        payment: null == payment
            ? _value.payment
            : payment // ignore: cast_nullable_to_non_nullable
                  as bool,
        reminders: null == reminders
            ? _value.reminders
            : reminders // ignore: cast_nullable_to_non_nullable
                  as bool,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$NotificationChannelsImpl implements _NotificationChannels {
  const _$NotificationChannelsImpl({
    this.assignment = true,
    this.statusChange = true,
    this.payment = true,
    this.reminders = true,
  });

  factory _$NotificationChannelsImpl.fromJson(Map<String, dynamic> json) =>
      _$$NotificationChannelsImplFromJson(json);

  @override
  @JsonKey()
  final bool assignment;
  @override
  @JsonKey()
  final bool statusChange;
  @override
  @JsonKey()
  final bool payment;
  @override
  @JsonKey()
  final bool reminders;

  @override
  String toString() {
    return 'NotificationChannels(assignment: $assignment, statusChange: $statusChange, payment: $payment, reminders: $reminders)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$NotificationChannelsImpl &&
            (identical(other.assignment, assignment) || other.assignment == assignment) &&
            (identical(other.statusChange, statusChange) || other.statusChange == statusChange) &&
            (identical(other.payment, payment) || other.payment == payment) &&
            (identical(other.reminders, reminders) || other.reminders == reminders));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, assignment, statusChange, payment, reminders);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$NotificationChannelsImplCopyWith<_$NotificationChannelsImpl> get copyWith =>
      __$$NotificationChannelsImplCopyWithImpl<_$NotificationChannelsImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$NotificationChannelsImplToJson(this);
  }
}

abstract class _NotificationChannels implements NotificationChannels {
  const factory _NotificationChannels({
    final bool assignment,
    final bool statusChange,
    final bool payment,
    final bool reminders,
  }) = _$NotificationChannelsImpl;

  factory _NotificationChannels.fromJson(Map<String, dynamic> json) =
      _$NotificationChannelsImpl.fromJson;

  @override
  bool get assignment;
  @override
  bool get statusChange;
  @override
  bool get payment;
  @override
  bool get reminders;
  @override
  @JsonKey(ignore: true)
  _$$NotificationChannelsImplCopyWith<_$NotificationChannelsImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
