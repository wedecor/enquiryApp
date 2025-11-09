// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'user_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

UserModel _$UserModelFromJson(Map<String, dynamic> json) {
  return _UserModel.fromJson(json);
}

/// @nodoc
mixin _$UserModel {
  /// Unique identifier for the user.
  ///
  /// This is typically the UID from Firebase Authentication and serves
  /// as the primary key for the user in the database. It should be
  /// unique across all users in the system.
  String get uid => throw _privateConstructorUsedError;

  /// User's full name as displayed in the application.
  ///
  /// This name is used throughout the UI for displaying user information,
  /// such as in enquiry assignments, user lists, and profile displays.
  String get name => throw _privateConstructorUsedError;

  /// User's email address.
  ///
  /// This email is used for:
  /// - User authentication (login)
  /// - System communications and notifications
  /// - User identification in the system
  String get email => throw _privateConstructorUsedError;

  /// User's phone number.
  ///
  /// This phone number is used for:
  /// - Contact information in enquiries
  /// - Emergency communications
  /// - User verification processes
  String? get phone => throw _privateConstructorUsedError;

  /// User's role in the application.
  ///
  /// This role determines the user's permissions and access levels
  /// throughout the system. Defaults to [UserRole.staff] for security.
  UserRole get role => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $UserModelCopyWith<UserModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $UserModelCopyWith<$Res> {
  factory $UserModelCopyWith(UserModel value, $Res Function(UserModel) then) =
      _$UserModelCopyWithImpl<$Res, UserModel>;
  @useResult
  $Res call(
      {String uid, String name, String email, String? phone, UserRole role});
}

/// @nodoc
class _$UserModelCopyWithImpl<$Res, $Val extends UserModel>
    implements $UserModelCopyWith<$Res> {
  _$UserModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? uid = null,
    Object? name = null,
    Object? email = null,
    Object? phone = freezed,
    Object? role = null,
  }) {
    return _then(_value.copyWith(
      uid: null == uid
          ? _value.uid
          : uid // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      email: null == email
          ? _value.email
          : email // ignore: cast_nullable_to_non_nullable
              as String,
      phone: freezed == phone
          ? _value.phone
          : phone // ignore: cast_nullable_to_non_nullable
              as String?,
      role: null == role
          ? _value.role
          : role // ignore: cast_nullable_to_non_nullable
              as UserRole,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$UserModelImplCopyWith<$Res>
    implements $UserModelCopyWith<$Res> {
  factory _$$UserModelImplCopyWith(
          _$UserModelImpl value, $Res Function(_$UserModelImpl) then) =
      __$$UserModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String uid, String name, String email, String? phone, UserRole role});
}

/// @nodoc
class __$$UserModelImplCopyWithImpl<$Res>
    extends _$UserModelCopyWithImpl<$Res, _$UserModelImpl>
    implements _$$UserModelImplCopyWith<$Res> {
  __$$UserModelImplCopyWithImpl(
      _$UserModelImpl _value, $Res Function(_$UserModelImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? uid = null,
    Object? name = null,
    Object? email = null,
    Object? phone = freezed,
    Object? role = null,
  }) {
    return _then(_$UserModelImpl(
      uid: null == uid
          ? _value.uid
          : uid // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      email: null == email
          ? _value.email
          : email // ignore: cast_nullable_to_non_nullable
              as String,
      phone: freezed == phone
          ? _value.phone
          : phone // ignore: cast_nullable_to_non_nullable
              as String?,
      role: null == role
          ? _value.role
          : role // ignore: cast_nullable_to_non_nullable
              as UserRole,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$UserModelImpl implements _UserModel {
  const _$UserModelImpl(
      {required this.uid,
      required this.name,
      required this.email,
      this.phone,
      this.role = UserRole.staff});

  factory _$UserModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$UserModelImplFromJson(json);

  /// Unique identifier for the user.
  ///
  /// This is typically the UID from Firebase Authentication and serves
  /// as the primary key for the user in the database. It should be
  /// unique across all users in the system.
  @override
  final String uid;

  /// User's full name as displayed in the application.
  ///
  /// This name is used throughout the UI for displaying user information,
  /// such as in enquiry assignments, user lists, and profile displays.
  @override
  final String name;

  /// User's email address.
  ///
  /// This email is used for:
  /// - User authentication (login)
  /// - System communications and notifications
  /// - User identification in the system
  @override
  final String email;

  /// User's phone number.
  ///
  /// This phone number is used for:
  /// - Contact information in enquiries
  /// - Emergency communications
  /// - User verification processes
  @override
  final String? phone;

  /// User's role in the application.
  ///
  /// This role determines the user's permissions and access levels
  /// throughout the system. Defaults to [UserRole.staff] for security.
  @override
  @JsonKey()
  final UserRole role;

  @override
  String toString() {
    return 'UserModel(uid: $uid, name: $name, email: $email, phone: $phone, role: $role)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UserModelImpl &&
            (identical(other.uid, uid) || other.uid == uid) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.email, email) || other.email == email) &&
            (identical(other.phone, phone) || other.phone == phone) &&
            (identical(other.role, role) || other.role == role));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, uid, name, email, phone, role);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$UserModelImplCopyWith<_$UserModelImpl> get copyWith =>
      __$$UserModelImplCopyWithImpl<_$UserModelImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$UserModelImplToJson(
      this,
    );
  }
}

abstract class _UserModel implements UserModel {
  const factory _UserModel(
      {required final String uid,
      required final String name,
      required final String email,
      final String? phone,
      final UserRole role}) = _$UserModelImpl;

  factory _UserModel.fromJson(Map<String, dynamic> json) =
      _$UserModelImpl.fromJson;

  @override

  /// Unique identifier for the user.
  ///
  /// This is typically the UID from Firebase Authentication and serves
  /// as the primary key for the user in the database. It should be
  /// unique across all users in the system.
  String get uid;
  @override

  /// User's full name as displayed in the application.
  ///
  /// This name is used throughout the UI for displaying user information,
  /// such as in enquiry assignments, user lists, and profile displays.
  String get name;
  @override

  /// User's email address.
  ///
  /// This email is used for:
  /// - User authentication (login)
  /// - System communications and notifications
  /// - User identification in the system
  String get email;
  @override

  /// User's phone number.
  ///
  /// This phone number is used for:
  /// - Contact information in enquiries
  /// - Emergency communications
  /// - User verification processes
  String? get phone;
  @override

  /// User's role in the application.
  ///
  /// This role determines the user's permissions and access levels
  /// throughout the system. Defaults to [UserRole.staff] for security.
  UserRole get role;
  @override
  @JsonKey(ignore: true)
  _$$UserModelImplCopyWith<_$UserModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
