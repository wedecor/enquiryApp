// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'session_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$FirebaseUserLite {
  String get uid => throw _privateConstructorUsedError;
  String get email => throw _privateConstructorUsedError;
  bool get isEmailVerified => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $FirebaseUserLiteCopyWith<FirebaseUserLite> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $FirebaseUserLiteCopyWith<$Res> {
  factory $FirebaseUserLiteCopyWith(
          FirebaseUserLite value, $Res Function(FirebaseUserLite) then) =
      _$FirebaseUserLiteCopyWithImpl<$Res, FirebaseUserLite>;
  @useResult
  $Res call({String uid, String email, bool isEmailVerified});
}

/// @nodoc
class _$FirebaseUserLiteCopyWithImpl<$Res, $Val extends FirebaseUserLite>
    implements $FirebaseUserLiteCopyWith<$Res> {
  _$FirebaseUserLiteCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? uid = null,
    Object? email = null,
    Object? isEmailVerified = null,
  }) {
    return _then(_value.copyWith(
      uid: null == uid
          ? _value.uid
          : uid // ignore: cast_nullable_to_non_nullable
              as String,
      email: null == email
          ? _value.email
          : email // ignore: cast_nullable_to_non_nullable
              as String,
      isEmailVerified: null == isEmailVerified
          ? _value.isEmailVerified
          : isEmailVerified // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$FirebaseUserLiteImplCopyWith<$Res>
    implements $FirebaseUserLiteCopyWith<$Res> {
  factory _$$FirebaseUserLiteImplCopyWith(_$FirebaseUserLiteImpl value,
          $Res Function(_$FirebaseUserLiteImpl) then) =
      __$$FirebaseUserLiteImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String uid, String email, bool isEmailVerified});
}

/// @nodoc
class __$$FirebaseUserLiteImplCopyWithImpl<$Res>
    extends _$FirebaseUserLiteCopyWithImpl<$Res, _$FirebaseUserLiteImpl>
    implements _$$FirebaseUserLiteImplCopyWith<$Res> {
  __$$FirebaseUserLiteImplCopyWithImpl(_$FirebaseUserLiteImpl _value,
      $Res Function(_$FirebaseUserLiteImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? uid = null,
    Object? email = null,
    Object? isEmailVerified = null,
  }) {
    return _then(_$FirebaseUserLiteImpl(
      uid: null == uid
          ? _value.uid
          : uid // ignore: cast_nullable_to_non_nullable
              as String,
      email: null == email
          ? _value.email
          : email // ignore: cast_nullable_to_non_nullable
              as String,
      isEmailVerified: null == isEmailVerified
          ? _value.isEmailVerified
          : isEmailVerified // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc

class _$FirebaseUserLiteImpl implements _FirebaseUserLite {
  const _$FirebaseUserLiteImpl(
      {required this.uid, required this.email, this.isEmailVerified = false});

  @override
  final String uid;
  @override
  final String email;
  @override
  @JsonKey()
  final bool isEmailVerified;

  @override
  String toString() {
    return 'FirebaseUserLite(uid: $uid, email: $email, isEmailVerified: $isEmailVerified)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$FirebaseUserLiteImpl &&
            (identical(other.uid, uid) || other.uid == uid) &&
            (identical(other.email, email) || other.email == email) &&
            (identical(other.isEmailVerified, isEmailVerified) ||
                other.isEmailVerified == isEmailVerified));
  }

  @override
  int get hashCode => Object.hash(runtimeType, uid, email, isEmailVerified);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$FirebaseUserLiteImplCopyWith<_$FirebaseUserLiteImpl> get copyWith =>
      __$$FirebaseUserLiteImplCopyWithImpl<_$FirebaseUserLiteImpl>(
          this, _$identity);
}

abstract class _FirebaseUserLite implements FirebaseUserLite {
  const factory _FirebaseUserLite(
      {required final String uid,
      required final String email,
      final bool isEmailVerified}) = _$FirebaseUserLiteImpl;

  @override
  String get uid;
  @override
  String get email;
  @override
  bool get isEmailVerified;
  @override
  @JsonKey(ignore: true)
  _$$FirebaseUserLiteImplCopyWith<_$FirebaseUserLiteImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$SessionState {
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() unauthenticated,
    required TResult Function(String? reason) loading,
    required TResult Function(FirebaseUserLite user, UserModel profile)
        authenticated,
    required TResult Function(String email) unprovisioned,
    required TResult Function(String email) disabled,
    required TResult Function(String message, Object? cause) error,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? unauthenticated,
    TResult? Function(String? reason)? loading,
    TResult? Function(FirebaseUserLite user, UserModel profile)? authenticated,
    TResult? Function(String email)? unprovisioned,
    TResult? Function(String email)? disabled,
    TResult? Function(String message, Object? cause)? error,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? unauthenticated,
    TResult Function(String? reason)? loading,
    TResult Function(FirebaseUserLite user, UserModel profile)? authenticated,
    TResult Function(String email)? unprovisioned,
    TResult Function(String email)? disabled,
    TResult Function(String message, Object? cause)? error,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(SessionUnauthenticated value) unauthenticated,
    required TResult Function(SessionLoading value) loading,
    required TResult Function(SessionAuthenticated value) authenticated,
    required TResult Function(SessionUnprovisioned value) unprovisioned,
    required TResult Function(SessionDisabled value) disabled,
    required TResult Function(SessionError value) error,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(SessionUnauthenticated value)? unauthenticated,
    TResult? Function(SessionLoading value)? loading,
    TResult? Function(SessionAuthenticated value)? authenticated,
    TResult? Function(SessionUnprovisioned value)? unprovisioned,
    TResult? Function(SessionDisabled value)? disabled,
    TResult? Function(SessionError value)? error,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(SessionUnauthenticated value)? unauthenticated,
    TResult Function(SessionLoading value)? loading,
    TResult Function(SessionAuthenticated value)? authenticated,
    TResult Function(SessionUnprovisioned value)? unprovisioned,
    TResult Function(SessionDisabled value)? disabled,
    TResult Function(SessionError value)? error,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SessionStateCopyWith<$Res> {
  factory $SessionStateCopyWith(
          SessionState value, $Res Function(SessionState) then) =
      _$SessionStateCopyWithImpl<$Res, SessionState>;
}

/// @nodoc
class _$SessionStateCopyWithImpl<$Res, $Val extends SessionState>
    implements $SessionStateCopyWith<$Res> {
  _$SessionStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;
}

/// @nodoc
abstract class _$$SessionUnauthenticatedImplCopyWith<$Res> {
  factory _$$SessionUnauthenticatedImplCopyWith(
          _$SessionUnauthenticatedImpl value,
          $Res Function(_$SessionUnauthenticatedImpl) then) =
      __$$SessionUnauthenticatedImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$SessionUnauthenticatedImplCopyWithImpl<$Res>
    extends _$SessionStateCopyWithImpl<$Res, _$SessionUnauthenticatedImpl>
    implements _$$SessionUnauthenticatedImplCopyWith<$Res> {
  __$$SessionUnauthenticatedImplCopyWithImpl(
      _$SessionUnauthenticatedImpl _value,
      $Res Function(_$SessionUnauthenticatedImpl) _then)
      : super(_value, _then);
}

/// @nodoc

class _$SessionUnauthenticatedImpl implements SessionUnauthenticated {
  const _$SessionUnauthenticatedImpl();

  @override
  String toString() {
    return 'SessionState.unauthenticated()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SessionUnauthenticatedImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() unauthenticated,
    required TResult Function(String? reason) loading,
    required TResult Function(FirebaseUserLite user, UserModel profile)
        authenticated,
    required TResult Function(String email) unprovisioned,
    required TResult Function(String email) disabled,
    required TResult Function(String message, Object? cause) error,
  }) {
    return unauthenticated();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? unauthenticated,
    TResult? Function(String? reason)? loading,
    TResult? Function(FirebaseUserLite user, UserModel profile)? authenticated,
    TResult? Function(String email)? unprovisioned,
    TResult? Function(String email)? disabled,
    TResult? Function(String message, Object? cause)? error,
  }) {
    return unauthenticated?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? unauthenticated,
    TResult Function(String? reason)? loading,
    TResult Function(FirebaseUserLite user, UserModel profile)? authenticated,
    TResult Function(String email)? unprovisioned,
    TResult Function(String email)? disabled,
    TResult Function(String message, Object? cause)? error,
    required TResult orElse(),
  }) {
    if (unauthenticated != null) {
      return unauthenticated();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(SessionUnauthenticated value) unauthenticated,
    required TResult Function(SessionLoading value) loading,
    required TResult Function(SessionAuthenticated value) authenticated,
    required TResult Function(SessionUnprovisioned value) unprovisioned,
    required TResult Function(SessionDisabled value) disabled,
    required TResult Function(SessionError value) error,
  }) {
    return unauthenticated(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(SessionUnauthenticated value)? unauthenticated,
    TResult? Function(SessionLoading value)? loading,
    TResult? Function(SessionAuthenticated value)? authenticated,
    TResult? Function(SessionUnprovisioned value)? unprovisioned,
    TResult? Function(SessionDisabled value)? disabled,
    TResult? Function(SessionError value)? error,
  }) {
    return unauthenticated?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(SessionUnauthenticated value)? unauthenticated,
    TResult Function(SessionLoading value)? loading,
    TResult Function(SessionAuthenticated value)? authenticated,
    TResult Function(SessionUnprovisioned value)? unprovisioned,
    TResult Function(SessionDisabled value)? disabled,
    TResult Function(SessionError value)? error,
    required TResult orElse(),
  }) {
    if (unauthenticated != null) {
      return unauthenticated(this);
    }
    return orElse();
  }
}

abstract class SessionUnauthenticated implements SessionState {
  const factory SessionUnauthenticated() = _$SessionUnauthenticatedImpl;
}

/// @nodoc
abstract class _$$SessionLoadingImplCopyWith<$Res> {
  factory _$$SessionLoadingImplCopyWith(_$SessionLoadingImpl value,
          $Res Function(_$SessionLoadingImpl) then) =
      __$$SessionLoadingImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String? reason});
}

/// @nodoc
class __$$SessionLoadingImplCopyWithImpl<$Res>
    extends _$SessionStateCopyWithImpl<$Res, _$SessionLoadingImpl>
    implements _$$SessionLoadingImplCopyWith<$Res> {
  __$$SessionLoadingImplCopyWithImpl(
      _$SessionLoadingImpl _value, $Res Function(_$SessionLoadingImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? reason = freezed,
  }) {
    return _then(_$SessionLoadingImpl(
      reason: freezed == reason
          ? _value.reason
          : reason // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc

class _$SessionLoadingImpl implements SessionLoading {
  const _$SessionLoadingImpl({this.reason});

  @override
  final String? reason;

  @override
  String toString() {
    return 'SessionState.loading(reason: $reason)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SessionLoadingImpl &&
            (identical(other.reason, reason) || other.reason == reason));
  }

  @override
  int get hashCode => Object.hash(runtimeType, reason);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$SessionLoadingImplCopyWith<_$SessionLoadingImpl> get copyWith =>
      __$$SessionLoadingImplCopyWithImpl<_$SessionLoadingImpl>(
          this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() unauthenticated,
    required TResult Function(String? reason) loading,
    required TResult Function(FirebaseUserLite user, UserModel profile)
        authenticated,
    required TResult Function(String email) unprovisioned,
    required TResult Function(String email) disabled,
    required TResult Function(String message, Object? cause) error,
  }) {
    return loading(reason);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? unauthenticated,
    TResult? Function(String? reason)? loading,
    TResult? Function(FirebaseUserLite user, UserModel profile)? authenticated,
    TResult? Function(String email)? unprovisioned,
    TResult? Function(String email)? disabled,
    TResult? Function(String message, Object? cause)? error,
  }) {
    return loading?.call(reason);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? unauthenticated,
    TResult Function(String? reason)? loading,
    TResult Function(FirebaseUserLite user, UserModel profile)? authenticated,
    TResult Function(String email)? unprovisioned,
    TResult Function(String email)? disabled,
    TResult Function(String message, Object? cause)? error,
    required TResult orElse(),
  }) {
    if (loading != null) {
      return loading(reason);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(SessionUnauthenticated value) unauthenticated,
    required TResult Function(SessionLoading value) loading,
    required TResult Function(SessionAuthenticated value) authenticated,
    required TResult Function(SessionUnprovisioned value) unprovisioned,
    required TResult Function(SessionDisabled value) disabled,
    required TResult Function(SessionError value) error,
  }) {
    return loading(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(SessionUnauthenticated value)? unauthenticated,
    TResult? Function(SessionLoading value)? loading,
    TResult? Function(SessionAuthenticated value)? authenticated,
    TResult? Function(SessionUnprovisioned value)? unprovisioned,
    TResult? Function(SessionDisabled value)? disabled,
    TResult? Function(SessionError value)? error,
  }) {
    return loading?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(SessionUnauthenticated value)? unauthenticated,
    TResult Function(SessionLoading value)? loading,
    TResult Function(SessionAuthenticated value)? authenticated,
    TResult Function(SessionUnprovisioned value)? unprovisioned,
    TResult Function(SessionDisabled value)? disabled,
    TResult Function(SessionError value)? error,
    required TResult orElse(),
  }) {
    if (loading != null) {
      return loading(this);
    }
    return orElse();
  }
}

