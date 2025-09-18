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
      alert: true, badge: true, sound: true,
    );

    // VAPID public key from Firebase Console
    const vapidKey = 'BKmvRVlG_poi0It85Ooupfs2e8ylBJ4me4TLUhqiIVC7OSnxXK1ctR1gGP1emUgaJJ8z7MzHgZFCe5MsMWnIY7E';

    final token = await FirebaseMessaging.instance.getToken(vapidKey: vapidKey);
    if (token == null) return;

    final doc = FirebaseFirestore.instance.collection('users').doc(user.uid);
    await doc.set({
      'fcmToken': token,
      'webTokens': FieldValue.arrayUnion([token]),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    // Foreground handler (optional)
    FirebaseMessaging.onMessage.listen((RemoteMessage m) {
      // TODO: show a snackbar/toast in-app if desired
      // debugPrint('🔔 ${m.notification?.title ?? "Update"}: ${m.notification?.body ?? ""}');
    });

    // Token refresh
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      await doc.set({
        'fcmToken': newToken,
        'webTokens': FieldValue.arrayUnion([newToken]),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    });

    _registered = true;
  }
}