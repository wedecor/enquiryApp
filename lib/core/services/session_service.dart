import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/models/user_model.dart';
import '../auth/session_state.dart';
import '../logging/safe_log.dart';
import 'firestore_service.dart';

/// Returns false when the Firestore profile marks the user inactive.
@visibleForTesting
bool isProfileActive(Map<String, dynamic> data) {
  final isActive = data['isActive'] ?? data['active'] ?? true;
  return isActive != false;
}

/// Builds the session [UserModel] from a `users/{uid}` document, tolerating
/// legacy/hand-edited docs: missing `name`/`email`, role in any case
/// (`'Admin'`), non-string phone. Unknown roles fall back to staff.
@visibleForTesting
UserModel parseSessionProfile(String uid, Map<String, dynamic> data, {String? fallbackEmail}) {
  String? str(Object? v) {
    if (v == null) return null;
    final text = v.toString().trim();
    return text.isEmpty ? null : text;
  }

  final email = str(data['email']) ?? fallbackEmail ?? '';
  final name = str(data['name']) ?? str(data['displayName']) ?? email.split('@').first;
  final role = str(data['role'])?.toLowerCase() == 'admin' ? UserRole.admin : UserRole.staff;

  return UserModel(uid: uid, name: name, email: email, phone: str(data['phone']), role: role);
}

