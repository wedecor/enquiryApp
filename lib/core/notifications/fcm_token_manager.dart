import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class FcmTokenManager {
  static bool _registered = false;

  static Future<void> ensureFcmRegistered() async {
    if (_registered) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Web permission prompt
    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // VAPID public key from environment configuration
    const vapidKey = String.fromEnvironment(
      'VAPID_PUBLIC_KEY',
      defaultValue:
          'BKmvRVlG_poi0It85Ooupfs2e8ylBJ4me4TLUhqiIVC7OSnxXK1ctR1gGP1emUgaJJ8z7MzHgZFCe5MsMWnIY7E',
    );

    final token = await FirebaseMessaging.instance.getToken(vapidKey: vapidKey);
    if (token == null) return;

    // NEW: Store tokens in private subcollection (owner-only access)
    final tokensCollection = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('private')
        .doc('notifications')
        .collection('tokens');

    // Use the token as the doc ID for idempotency
    await tokensCollection.doc(token).set({
      'token': token,
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    // Foreground handler (optional)
    FirebaseMessaging.onMessage.listen((RemoteMessage m) {
      // TODO: show a snackbar/toast in-app if desired
      // debugPrint('🔔 ${m.notification?.title ?? "Update"}: ${m.notification?.body ?? ""}');
    });

    // Token refresh - update private collection
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      await tokensCollection.doc(newToken).set({
        'token': newToken,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    });

    _registered = true;
  }

  /// Optional: Clean up token on sign-out
  static Future<void> removeCurrentToken() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final token = await FirebaseMessaging.instance.getToken();
      if (token == null) return;

      // Remove from private collection
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('private')
          .doc('notifications')
          .collection('tokens')
          .doc(token)
          .delete();
    } catch (e) {
      // Ignore cleanup errors
    }
  }
}
