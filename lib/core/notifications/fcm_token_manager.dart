import 'dart:developer';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Minimal FCM token manager for push notifications
class FcmTokenManager {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Replace with your actual VAPID key from Firebase Console > Cloud Messaging > Web Push certificates
  static const String _vapidKey = "YOUR_VAPID_KEY_HERE";
  
  /// Ensure FCM is registered for the current user (call after successful sign-in)
  static Future<void> ensureFcmRegistered() async {
    final user = _auth.currentUser;
    if (user == null) {
      log('FCM: No authenticated user, skipping registration');
      return;
    }

    try {
      // Request permission (important for web)
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus != AuthorizationStatus.authorized) {
        log('FCM: Permission denied');
        return;
      }

      // Get FCM token with VAPID key for web
      final token = kIsWeb 
          ? await _messaging.getToken(vapidKey: _vapidKey)
          : await _messaging.getToken();

      if (token != null) {
        await _storeTokenForUser(user.uid, token);
        log('FCM: Token registered for user ${user.uid}');
        
        // Listen for token refresh
        _messaging.onTokenRefresh.listen((newToken) {
          _storeTokenForUser(user.uid, newToken);
          log('FCM: Token refreshed for user ${user.uid}');
        });

        // Handle foreground messages with in-app snackbar/toast
        FirebaseMessaging.onMessage.listen((message) {
          log('FCM: Foreground message: ${message.notification?.title}');
          // You can show an in-app snackbar here if needed
        });
      }

    } catch (e) {
      log('FCM: Error registering token: $e');
    }
  }

  /// Store FCM token in Firestore
  static Future<void> _storeTokenForUser(String uid, String token) async {
    try {
      await _firestore.collection('users').doc(uid).set({
        'fcmToken': token,
        'webTokens': FieldValue.arrayUnion([token]),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      
      log('FCM: Token stored for user $uid');
    } catch (e) {
      log('FCM: Error storing token: $e');
    }
  }

  /// Remove token on sign out (optional cleanup)
  static Future<void> removeTokenOnSignOut() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final token = await _messaging.getToken();
      if (token != null) {
        await _firestore.collection('users').doc(user.uid).update({
          'webTokens': FieldValue.arrayRemove([token]),
        });
        log('FCM: Token removed on sign out');
      }
    } catch (e) {
      log('FCM: Error removing token: $e');
    }
  }
}
