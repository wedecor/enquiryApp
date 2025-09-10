import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class MessagingService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  
  static Future<void> initialize() async {
    try {
      // Request permission
      await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      
      // Get FCM token
      final token = await _messaging.getToken();
      if (token != null) {
        await _addTokenToUser(token);
      }
      
      // Listen for token refresh
      _messaging.onTokenRefresh.listen(_addTokenToUser);
    } catch (e) {
      if (kDebugMode) {
        print('Messaging initialization error: $e');
      }
      // Continue without messaging for demo purposes
    }
  }
  
  static Future<void> _addTokenToUser(String token) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    
    await _db.collection('users').doc(user.uid).update({
      'fcmTokens': FieldValue.arrayUnion([token]),
    });
  }
  
  static Future<void> subscribeToTopics(List<String> topics) async {
    for (final topic in topics) {
      await _messaging.subscribeToTopic(topic);
    }
  }
  
  static Future<void> unsubscribeFromTopics(List<String> topics) async {
    for (final topic in topics) {
      await _messaging.unsubscribeFromTopic(topic);
    }
  }
}