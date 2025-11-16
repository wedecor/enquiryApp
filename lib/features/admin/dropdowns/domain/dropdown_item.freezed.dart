// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'dropdown_item.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

DropdownItem _$DropdownItemFromJson(Map<String, dynamic> json) {
  return _DropdownItem.fromJson(json);
}

/// @nodoc
mixin _$DropdownItem {
  String get value => throw _privateConstructorUsedError;
  String get label => throw _privateConstructorUsedError;
  int get order => throw _privateConstructorUsedError;
  bool get active => throw _privateConstructorUsedError;
  String? get color => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;
  DateTime get updatedAt => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $DropdownItemCopyWith<DropdownItem> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DropdownItemCopyWith<$Res> {
  factory $DropdownItemCopyWith(DropdownItem value, $Res Function(DropdownItem) then) =
      _$DropdownItemCopyWithImpl<$Res, DropdownItem>;
  @useResult
  $Res call({
    String value,
    String label,
    int order,
    bool active,
    String? color,
    DateTime createdAt,
    DateTime updatedAt,
  });
}

/// @nodoc
class _$DropdownItemCopyWithImpl<$Res, $Val extends DropdownItem>
    implements $DropdownItemCopyWith<$Res> {
  _$DropdownItemCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? value = null,
    Object? label = null,
    Object? order = null,
    Object? active = null,
    Object? color = freezed,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(
      _value.copyWith(
            value: null == value
                ? _value.value
                : value // ignore: cast_nullable_to_non_nullable
                      as String,
            label: null == label
                ? _value.label
                : label // ignore: cast_nullable_to_non_nullable
                      as String,
            order: null == order
                ? _value.order
                : order // ignore: cast_nullable_to_non_nullable
                      as int,
            active: null == active
                ? _value.active
                : active // ignore: cast_nullable_to_non_nullable
                      as bool,
            color: freezed == color
                ? _value.color
                : color // ignore: cast_nullable_to_non_nullable
                      as String?,
            createdAt: null == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            updatedAt: null == updatedAt
                ? _value.updatedAt
                : updatedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$DropdownItemImplCopyWith<$Res> implements $DropdownItemCopyWith<$Res> {
  factory _$$DropdownItemImplCopyWith(
    _$DropdownItemImpl value,
    $Res Function(_$DropdownItemImpl) then,
  ) = __$$DropdownItemImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String value,
    String label,
    int order,
    bool active,
    String? color,
    DateTime createdAt,
    DateTime updatedAt,
  });
}

/// @nodoc
class __$$DropdownItemImplCopyWithImpl<$Res>
    extends _$DropdownItemCopyWithImpl<$Res, _$DropdownItemImpl>
    implements _$$DropdownItemImplCopyWith<$Res> {
  __$$DropdownItemImplCopyWithImpl(
    _$DropdownItemImpl _value,
    $Res Function(_$DropdownItemImpl) _then,
  ) : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? value = null,
    Object? label = null,
    Object? order = null,
    Object? active = null,
    Object? color = freezed,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(
      _$DropdownItemImpl(
        value: null == value
            ? _value.value
            : value // ignore: cast_nullable_to_non_nullable
                  as String,
        label: null == label
            ? _value.label
            : label // ignore: cast_nullable_to_non_nullable
                  as String,
        order: null == order
            ? _value.order
            : order // ignore: cast_nullable_to_non_nullable
                  as int,
        active: null == active
            ? _value.active
            : active // ignore: cast_nullable_to_non_nullable
                  as bool,
        color: freezed == color
            ? _value.color
            : color // ignore: cast_nullable_to_non_nullable
                  as String?,
        createdAt: null == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        updatedAt: null == updatedAt
            ? _value.updatedAt
            : updatedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$DropdownItemImpl implements _DropdownItem {
  const _$DropdownItemImpl({
    required this.value,
    required this.label,
    required this.order,
    required this.active,
    this.color,
    required this.createdAt,
    required this.updatedAt,
  });

  factory _$DropdownItemImpl.fromJson(Map<String, dynamic> json) =>
      _$$DropdownItemImplFromJson(json);

  @override
  final String value;
  @override
  final String label;
  @override
  final int order;
  @override
  final bool active;
  @override
  final String? color;
  @override
  final DateTime createdAt;
  @override
  final DateTime updatedAt;

  @override
  String toString() {
    return 'DropdownItem(value: $value, label: $label, order: $order, active: $active, color: $color, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DropdownItemImpl &&
            (identical(other.value, value) || other.value == value) &&
            (identical(other.label, label) || other.label == label) &&
            (identical(other.order, order) || other.order == order) &&
            (identical(other.active, active) || other.active == active) &&
            (identical(other.color, color) || other.color == color) &&
            (identical(other.createdAt, createdAt) || other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode =>
      Object.hash(runtimeType, value, label, order, active, color, createdAt, updatedAt);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$DropdownItemImplCopyWith<_$DropdownItemImpl> get copyWith =>
      __$$DropdownItemImplCopyWithImpl<_$DropdownItemImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$DropdownItemImplToJson(this);
  }
}

abstract class _DropdownItem implements DropdownItem {
  const factory _DropdownItem({
    required final String value,
    required final String label,
    required final int order,
    required final bool active,
    final String? color,
    required final DateTime createdAt,
    required final DateTime updatedAt,
  }) = _$DropdownItemImpl;

  factory _DropdownItem.fromJson(Map<String, dynamic> json) = _$DropdownItemImpl.fromJson;

  @override
  String get value;
  @override
  String get label;
  @override
  int get order;
  @override
  bool get active;
  @override
  String? get color;
  @override
  DateTime get createdAt;
  @override
  DateTime get updatedAt;
  @override
  @JsonKey(ignore: true)
  _$$DropdownItemImplCopyWith<_$DropdownItemImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$DropdownItemInput {
  String get value => throw _privateConstructorUsedError;
  String get label => throw _privateConstructorUsedError;
  String? get color => throw _privateConstructorUsedError;
  bool get active => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $DropdownItemInputCopyWith<DropdownItemInput> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DropdownItemInputCopyWith<$Res> {
  factory $DropdownItemInputCopyWith(
    DropdownItemInput value,
    $Res Function(DropdownItemInput) then,
  ) = _$DropdownItemInputCopyWithImpl<$Res, DropdownItemInput>;
  @useResult
  $Res call({String value, String label, String? color, bool active});
}

/// @nodoc
class _$DropdownItemInputCopyWithImpl<$Res, $Val extends DropdownItemInput>
    implements $DropdownItemInputCopyWith<$Res> {
  _$DropdownItemInputCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? value = null,
    Object? label = null,
    Object? color = freezed,
    Object? active = null,
  }) {
    return _then(
      _value.copyWith(
            value: null == value
                ? _value.value
                : value // ignore: cast_nullable_to_non_nullable
                      as String,
            label: null == label
                ? _value.label
                : label // ignore: cast_nullable_to_non_nullable
                      as String,
            color: freezed == color
                ? _value.color
                : color // ignore: cast_nullable_to_non_nullable
                      as String?,
            active: null == active
                ? _value.active
                : active // ignore: cast_nullable_to_non_nullable
                      as bool,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$DropdownItemInputImplCopyWith<$Res> implements $DropdownItemInputCopyWith<$Res> {
  factory _$$DropdownItemInputImplCopyWith(
    _$DropdownItemInputImpl value,
    $Res Function(_$DropdownItemInputImpl) then,
  ) = __$$DropdownItemInputImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String value, String label, String? color, bool active});
}

/// @nodoc
class __$$DropdownItemInputImplCopyWithImpl<$Res>
    extends _$DropdownItemInputCopyWithImpl<$Res, _$DropdownItemInputImpl>
    implements _$$DropdownItemInputImplCopyWith<$Res> {
  __$$DropdownItemInputImplCopyWithImpl(
    _$DropdownItemInputImpl _value,
    $Res Function(_$DropdownItemInputImpl) _then,
  ) : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? value = null,
    Object? label = null,
    Object? color = freezed,
    Object? active = null,
  }) {
    return _then(
      _$DropdownItemInputImpl(
        value: null == value
            ? _value.value
            : value // ignore: cast_nullable_to_non_nullable
                  as String,
        label: null == label
            ? _value.label
            : label // ignore: cast_nullable_to_non_nullable
                  as String,
        color: freezed == color
            ? _value.color
            : color // ignore: cast_nullable_to_non_nullable
                  as String?,
        active: null == active
            ? _value.active
            : active // ignore: cast_nullable_to_non_nullable
                  as bool,
      ),
    );
  }
}

/// @nodoc

class _$DropdownItemInputImpl implements _DropdownItemInput {
  const _$DropdownItemInputImpl({
    required this.value,
    required this.label,
    this.color,
    this.active = true,
  });

  @override
  final String value;
  @override
  final String label;
  @override
  final String? color;
  @override
  @JsonKey()
  final bool active;

  @override
  String toString() {
    return 'DropdownItemInput(value: $value, label: $label, color: $color, active: $active)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DropdownItemInputImpl &&
            (identical(other.value, value) || other.value == value) &&
            (identical(other.label, label) || other.label == label) &&
            (identical(other.color, color) || other.color == color) &&
            (identical(other.active, active) || other.active == active));
  }

  @override
  int get hashCode => Object.hash(runtimeType, value, label, color, active);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$DropdownItemInputImplCopyWith<_$DropdownItemInputImpl> get copyWith =>
      __$$DropdownItemInputImplCopyWithImpl<_$DropdownItemInputImpl>(this, _$identity);
}

abstract class _DropdownItemInput implements DropdownItemInput {
  const factory _DropdownItemInput({
    required final String value,
    required final String label,
    final String? color,
    final bool active,
  }) = _$DropdownItemInputImpl;

  @override
  String get value;
  @override
  String get label;
  @override
  String? get color;
  @override
  bool get active;
  @override
  @JsonKey(ignore: true)
  _$$DropdownItemInputImplCopyWith<_$DropdownItemInputImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