abstract class SessionLoading implements SessionState {
  const factory SessionLoading({final String? reason}) = _$SessionLoadingImpl;

  String? get reason;
  @JsonKey(ignore: true)
  _$$SessionLoadingImplCopyWith<_$SessionLoadingImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$SessionAuthenticatedImplCopyWith<$Res> {
  factory _$$SessionAuthenticatedImplCopyWith(_$SessionAuthenticatedImpl value,
          $Res Function(_$SessionAuthenticatedImpl) then) =
      __$$SessionAuthenticatedImplCopyWithImpl<$Res>;
  @useResult
  $Res call({FirebaseUserLite user, UserModel profile});

  $FirebaseUserLiteCopyWith<$Res> get user;
  $UserModelCopyWith<$Res> get profile;
}

/// @nodoc
class __$$SessionAuthenticatedImplCopyWithImpl<$Res>
    extends _$SessionStateCopyWithImpl<$Res, _$SessionAuthenticatedImpl>
    implements _$$SessionAuthenticatedImplCopyWith<$Res> {
  __$$SessionAuthenticatedImplCopyWithImpl(_$SessionAuthenticatedImpl _value,
      $Res Function(_$SessionAuthenticatedImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? user = null,
    Object? profile = null,
  }) {
    return _then(_$SessionAuthenticatedImpl(
      user: null == user
          ? _value.user
          : user // ignore: cast_nullable_to_non_nullable
              as FirebaseUserLite,
      profile: null == profile
          ? _value.profile
          : profile // ignore: cast_nullable_to_non_nullable
              as UserModel,
    ));
  }

  @override
  @pragma('vm:prefer-inline')
  $FirebaseUserLiteCopyWith<$Res> get user {
    return $FirebaseUserLiteCopyWith<$Res>(_value.user, (value) {
      return _then(_value.copyWith(user: value));
    });
  }

  @override
  @pragma('vm:prefer-inline')
  $UserModelCopyWith<$Res> get profile {
    return $UserModelCopyWith<$Res>(_value.profile, (value) {
      return _then(_value.copyWith(profile: value));
    });
  }
}

/// @nodoc

class _$SessionAuthenticatedImpl implements SessionAuthenticated {
  const _$SessionAuthenticatedImpl({required this.user, required this.profile});

