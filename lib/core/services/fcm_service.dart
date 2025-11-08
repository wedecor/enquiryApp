import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/models/user_model.dart';
import '../../utils/logger.dart';

/// Service for handling Firebase Cloud Messaging (FCM)
class FCMService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Initialize FCM and request permissions
  Future<void> initialize() async {
    try {
      // Request permission for iOS devices
      final NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        Log.i('FCM permission granted', data: {'status': 'authorized'});
      } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
        Log.i('FCM permission granted', data: {'status': 'provisional'});
      } else {
        Log.w(
          'FCM permission denied or not accepted',
          data: {'status': settings.authorizationStatus.name},
        );
        return;
      }

      // Get FCM token
      final String? token = await _messaging.getToken();
      if (token != null) {
        // TODO: Replace with safeLog - Log.i('FCM token retrieved');
        await _saveTokenToUserProfile(token);
      }

      // Listen for token refresh
      _messaging.onTokenRefresh.listen((newToken) {
        _saveTokenToUserProfile(newToken);
      });

      // Subscribe to general topics
      await _subscribeToGeneralTopics();

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Handle background messages
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // Handle notification taps when app is opened from background
      FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

      // Handle notification tap when app is terminated
      final RemoteMessage? initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        _handleMessageOpenedApp(initialMessage);
      }
    } catch (e, st) {
      Log.e('FCM initialization error', error: e, stackTrace: st);
    }
  }

  /// Save FCM token to user profile in Firestore
  Future<void> _saveTokenToUserProfile(String token) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser != null) {
        // Store token in private subcollection for security
        await _firestore
            .collection('users')
            .doc(currentUser.uid)
            .collection('private')
            .doc('notifications')
            .collection('tokens')
            .doc(token)
            .set({
              'token': token,
              'createdAt': FieldValue.serverTimestamp(),
              'lastUpdate': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));
        // TODO: Replace with safeLog - Log.i('FCM: token saved to private collection');
      }
    } catch (e) {
      // TODO: Replace with safeLog - Log.e('FCM: error saving token to user profile');
    }
  }

  /// Subscribe to general topics based on user role
  Future<void> _subscribeToGeneralTopics() async {
    try {
      // Subscribe to general app notifications
      await _messaging.subscribeToTopic('general');

      // Subscribe to role-based topics
      final currentUser = _auth.currentUser;
      if (currentUser != null) {
        final userDoc = await _firestore.collection('users').doc(currentUser.uid).get();

        if (userDoc.exists) {
          final userData = userDoc.data() as Map<String, dynamic>;
          final role = userData['role'] as String?;

          if (role == 'admin') {
            await _messaging.subscribeToTopic('admin');
            await _messaging.subscribeToTopic('enquiries');
          } else {
            await _messaging.subscribeToTopic('staff');
            // Subscribe to personal assignments
            await _messaging.subscribeToTopic('user_${currentUser.uid}');
          }
        }
      }

      Log.i('FCM: subscribed to relevant topics');
    } catch (e, st) {
      Log.e('FCM: error subscribing to topics', error: e, stackTrace: st);
    }
  }

  /// Subscribe user to specific topics based on their role and assignments
  Future<void> subscribeToUserTopics(UserModel user) async {
    try {
      // Unsubscribe from all topics first
      await _messaging.unsubscribeFromTopic('admin');
      await _messaging.unsubscribeFromTopic('staff');
      await _messaging.unsubscribeFromTopic('user_${user.uid}');

      // Subscribe to role-based topics
      if (user.role == UserRole.admin) {
        await _messaging.subscribeToTopic('admin');
        await _messaging.subscribeToTopic('enquiries');
      } else {
        await _messaging.subscribeToTopic('staff');
        // Subscribe to personal assignments
        await _messaging.subscribeToTopic('user_${user.uid}');
      }

      Log.i('FCM: updated topic subscriptions', data: {'uid': user.uid, 'role': user.role.name});
    } catch (e, st) {
      Log.e('FCM: error updating topic subscriptions', error: e, stackTrace: st);
    }
  }

  /// Handle foreground messages
  void _handleForegroundMessage(RemoteMessage message) {
    Log.d('FCM: received foreground message', data: {'messageId': message.messageId});

    // Show local notification for foreground messages
    _showLocalNotification(message);
  }

  /// Handle message when app is opened from background
  void _handleMessageOpenedApp(RemoteMessage message) {
    Log.d('FCM: app opened from notification', data: {'messageId': message.messageId});

    // Handle navigation based on message data
    _handleNotificationNavigation(message);
  }

  /// Show local notification for foreground messages
  void _showLocalNotification(RemoteMessage message) {
    // TODO: Implement local notification display using flutter_local_notifications
    Log.d('FCM: would show local notification', data: {'title': message.notification?.title});
  }

  /// Handle navigation based on notification data
  void _handleNotificationNavigation(RemoteMessage message) {
    final data = message.data;

    // Handle different notification types
    switch (data['type']) {
      case 'new_enquiry':
        // Navigate to enquiry details
        Log.d('FCM: navigate to enquiry', data: {'enquiryId': data['enquiryId']});
        break;
      case 'enquiry_assigned':
        // Navigate to assigned enquiry
        Log.d('FCM: navigate to assigned enquiry', data: {'enquiryId': data['enquiryId']});
        break;
      case 'status_update':
        // Navigate to updated enquiry
        Log.d('FCM: navigate to updated enquiry', data: {'enquiryId': data['enquiryId']});
        break;
      default:
        // Navigate to dashboard or general area
        Log.d('FCM: navigate to general area');
        break;
    }
  }

  /// Get current FCM token
  Future<String?> getToken() async {
    return await _messaging.getToken();
  }

  /// Unsubscribe from all topics (for logout)
  Future<void> unsubscribeFromAllTopics() async {
    try {
      await _messaging.unsubscribeFromTopic('general');
      await _messaging.unsubscribeFromTopic('admin');
      await _messaging.unsubscribeFromTopic('staff');
      await _messaging.unsubscribeFromTopic('enquiries');

      // Unsubscribe from personal topic
      final currentUser = _auth.currentUser;
      if (currentUser != null) {
        await _messaging.unsubscribeFromTopic('user_${currentUser.uid}');
      }

      Log.i('FCM: unsubscribed from all topics');
    } catch (e, st) {
      Log.e('FCM: error unsubscribing from topics', error: e, stackTrace: st);
    }
  }

  /// Delete FCM token from private collection (for logout)
  Future<void> deleteTokenFromProfile() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser != null) {
        final token = await FirebaseMessaging.instance.getToken();
        if (token != null) {
          // Delete token from private subcollection
          await _firestore
              .collection('users')
              .doc(currentUser.uid)
              .collection('private')
              .doc('notifications')
              .collection('tokens')
              .doc(token)
              .delete();
          // TODO: Replace with safeLog - Log.i('FCM: token deleted from private collection');
        }
      }
    } catch (e) {
      // TODO: Replace with safeLog - Log.e('FCM: error deleting token from user profile');
    }
  }
}

/// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  Log.d('FCM: handling background message', data: {'messageId': message.messageId});

  // Handle background message processing
  // This could include updating local storage, triggering sync, etc.
}

/// Riverpod providers for FCM service
final fcmServiceProvider = Provider<FCMService>((ref) {
  return FCMService();
});

/// Provider for FCM initialization
final fcmInitializedProvider = FutureProvider<bool>((ref) async {
  final fcmService = ref.read(fcmServiceProvider);
  await fcmService.initialize();
  return true;
});
