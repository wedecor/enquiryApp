import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/widgets.dart';

import '../logging/logger.dart';
import '../services/firestore_service.dart';
import 'notification_router.dart';

class FcmTokenManager {
  static bool _listenersRegistered = false;
  static bool _tokenSaved = false;
  static bool _registering = false;
  static FirestoreService? _firestoreService;
  static StreamSubscription<String>? _tokenRefreshSubscription;
  static StreamSubscription<RemoteMessage>? _foregroundSubscription;
  static StreamSubscription<RemoteMessage>? _openedSubscription;

  static const String _vapidKey = String.fromEnvironment(
    'VAPID_PUBLIC_KEY',
    defaultValue:
        'BKmvRVlG_poi0It85Ooupfs2e8ylBJ4me4TLUhqiIVC7OSnxXK1ctR1gGP1emUgaJJ8z7MzHgZFCe5MsMWnIY7E',
  );

  static const int _maxTokenAttempts = 3;
  static const Duration _tokenTimeout = Duration(seconds: 20);

  /// Wires push listeners (once per process) and saves this device's token for
  /// the signed-in user. Never throws: failures are logged and retried.
  static Future<void> ensureFcmRegistered(FirestoreService firestoreService) async {
    _firestoreService = firestoreService;

    // Listeners first, so a token failure never costs banners or tap-to-open.
    try {
      await _registerListenersOnce();
    } catch (e, st) {
      Log.e('FcmTokenManager: failed to register listeners', error: e, stackTrace: st);
    }

    if (_tokenSaved || _registering) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    _registering = true;
    try {
      await FirebaseMessaging.instance.requestPermission(alert: true, badge: true, sound: true);
    } catch (e) {
      Log.w('FcmTokenManager: permission request failed', data: {'error': e.toString()});
    }

    try {
      for (var attempt = 1; attempt <= _maxTokenAttempts; attempt++) {
        try {
          // getToken can hang while Play services is still starting; time out so the
          // retry loop (and the _registering guard) can't stay stuck for the whole session.
          final token = await FirebaseMessaging.instance
              .getToken(vapidKey: _vapidKey)
              .timeout(_tokenTimeout);
          if (token == null) return;
          // The user may have signed out while we were waiting.
          final current = FirebaseAuth.instance.currentUser;
          if (current == null || current.uid != user.uid) return;
          await firestoreService.saveFcmToken(user.uid, token);
          _tokenSaved = true;
          return;
        } catch (e, st) {
          if (attempt == _maxTokenAttempts) {
            Log.e(
              'FcmTokenManager: could not fetch/save FCM token',
              error: e,
              stackTrace: st,
              data: {'attempts': attempt},
            );
            return;
          }
          await Future<void>.delayed(Duration(seconds: 2 * attempt));
        }
      }
    } finally {
      _registering = false;
    }
  }

  static Future<void> _registerListenersOnce() async {
    if (_listenersRegistered) return;
    _listenersRegistered = true;

    // Foreground pushes are not shown by the OS — show an in-app banner instead.
    _foregroundSubscription = FirebaseMessaging.onMessage.listen(NotificationRouter.showForeground);

    // Tapping a push opens the enquiry it refers to.
    _openedSubscription = FirebaseMessaging.onMessageOpenedApp.listen(NotificationRouter.open);

    // A refreshed token belongs to whoever is signed in now.
    _tokenRefreshSubscription = FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      final currentUser = FirebaseAuth.instance.currentUser;
      final service = _firestoreService;
      if (currentUser == null || service == null) return;
      try {
        await service.saveFcmToken(currentUser.uid, newToken, refreshed: true);
      } catch (e, st) {
        Log.e('FcmTokenManager: failed to save refreshed token', error: e, stackTrace: st);
      }
    });

    final initial = await FirebaseMessaging.instance.getInitialMessage();
    if (initial != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => NotificationRouter.open(initial));
    }
  }

  /// Removes this device's token for the signed-in user, then deletes the token
  /// itself so the next user on this device gets a fresh one. Call BEFORE
  /// `FirebaseAuth.signOut()` (the token doc is owner-only).
  static Future<void> removeCurrentToken(FirestoreService firestoreService) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final token = await FirebaseMessaging.instance.getToken(vapidKey: _vapidKey);
        if (token != null) {
          await firestoreService.deleteFcmToken(user.uid, token);
        }
      }
    } catch (e) {
      Log.w('FcmTokenManager: failed to delete token doc', data: {'error': e.toString()});
    }

    try {
      await FirebaseMessaging.instance.deleteToken();
    } catch (e) {
      Log.w('FcmTokenManager: failed to delete FCM token', data: {'error': e.toString()});
    }
    _tokenSaved = false;
  }

  /// Called when the user signs out: the next sign-in saves its token again.
  /// Listeners stay registered for the life of the process.
  static Future<void> dispose() async {
    _tokenSaved = false;
  }

  /// Full teardown (app root disposed): cancels listeners so a later
  /// [ensureFcmRegistered] wires them again.
  static Future<void> cancelListeners() async {
    await _tokenRefreshSubscription?.cancel();
    _tokenRefreshSubscription = null;
    await _foregroundSubscription?.cancel();
    _foregroundSubscription = null;
    await _openedSubscription?.cancel();
    _openedSubscription = null;
    _listenersRegistered = false;
    _tokenSaved = false;
  }
}