  @override
  final FirebaseUserLite user;
  @override
  final UserModel profile;

  @override
  String toString() {
    return 'SessionState.authenticated(user: $user, profile: $profile)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SessionAuthenticatedImpl &&
            (identical(other.user, user) || other.user == user) &&
            (identical(other.profile, profile) || other.profile == profile));
  }

  @override
  int get hashCode => Object.hash(runtimeType, user, profile);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$SessionAuthenticatedImplCopyWith<_$SessionAuthenticatedImpl>
      get copyWith =>
          __$$SessionAuthenticatedImplCopyWithImpl<_$SessionAuthenticatedImpl>(
              this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() unauthenticated,
    required TResult Function(String? reason) loading,
    required TResult Function(FirebaseUserLite user, UserModel profile)
        authenticated,
    required TResult Function(String email) unprovisioned,
    required TResult Function(String email) disabled,
    required TResult Function(String message, Object? cause) error,
  }) {
    return authenticated(user, profile);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? unauthenticated,
    TResult? Function(String? reason)? loading,
    TResult? Function(FirebaseUserLite user, UserModel profile)? authenticated,
    TResult? Function(String email)? unprovisioned,
    TResult? Function(String email)? disabled,
    TResult? Function(String message, Object? cause)? error,
  }) {
    return authenticated?.call(user, profile);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? unauthenticated,
    TResult Function(String? reason)? loading,
    TResult Function(FirebaseUserLite user, UserModel profile)? authenticated,
    TResult Function(String email)? unprovisioned,
    TResult Function(String email)? disabled,
    TResult Function(String message, Object? cause)? error,
    required TResult orElse(),
  }) {
    if (authenticated != null) {
      return authenticated(user, profile);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(SessionUnauthenticated value) unauthenticated,
    required TResult Function(SessionLoading value) loading,
    required TResult Function(SessionAuthenticated value) authenticated,
    required TResult Function(SessionUnprovisioned value) unprovisioned,
    required TResult Function(SessionDisabled value) disabled,
    required TResult Function(SessionError value) error,
  }) {
    return authenticated(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(SessionUnauthenticated value)? unauthenticated,
    TResult? Function(SessionLoading value)? loading,
    TResult? Function(SessionAuthenticated value)? authenticated,
    TResult? Function(SessionUnprovisioned value)? unprovisioned,
    TResult? Function(SessionDisabled value)? disabled,
    TResult? Function(SessionError value)? error,
  }) {
    return authenticated?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(SessionUnauthenticated value)? unauthenticated,
    TResult Function(SessionLoading value)? loading,
    TResult Function(SessionAuthenticated value)? authenticated,
    TResult Function(SessionUnprovisioned value)? unprovisioned,
    TResult Function(SessionDisabled value)? disabled,
    TResult Function(SessionError value)? error,
    required TResult orElse(),
  }) {
    if (authenticated != null) {
      return authenticated(this);
    }
    return orElse();
  }
}

