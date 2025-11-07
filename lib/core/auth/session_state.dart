import 'package:freezed_annotation/freezed_annotation.dart';
import '../../shared/models/user_model.dart';

part 'session_state.freezed.dart';

/// Minimal Firebase user data to avoid exposing full User object
@freezed
class FirebaseUserLite with _$FirebaseUserLite {
  const factory FirebaseUserLite({
    required String uid,
    required String email,
    @Default(false) bool isEmailVerified,
  }) = _FirebaseUserLite;
}

/// Complete session state for robust authentication handling
@freezed
class SessionState with _$SessionState {
  /// User is not signed in
  const factory SessionState.unauthenticated() = SessionUnauthenticated;

  /// Loading state with optional reason
  const factory SessionState.loading({String? reason}) = SessionLoading;

  /// User is authenticated with complete profile
  const factory SessionState.authenticated({
    required FirebaseUserLite user,
    required UserModel profile,
  }) = SessionAuthenticated;

  /// User is signed in but has no Firestore profile
  const factory SessionState.unprovisioned({required String email}) = SessionUnprovisioned;

  /// User profile exists but is disabled
  const factory SessionState.disabled({required String email}) = SessionDisabled;

  /// Error state with message and optional cause
  const factory SessionState.error({required String message, Object? cause}) = SessionError;
}

/// Extension methods for SessionState
extension SessionStateExtensions on SessionState {
  /// Whether the user is authenticated and active
  bool get isAuthenticated => when(
    unauthenticated: () => false,
    loading: (_) => false,
    authenticated: (_, __) => true,
    unprovisioned: (_) => false,
    disabled: (_) => false,
    error: (_, __) => false,
  );

  /// Whether the user is signed in (but may not be provisioned/active)
  bool get isSignedIn => when(
    unauthenticated: () => false,
    loading: (_) => false,
    authenticated: (_, __) => true,
    unprovisioned: (_) => true,
    disabled: (_) => true,
    error: (_, __) => false,
  );

  /// Get the current user's email if available
  String? get email => when(
    unauthenticated: () => null,
    loading: (_) => null,
    authenticated: (user, _) => user.email,
    unprovisioned: (email) => email,
    disabled: (email) => email,
    error: (_, __) => null,
  );

  /// Get the current user's UID if authenticated
  String? get uid => when(
    unauthenticated: () => null,
    loading: (_) => null,
    authenticated: (user, _) => user.uid,
    unprovisioned: (_) => null,
    disabled: (_) => null,
    error: (_, __) => null,
  );

  /// Get the user's role if authenticated
  UserRole? get role => when(
    unauthenticated: () => null,
    loading: (_) => null,
    authenticated: (_, profile) => profile.role,
    unprovisioned: (_) => null,
    disabled: (_) => null,
    error: (_, __) => null,
  );
}