class SessionService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirestoreService _firestoreService;

  SessionService(this._firestoreService);

  FirebaseFirestore get _firestore => _firestoreService.firestore;

  StreamController<SessionState>? _sessionController;
  StreamSubscription<User?>? _authSubscription;
  Stream<SessionState>? _sessionStream;
  Timer? _debounceTimer;
  User? _lastUser;

  /// Live listener on `users/{uid}` for the signed-in user, so deactivation
  /// and provisioning take effect without restarting the app.
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _profileSubscription;
  SessionState? _lastEmitted;

  /// Stream of session states with debouncing and profile fetching.
  Stream<SessionState> get sessionStream => _sessionStream ??= _bindSessionStream();

  Stream<SessionState> _bindSessionStream() {
    _sessionController = StreamController<SessionState>.broadcast();
    _authSubscription = _auth.authStateChanges().listen(_handleAuthStateChange);
    // Emit immediately from cached auth — don't wait on splash for first stream event.
    final currentUser = _auth.currentUser;
    if (currentUser != null) {
      _handleAuthStateChange(currentUser);
    } else {
      _emitSessionState(const SessionState.unauthenticated());
    }
    return _sessionController!.stream;
  }

  void _handleAuthStateChange(User? user) {
    // Cancel any pending debounce
    _debounceTimer?.cancel();

    // If user is null, emit immediately
    if (user == null) {
      _cancelProfileSubscription();
      _lastUser = null;
      _emitSessionState(const SessionState.unauthenticated());
      safeLog('session_transition', {'outcome': 'unauthenticated', 'reason': 'auth_user_null'});
      return;
    }

    // If user is the same as last, skip processing
    if (_lastUser?.uid == user.uid) {
      return;
    }

    // A different user: stop listening to the previous user's profile.
    _cancelProfileSubscription();

    // Debounce rapid auth changes
    _debounceTimer = Timer(const Duration(milliseconds: 400), () {
      _lastUser = user;
      _processAuthenticatedUser(user);
    });
  }

  Future<void> _processAuthenticatedUser(User user) async {
    final userLite = FirebaseUserLite(
      uid: user.uid,
      email: user.email ?? '',
      isEmailVerified: user.emailVerified,
    );

    // Emit loading state
    _emitSessionState(const SessionState.loading(reason: 'sync_profile'));

    safeLog('session_transition', {
      'outcome': 'loading',
      'reason': 'sync_profile',
      'emailPrefix': _emailPrefix(user.email),
      'emailVerified': user.emailVerified,
    });

    try {
      // Fetch profile with exponential backoff
      final fetchResult = await _fetchProfileWithBackoff(user.uid, user.email);
      final profile = fetchResult.profile;
      final rawData = fetchResult.rawData;

      // Signed out or switched user while fetching: drop the stale result.
      if (_lastUser?.uid != user.uid) return;

      // From here on, react to changes of users/{uid} (deactivation,
      // reactivation, provisioning, role changes).
      _listenToProfile(user, userLite);

      if (profile == null) {
        _emitSessionState(SessionState.unprovisioned(email: user.email ?? ''));
        safeLog('session_transition', {
          'outcome': 'unprovisioned',
          'emailPrefix': _emailPrefix(user.email),
          'uid': user.uid,
        });
        return;
      }

      if (rawData != null && !isProfileActive(rawData)) {
        _emitSessionState(SessionState.disabled(email: user.email ?? ''));
        safeLog('session_transition', {
          'outcome': 'disabled',
          'emailPrefix': _emailPrefix(user.email),
          'uid': user.uid,
        });
        return;
      }

      _emitSessionState(SessionState.authenticated(user: userLite, profile: profile));

      safeLog('session_transition', {
        'outcome': 'authenticated',
        'emailPrefix': _emailPrefix(user.email),
        'role': profile.role.name,
        'uid': user.uid,
      });
    } catch (e, stackTrace) {
      if (_lastUser?.uid != user.uid) return;
      _emitSessionState(SessionState.error(message: 'Failed to load user profile', cause: e));

      safeLog('session_transition_error', {
        'outcome': 'error',
        'emailPrefix': _emailPrefix(user.email),
        'error': e.toString(),
        'hasStackTrace': stackTrace.toString().isNotEmpty,
      });
    }
  }

  /// Fetch user profile with exponential backoff
  Future<({UserModel? profile, Map<String, dynamic>? rawData})> _fetchProfileWithBackoff(
    String uid,
    String? authEmail,
  ) async {
    const delays = [250, 500, 1000, 2000, 4000]; // ~7.75s total

    for (int attempt = 0; attempt < delays.length; attempt++) {
      try {
        final doc = await _firestore
            .collection('users')
            .doc(uid)
            .get()
            .timeout(const Duration(seconds: 15));

        if (doc.exists) {
          final data = doc.data();
          if (data != null) {
            return (
              profile: parseSessionProfile(uid, data, fallbackEmail: authEmail),
              rawData: data,
            );
          }
        }

        // If not found and this is the last attempt, return null
        if (attempt == delays.length - 1) {
          return (profile: null, rawData: null);
        }

        // Wait before next attempt
        await Future<void>.delayed(Duration(milliseconds: delays[attempt]));

        safeLog('profile_fetch_retry', {
          'attempt': attempt + 1,
          'nextDelayMs': delays[attempt],
          'uid': uid,
        });
      } catch (e) {
        // On error, wait and retry unless it's the last attempt
        if (attempt == delays.length - 1) {
          rethrow;
        }

        await Future<void>.delayed(Duration(milliseconds: delays[attempt]));

        safeLog('profile_fetch_error_retry', {
          'attempt': attempt + 1,
          'error': e.toString(),
          'uid': uid,
        });
      }
    }

    return (profile: null, rawData: null);
  }

  /// Subscribes to `users/{uid}` and maps each snapshot to a session state:
  /// missing doc → unprovisioned, inactive → disabled, otherwise
  /// authenticated (with the fresh profile). Identical states are not
  /// re-emitted.
  void _listenToProfile(User user, FirebaseUserLite userLite) {
    _cancelProfileSubscription();
    final email = user.email ?? '';
    _profileSubscription = _firestore
        .collection('users')
        .doc(user.uid)
        .snapshots()
        .listen(
          (doc) {
            if (_lastUser?.uid != user.uid) return;

            final SessionState next;
            final data = doc.data();
            if (!doc.exists || data == null) {
              // A cache-only "missing" result is not authoritative.
              if (doc.metadata.isFromCache) return;
              next = SessionState.unprovisioned(email: email);
            } else if (!isProfileActive(data)) {
              next = SessionState.disabled(email: email);
            } else {
              next = SessionState.authenticated(
                user: userLite,
                profile: parseSessionProfile(user.uid, data, fallbackEmail: user.email),
              );
            }

            if (next == _lastEmitted) return;
            _emitSessionState(next);
            safeLog('session_transition', {
              'outcome': next.map(
                unauthenticated: (_) => 'unauthenticated',
                loading: (_) => 'loading',
                authenticated: (_) => 'authenticated',
                unprovisioned: (_) => 'unprovisioned',
                disabled: (_) => 'disabled',
                error: (_) => 'error',
              ),
              'reason': 'profile_snapshot',
              'uid': user.uid,
            });
          },
          onError: (Object e, StackTrace st) {
            if (_lastUser?.uid != user.uid) return;
            safeLog('session_profile_listen_error', {'error': e.toString(), 'uid': user.uid});
            // Losing read access to our own profile means the account was
            // deactivated (rules require an active user).
            if (e is FirebaseException && e.code == 'permission-denied') {
              _emitSessionState(SessionState.disabled(email: email));
            }
          },
        );
  }

  void _cancelProfileSubscription() {
    _profileSubscription?.cancel();
    _profileSubscription = null;
  }

  void _emitSessionState(SessionState state) {
    if (_sessionController != null && !_sessionController!.isClosed) {
      _lastEmitted = state;
      _sessionController!.add(state);
    }
  }

  /// Get email prefix for logging (first 3 chars + @domain)
  String _emailPrefix(String? email) {
    if (email == null || email.isEmpty) return 'unknown';
    final parts = email.split('@');
    if (parts.length != 2) return 'invalid';
    final prefix = parts[0].length > 3 ? '${parts[0].substring(0, 3)}***' : '***';
    return '$prefix@${parts[1]}';
  }

  void dispose() {
    _debounceTimer?.cancel();
    _debounceTimer = null;
    _cancelProfileSubscription();
    _lastEmitted = null;
    _authSubscription?.cancel();
    _authSubscription = null;
    _sessionController?.close();
    _sessionController = null;
    _sessionStream = null;
    _lastUser = null;
  }
}

/// Riverpod provider for session service
final sessionServiceProvider = Provider<SessionService>((ref) {
  final service = SessionService(ref.watch(firestoreServiceProvider));
  ref.onDispose(() => service.dispose());
  return service;
});

/// Stream provider for session state
final sessionStateProvider = StreamProvider<SessionState>((ref) {
  final service = ref.watch(sessionServiceProvider);
  return service.sessionStream;
});