abstract class SessionAuthenticated implements SessionState {
  const factory SessionAuthenticated(
      {required final FirebaseUserLite user,
      required final UserModel profile}) = _$SessionAuthenticatedImpl;

  FirebaseUserLite get user;
  UserModel get profile;
  @JsonKey(ignore: true)
  _$$SessionAuthenticatedImplCopyWith<_$SessionAuthenticatedImpl>
      get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$SessionUnprovisionedImplCopyWith<$Res> {
  factory _$$SessionUnprovisionedImplCopyWith(_$SessionUnprovisionedImpl value,
          $Res Function(_$SessionUnprovisionedImpl) then) =
      __$$SessionUnprovisionedImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String email});
}

/// @nodoc
class __$$SessionUnprovisionedImplCopyWithImpl<$Res>
    extends _$SessionStateCopyWithImpl<$Res, _$SessionUnprovisionedImpl>
    implements _$$SessionUnprovisionedImplCopyWith<$Res> {
  __$$SessionUnprovisionedImplCopyWithImpl(_$SessionUnprovisionedImpl _value,
      $Res Function(_$SessionUnprovisionedImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? email = null,
  }) {
    return _then(_$SessionUnprovisionedImpl(
      email: null == email
          ? _value.email
          : email // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class _$SessionUnprovisionedImpl implements SessionUnprovisioned {
  const _$SessionUnprovisionedImpl({required this.email});

  @override
  final String email;

  @override
  String toString() {
    return 'SessionState.unprovisioned(email: $email)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SessionUnprovisionedImpl &&
            (identical(other.email, email) || other.email == email));
  }

  @override
  int get hashCode => Object.hash(runtimeType, email);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$SessionUnprovisionedImplCopyWith<_$SessionUnprovisionedImpl>
      get copyWith =>
          __$$SessionUnprovisionedImplCopyWithImpl<_$SessionUnprovisionedImpl>(
              this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() unauthenticated,
    required TResult Function(String? reason) loading,
    required TResult Function(FirebaseUserLite user, UserModel profile)
        authenticated,
    required TResult Function(String email) unprovisioned,
    required TResult Function(String email) disabled,
    required TResult Function(String message, Object? cause) error,
  }) {
    return unprovisioned(email);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? unauthenticated,
    TResult? Function(String? reason)? loading,
    TResult? Function(FirebaseUserLite user, UserModel profile)? authenticated,
    TResult? Function(String email)? unprovisioned,
    TResult? Function(String email)? disabled,
    TResult? Function(String message, Object? cause)? error,
  }) {
    return unprovisioned?.call(email);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? unauthenticated,
    TResult Function(String? reason)? loading,
    TResult Function(FirebaseUserLite user, UserModel profile)? authenticated,
    TResult Function(String email)? unprovisioned,
    TResult Function(String email)? disabled,
    TResult Function(String message, Object? cause)? error,
    required TResult orElse(),
  }) {
    if (unprovisioned != null) {
      return unprovisioned(email);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(SessionUnauthenticated value) unauthenticated,
    required TResult Function(SessionLoading value) loading,
    required TResult Function(SessionAuthenticated value) authenticated,
    required TResult Function(SessionUnprovisioned value) unprovisioned,
    required TResult Function(SessionDisabled value) disabled,
    required TResult Function(SessionError value) error,
  }) {
    return unprovisioned(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(SessionUnauthenticated value)? unauthenticated,
    TResult? Function(SessionLoading value)? loading,
    TResult? Function(SessionAuthenticated value)? authenticated,
    TResult? Function(SessionUnprovisioned value)? unprovisioned,
    TResult? Function(SessionDisabled value)? disabled,
    TResult? Function(SessionError value)? error,
  }) {
    return unprovisioned?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(SessionUnauthenticated value)? unauthenticated,
    TResult Function(SessionLoading value)? loading,
    TResult Function(SessionAuthenticated value)? authenticated,
    TResult Function(SessionUnprovisioned value)? unprovisioned,
    TResult Function(SessionDisabled value)? disabled,
    TResult Function(SessionError value)? error,
    required TResult orElse(),
  }) {
    if (unprovisioned != null) {
      return unprovisioned(this);
    }
    return orElse();
  }
}

