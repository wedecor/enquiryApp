import 'dart:developer';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Manages FCM token lifecycle for the current user
class FcmTokenManager {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  
  static String? _currentToken;
  static bool _isInitialized = false;

  /// Initialize FCM and request permissions
  static Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      // Request permission (especially important for web and iOS)
      final settings = await _messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      log('FCM: Permission granted: ${settings.authorizationStatus}');

      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        
        // Get initial token
        await _updateToken();
        
        // Listen for token refresh
        _messaging.onTokenRefresh.listen(_onTokenRefresh);
        
        // Handle foreground messages
        FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
        
        _isInitialized = true;
        log('FCM: Initialized successfully');
      } else {
        log('FCM: Permission denied');
      }
    } catch (e) {
      log('FCM: Error initializing: $e');
    }
  }

  /// Ensure FCM is registered for the current user (call after login)
  static Future<void> ensureFcmRegistered() async {
    final user = _auth.currentUser;
    if (user == null) {
      log('FCM: No authenticated user, skipping registration');
      return;
    }

    try {
      await initialize();
      
      if (_currentToken != null) {
        await _storeTokenForUser(user.uid, _currentToken!);
        log('FCM: Token registered for user ${user.uid}');
      }
    } catch (e) {
      log('FCM: Error ensuring registration: $e');
    }
  }

  /// Update FCM token and store it
  static Future<void> _updateToken() async {
    try {
      final token = await _messaging.getToken();
      if (token != null) {
        _currentToken = token;
        
        final user = _auth.currentUser;
        if (user != null) {
          await _storeTokenForUser(user.uid, token);
        }
        
        log('FCM: Token updated: ${token.substring(0, 20)}...');
      }
    } catch (e) {
      log('FCM: Error updating token: $e');
    }
  }

  /// Handle token refresh
  static Future<void> _onTokenRefresh(String token) async {
    log('FCM: Token refreshed');
    _currentToken = token;
    
    final user = _auth.currentUser;
    if (user != null) {
      await _storeTokenForUser(user.uid, token);
    }
  }

  /// Store token in Firestore for the user
  static Future<void> _storeTokenForUser(String uid, String token) async {
    try {
      final userDoc = _firestore.collection('users').doc(uid);
      
      await userDoc.set({
        'fcmToken': token,
        'webTokens': FieldValue.arrayUnion([token]),
        'lastTokenUpdate': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      
      log('FCM: Token stored for user $uid');
    } catch (e) {
      log('FCM: Error storing token: $e');
    }
  }

  /// Remove token on sign out
  static Future<void> removeTokenOnSignOut() async {
    final user = _auth.currentUser;
    if (user == null || _currentToken == null) return;

    try {
      final userDoc = _firestore.collection('users').doc(user.uid);
      
      await userDoc.update({
        'webTokens': FieldValue.arrayRemove([_currentToken!]),
      });
      
      log('FCM: Token removed on sign out');
    } catch (e) {
      log('FCM: Error removing token: $e');
    }
    
    _currentToken = null;
  }

  /// Handle foreground messages
  static void _handleForegroundMessage(RemoteMessage message) {
    log('FCM: Foreground message received: ${message.notification?.title}');
    
    // You can show in-app notifications here
    // For now, we'll just log it
    if (message.notification != null) {
      log('FCM: Title: ${message.notification!.title}');
      log('FCM: Body: ${message.notification!.body}');
    }
  }

  /// Get current FCM token
  static String? get currentToken => _currentToken;
  
  /// Check if FCM is initialized
  static bool get isInitialized => _isInitialized;
}
