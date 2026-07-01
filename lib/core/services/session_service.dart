import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/models/user_model.dart';
import '../auth/session_state.dart';
import '../logging/safe_log.dart';
import 'firestore_service.dart';

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
      _lastUser = null;
      _emitSessionState(const SessionState.unauthenticated());
      safeLog('session_transition', {'outcome': 'unauthenticated', 'reason': 'auth_user_null'});
      return;
    }

    // If user is the same as last, skip processing
    if (_lastUser?.uid == user.uid) {
      return;
    }

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
      final profile = await _fetchProfileWithBackoff(user.uid);

      if (profile == null) {
        _emitSessionState(SessionState.unprovisioned(email: user.email ?? ''));
        safeLog('session_transition', {
          'outcome': 'unprovisioned',
          'emailPrefix': _emailPrefix(user.email),
          'uid': user.uid,
        });
        return;
      }

      // Note: UserModel doesn't have active field in current implementation
      // If needed, check if user exists in a disabled users collection
      // For now, assume all found profiles are active

      _emitSessionState(SessionState.authenticated(user: userLite, profile: profile));

      safeLog('session_transition', {
        'outcome': 'authenticated',
        'emailPrefix': _emailPrefix(user.email),
        'role': profile.role.name,
        'uid': user.uid,
      });
    } catch (e, stackTrace) {
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
  Future<UserModel?> _fetchProfileWithBackoff(String uid) async {
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
            return UserModel.fromJson({'uid': uid, ...data});
          }
        }

        // If not found and this is the last attempt, return null
        if (attempt == delays.length - 1) {
          return null;
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

    return null;
  }

  void _emitSessionState(SessionState state) {
    if (_sessionController != null && !_sessionController!.isClosed) {
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