abstract class SessionUnprovisioned implements SessionState {
  const factory SessionUnprovisioned({required final String email}) =
      _$SessionUnprovisionedImpl;

  String get email;
  @JsonKey(ignore: true)
  _$$SessionUnprovisionedImplCopyWith<_$SessionUnprovisionedImpl>
      get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$SessionDisabledImplCopyWith<$Res> {
  factory _$$SessionDisabledImplCopyWith(_$SessionDisabledImpl value,
          $Res Function(_$SessionDisabledImpl) then) =
      __$$SessionDisabledImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String email});
}

/// @nodoc
class __$$SessionDisabledImplCopyWithImpl<$Res>
    extends _$SessionStateCopyWithImpl<$Res, _$SessionDisabledImpl>
    implements _$$SessionDisabledImplCopyWith<$Res> {
  __$$SessionDisabledImplCopyWithImpl(
      _$SessionDisabledImpl _value, $Res Function(_$SessionDisabledImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? email = null,
  }) {
    return _then(_$SessionDisabledImpl(
      email: null == email
          ? _value.email
          : email // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class _$SessionDisabledImpl implements SessionDisabled {
  const _$SessionDisabledImpl({required this.email});

  @override
  final String email;

  @override
  String toString() {
    return 'SessionState.disabled(email: $email)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SessionDisabledImpl &&
            (identical(other.email, email) || other.email == email));
  }

  @override
  int get hashCode => Object.hash(runtimeType, email);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$SessionDisabledImplCopyWith<_$SessionDisabledImpl> get copyWith =>
      __$$SessionDisabledImplCopyWithImpl<_$SessionDisabledImpl>(
          this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() unauthenticated,
    required TResult Function(String? reason) loading,
    required TResult Function(FirebaseUserLite user, UserModel profile)
        authenticated,
    required TResult Function(String email) unprovisioned,
    required TResult Function(String email) disabled,
    required TResult Function(String message, Object? cause) error,
  }) {
    return disabled(email);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? unauthenticated,
    TResult? Function(String? reason)? loading,
    TResult? Function(FirebaseUserLite user, UserModel profile)? authenticated,
    TResult? Function(String email)? unprovisioned,
    TResult? Function(String email)? disabled,
    TResult? Function(String message, Object? cause)? error,
  }) {
    return disabled?.call(email);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? unauthenticated,
    TResult Function(String? reason)? loading,
    TResult Function(FirebaseUserLite user, UserModel profile)? authenticated,
    TResult Function(String email)? unprovisioned,
    TResult Function(String email)? disabled,
    TResult Function(String message, Object? cause)? error,
    required TResult orElse(),
  }) {
    if (disabled != null) {
      return disabled(email);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(SessionUnauthenticated value) unauthenticated,
    required TResult Function(SessionLoading value) loading,
    required TResult Function(SessionAuthenticated value) authenticated,
    required TResult Function(SessionUnprovisioned value) unprovisioned,
    required TResult Function(SessionDisabled value) disabled,
    required TResult Function(SessionError value) error,
  }) {
    return disabled(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(SessionUnauthenticated value)? unauthenticated,
    TResult? Function(SessionLoading value)? loading,
    TResult? Function(SessionAuthenticated value)? authenticated,
    TResult? Function(SessionUnprovisioned value)? unprovisioned,
    TResult? Function(SessionDisabled value)? disabled,
    TResult? Function(SessionError value)? error,
  }) {
    return disabled?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(SessionUnauthenticated value)? unauthenticated,
    TResult Function(SessionLoading value)? loading,
    TResult Function(SessionAuthenticated value)? authenticated,
    TResult Function(SessionUnprovisioned value)? unprovisioned,
    TResult Function(SessionDisabled value)? disabled,
    TResult Function(SessionError value)? error,
    required TResult orElse(),
  }) {
    if (disabled != null) {
      return disabled(this);
    }
    return orElse();
  }
}

