import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../services/firestore_service.dart';

class FcmTokenManager {
  static bool _registered = false;
  static StreamSubscription<String>? _tokenRefreshSubscription;

  static Future<void> ensureFcmRegistered(FirestoreService firestoreService) async {
    if (_registered) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseMessaging.instance.requestPermission(alert: true, badge: true, sound: true);

    const vapidKey = String.fromEnvironment(
      'VAPID_PUBLIC_KEY',
      defaultValue:
          'BKmvRVlG_poi0It85Ooupfs2e8ylBJ4me4TLUhqiIVC7OSnxXK1ctR1gGP1emUgaJJ8z7MzHgZFCe5MsMWnIY7E',
    );

    final token = await FirebaseMessaging.instance.getToken(vapidKey: vapidKey);
    if (token == null) return;

    await firestoreService.saveFcmToken(user.uid, token);

    FirebaseMessaging.onMessage.listen((RemoteMessage m) {
      // Optional in-app foreground handling
    });

    await _tokenRefreshSubscription?.cancel();
    _tokenRefreshSubscription = FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;
      await firestoreService.saveFcmToken(currentUser.uid, newToken, refreshed: true);
    });

    _registered = true;
  }

  static Future<void> removeCurrentToken(FirestoreService firestoreService) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final token = await FirebaseMessaging.instance.getToken();
      if (token == null) return;

      await firestoreService.deleteFcmToken(user.uid, token);
    } catch (_) {
      // Ignore cleanup errors
    }
  }

  static Future<void> dispose() async {
    await _tokenRefreshSubscription?.cancel();
    _tokenRefreshSubscription = null;
    _registered = false;
  }
}