abstract class SessionDisabled implements SessionState {
  const factory SessionDisabled({required final String email}) =
      _$SessionDisabledImpl;

  String get email;
  @JsonKey(ignore: true)
  _$$SessionDisabledImplCopyWith<_$SessionDisabledImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$SessionErrorImplCopyWith<$Res> {
  factory _$$SessionErrorImplCopyWith(
          _$SessionErrorImpl value, $Res Function(_$SessionErrorImpl) then) =
      __$$SessionErrorImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String message, Object? cause});
}

/// @nodoc
class __$$SessionErrorImplCopyWithImpl<$Res>
    extends _$SessionStateCopyWithImpl<$Res, _$SessionErrorImpl>
    implements _$$SessionErrorImplCopyWith<$Res> {
  __$$SessionErrorImplCopyWithImpl(
      _$SessionErrorImpl _value, $Res Function(_$SessionErrorImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? message = null,
    Object? cause = freezed,
  }) {
    return _then(_$SessionErrorImpl(
      message: null == message
          ? _value.message
          : message // ignore: cast_nullable_to_non_nullable
              as String,
      cause: freezed == cause ? _value.cause : cause,
    ));
  }
}

/// @nodoc

class _$SessionErrorImpl implements SessionError {
  const _$SessionErrorImpl({required this.message, this.cause});

  @override
  final String message;
  @override
  final Object? cause;

  @override
  String toString() {
    return 'SessionState.error(message: $message, cause: $cause)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SessionErrorImpl &&
            (identical(other.message, message) || other.message == message) &&
            const DeepCollectionEquality().equals(other.cause, cause));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType, message, const DeepCollectionEquality().hash(cause));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$SessionErrorImplCopyWith<_$SessionErrorImpl> get copyWith =>
      __$$SessionErrorImplCopyWithImpl<_$SessionErrorImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() unauthenticated,
    required TResult Function(String? reason) loading,
    required TResult Function(FirebaseUserLite user, UserModel profile)
        authenticated,
    required TResult Function(String email) unprovisioned,
    required TResult Function(String email) disabled,
    required TResult Function(String message, Object? cause) error,
  }) {
    return error(message, cause);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? unauthenticated,
    TResult? Function(String? reason)? loading,
    TResult? Function(FirebaseUserLite user, UserModel profile)? authenticated,
    TResult? Function(String email)? unprovisioned,
    TResult? Function(String email)? disabled,
    TResult? Function(String message, Object? cause)? error,
  }) {
    return error?.call(message, cause);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? unauthenticated,
    TResult Function(String? reason)? loading,
    TResult Function(FirebaseUserLite user, UserModel profile)? authenticated,
    TResult Function(String email)? unprovisioned,
    TResult Function(String email)? disabled,
    TResult Function(String message, Object? cause)? error,
    required TResult orElse(),
  }) {
    if (error != null) {
      return error(message, cause);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(SessionUnauthenticated value) unauthenticated,
    required TResult Function(SessionLoading value) loading,
    required TResult Function(SessionAuthenticated value) authenticated,
    required TResult Function(SessionUnprovisioned value) unprovisioned,
    required TResult Function(SessionDisabled value) disabled,
    required TResult Function(SessionError value) error,
  }) {
    return error(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(SessionUnauthenticated value)? unauthenticated,
    TResult? Function(SessionLoading value)? loading,
    TResult? Function(SessionAuthenticated value)? authenticated,
    TResult? Function(SessionUnprovisioned value)? unprovisioned,
    TResult? Function(SessionDisabled value)? disabled,
    TResult? Function(SessionError value)? error,
  }) {
    return error?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(SessionUnauthenticated value)? unauthenticated,
    TResult Function(SessionLoading value)? loading,
    TResult Function(SessionAuthenticated value)? authenticated,
    TResult Function(SessionUnprovisioned value)? unprovisioned,
    TResult Function(SessionDisabled value)? disabled,
    TResult Function(SessionError value)? error,
    required TResult orElse(),
  }) {
    if (error != null) {
      return error(this);
    }
    return orElse();
  }
}

abstract class SessionError implements SessionState {
  const factory SessionError(
      {required final String message,
      final Object? cause}) = _$SessionErrorImpl;

  String get message;
  Object? get cause;
  @JsonKey(ignore: true)
  _$$SessionErrorImplCopyWith<_$SessionErrorImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
