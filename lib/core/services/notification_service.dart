import 'package:cloud_firestore/cloud_firestore.dart';
import '../../shared/models/user_model.dart';

/// Service for managing notification triggers and sending notifications
class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Rate limiting configuration
  static const int _maxNotificationsPerMinute = 5;
  static const int _maxNotificationsPerHour = 20;
  static const int _maxNotificationsPerDay = 100;
  
  // Cache for rate limiting (in-memory, will reset on app restart)
  final Map<String, List<DateTime>> _notificationHistory = {};

  /// Send notification when a new enquiry is created
  Future<void> notifyEnquiryCreated({
    required String enquiryId,
    required String customerName,
    required String eventType,
    required String createdBy,
  }) async {
    try {
      // Get all admin users except the creator
      final adminUsers = await _getAdminUsers(excludeUserId: createdBy);

      // Send notification to all admins
      for (final admin in adminUsers) {
        await _sendNotificationToUser(
          userId: admin.uid,
          title: 'New Enquiry Created',
          body: 'New enquiry from $customerName for $eventType',
          data: {
            'type': 'new_enquiry',
            'enquiryId': enquiryId,
            'customerName': customerName,
            'eventType': eventType,
            'createdBy': createdBy,
          },
          notificationType: 'new_enquiry',
          isImportant: true, // New enquiries are important
        );
      }

      // Also send to general admin topic
      await _sendNotificationToTopic(
        topic: 'admins',
        title: 'New Enquiry Created',
        body: 'New enquiry from $customerName for $eventType',
        data: {
          'type': 'new_enquiry',
          'enquiryId': enquiryId,
          'customerName': customerName,
          'eventType': eventType,
          'createdBy': createdBy,
        },
      );

      print('NotificationService: Sent new enquiry notifications to ${adminUsers.length} admins');
    } catch (e) {
      print('NotificationService: Error sending new enquiry notifications: $e');
    }
  }

  /// Send notification when an enquiry is assigned
  Future<void> notifyEnquiryAssigned({
    required String enquiryId,
    required String customerName,
    required String eventType,
    required String assignedTo,
    required String assignedBy,
  }) async {
    try {
      // Get assigned user details
      final assignedUser = await _getUserById(assignedTo);
      if (assignedUser == null) {
        print('NotificationService: Assigned user not found: $assignedTo');
        return;
      }

      // Send notification to assigned staff member
      await _sendNotificationToUser(
        userId: assignedTo,
        title: 'Enquiry Assigned to You',
        body: 'You have been assigned an enquiry from $customerName for $eventType',
        data: {
          'type': 'enquiry_assigned',
          'enquiryId': enquiryId,
          'customerName': customerName,
          'eventType': eventType,
          'assignedBy': assignedBy,
        },
        notificationType: 'enquiry_assigned',
        isImportant: true, // Assignments are important
      );

      // Send notification to user's personal topic
      await _sendNotificationToTopic(
        topic: 'user_$assignedTo',
        title: 'Enquiry Assigned to You',
        body: 'You have been assigned an enquiry from $customerName for $eventType',
        data: {
          'type': 'enquiry_assigned',
          'enquiryId': enquiryId,
          'customerName': customerName,
          'eventType': eventType,
          'assignedBy': assignedBy,
        },
      );

      // Get all admin users except the assigner
      final adminUsers = await _getAdminUsers(excludeUserId: assignedBy);

      // Send notification to all admins
      for (final admin in adminUsers) {
        await _sendNotificationToUser(
          userId: admin.uid,
          title: 'Enquiry Assigned',
          body: 'Enquiry from $customerName assigned to ${assignedUser.name}',
          data: {
            'type': 'enquiry_assigned',
            'enquiryId': enquiryId,
            'customerName': customerName,
            'assignedTo': assignedTo,
            'assignedBy': assignedBy,
          },
          notificationType: 'enquiry_assigned',
          isImportant: false, // Admin notifications about assignments are less critical
        );
      }

      print('NotificationService: Sent assignment notifications');
    } catch (e) {
      print('NotificationService: Error sending assignment notifications: $e');
    }
  }

  /// Send notification when enquiry status is updated
  Future<void> notifyStatusUpdated({
    required String enquiryId,
    required String customerName,
    required String oldStatus,
    required String newStatus,
    required String updatedBy,
  }) async {
    try {
      // Get all admin users except the updater
      final adminUsers = await _getAdminUsers(excludeUserId: updatedBy);

      // Send notification to all admins
      for (final admin in adminUsers) {
        await _sendNotificationToUser(
          userId: admin.uid,
          title: 'Enquiry Status Updated',
          body: 'Status changed from $oldStatus to $newStatus for $customerName',
          data: {
            'type': 'status_update',
            'enquiryId': enquiryId,
            'customerName': customerName,
            'oldStatus': oldStatus,
            'newStatus': newStatus,
            'updatedBy': updatedBy,
          },
          notificationType: 'status_update',
          isImportant: _isImportantStatusChange(oldStatus, newStatus),
        );
      }

      // Also send to general admin topic
      await _sendNotificationToTopic(
        topic: 'admins',
        title: 'Enquiry Status Updated',
        body: 'Status changed from $oldStatus to $newStatus for $customerName',
        data: {
          'type': 'status_update',
          'enquiryId': enquiryId,
          'customerName': customerName,
          'oldStatus': oldStatus,
          'newStatus': newStatus,
          'updatedBy': updatedBy,
        },
      );

      print('NotificationService: Sent status change notifications to ${adminUsers.length} admins');
    } catch (e) {
      print('NotificationService: Error sending status change notifications: $e');
    }
  }

  /// Get all admin users, optionally excluding a specific user
  Future<List<UserModel>> _getAdminUsers({String? excludeUserId}) async {
    try {
      final query = _firestore
          .collection('users')
          .where('role', isEqualTo: 'admin')
          .where('isActive', isEqualTo: true);

      final snapshot = await query.get();

      final adminUsers = snapshot.docs
          .where((doc) => excludeUserId == null || doc.id != excludeUserId)
          .map((doc) {
            final data = doc.data();
            return UserModel(
              uid: doc.id,
              name: data['name'] as String? ?? '',
              email: data['email'] as String? ?? '',
              phone: data['phone'] as String? ?? '',
              role: UserRole.admin,
            );
          })
          .toList();

      return adminUsers;
    } catch (e) {
      print('NotificationService: Error getting admin users: $e');
      return [];
    }
  }

  /// Get user by ID
  Future<UserModel?> _getUserById(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (!doc.exists) return null;

      final data = doc.data() as Map<String, dynamic>;
      return UserModel(
        uid: doc.id,
        name: data['name'] as String? ?? '',
        email: data['email'] as String? ?? '',
        phone: data['phone'] as String? ?? '',
        role: data['role'] == 'admin' ? UserRole.admin : UserRole.staff,
      );
    } catch (e) {
      print('NotificationService: Error getting user by ID: $e');
      return null;
    }
  }

  /// Send notification to a specific user via their FCM token
  Future<void> _sendNotificationToUser({
    required String userId,
    required String title,
    required String body,
    required Map<String, dynamic> data,
    String? notificationType,
    bool isImportant = false,
  }) async {
    try {
      // Check rate limiting
      final type = notificationType ?? data['type'] as String? ?? 'general';
      if (!_shouldSendNotification(userId, type, isImportant: isImportant)) {
        print('NotificationService: Rate limit exceeded for user $userId, notification type: $type');
        return;
      }

      // Get user's FCM token
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) return;

      // Read tokens from private subcollection
      final tokensSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('private')
          .doc('notifications')
          .collection('tokens')
          .limit(10)
          .get();

      if (tokensSnapshot.docs.isEmpty) {
        // TODO: Replace with safeLog - print('NotificationService: No FCM tokens for user $userId');
        return;
      }

      // Get all valid tokens
      final tokens = tokensSnapshot.docs
          .map((doc) => doc.get('token') as String?)
          .where((token) => token != null && token.isNotEmpty)
          .cast<String>()
          .toList();

      if (tokens.isEmpty) {
        // TODO: Replace with safeLog - print('NotificationService: No valid FCM tokens for user $userId');
        return;
      }

      // Store notification in Firestore for the user
      await _firestore.collection('users').doc(userId).collection('notifications').add({
        'title': title,
        'body': body,
        'data': data,
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
        'notificationType': type,
        'isImportant': isImportant,
      });

      // Record notification sent for rate limiting
      _recordNotificationSent(userId, type);

      // FCM notification is now sent by Cloud Function when this document is created
    } catch (e) {
      print('NotificationService: Error sending notification to user $userId: $e');
    }
  }

  /// Send notification to a topic
  Future<void> _sendNotificationToTopic({
    required String topic,
    required String title,
    required String body,
    required Map<String, dynamic> data,
  }) async {
    try {
      // Store notification in Firestore for the topic
      await _firestore.collection('notifications').doc(topic).collection('messages').add({
        'title': title,
        'body': body,
        'data': data,
        'topic': topic,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // FCM notification is now sent by Cloud Function when this document is created
    } catch (e) {
      print('NotificationService: Error sending notification to topic $topic: $e');
    }
  }

  /// Get user's unread notifications
  Future<List<Map<String, dynamic>>> getUserNotifications(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .where('read', isEqualTo: false)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {'id': doc.id, ...data};
      }).toList();
    } catch (e) {
      print('NotificationService: Error getting user notifications: $e');
      return [];
    }
  }

  /// Mark notification as read
  Future<void> markNotificationAsRead(String userId, String notificationId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .doc(notificationId)
          .update({'read': true, 'readAt': FieldValue.serverTimestamp()});
    } catch (e) {
      print('NotificationService: Error marking notification as read: $e');
    }
  }

  /// Mark all notifications as read for a user
  Future<void> markAllNotificationsAsRead(String userId) async {
    try {
      final batch = _firestore.batch();
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .where('read', isEqualTo: false)
          .get();

      for (final doc in snapshot.docs) {
        batch.update(doc.reference, {'read': true, 'readAt': FieldValue.serverTimestamp()});
      }

      await batch.commit();
    } catch (e) {
      print('NotificationService: Error marking all notifications as read: $e');
    }
  }

  /// Check if notification rate limit is exceeded for a user
  bool _isRateLimitExceeded(String userId, String notificationType) {
    final now = DateTime.now();
    final key = '${userId}_$notificationType';
    
    // Get or create notification history for this user/type
    final history = _notificationHistory[key] ?? [];
    
    // Clean up old entries (older than 24 hours)
    history.removeWhere((timestamp) => now.difference(timestamp).inDays > 0);
    _notificationHistory[key] = history;
    
    // Check rate limits
    final lastMinute = history.where((timestamp) => now.difference(timestamp).inMinutes < 1).length;
    final lastHour = history.where((timestamp) => now.difference(timestamp).inHours < 1).length;
    final lastDay = history.length;
    
    if (lastMinute >= _maxNotificationsPerMinute) {
      print('NotificationService: Rate limit exceeded - too many notifications per minute for $userId');
      return true;
    }
    
    if (lastHour >= _maxNotificationsPerHour) {
      print('NotificationService: Rate limit exceeded - too many notifications per hour for $userId');
      return true;
    }
    
    if (lastDay >= _maxNotificationsPerDay) {
      print('NotificationService: Rate limit exceeded - too many notifications per day for $userId');
      return true;
    }
    
    return false;
  }

  /// Record notification sent for rate limiting
  void _recordNotificationSent(String userId, String notificationType) {
    final now = DateTime.now();
    final key = '${userId}_$notificationType';
    
    final history = _notificationHistory[key] ?? [];
    history.add(now);
    _notificationHistory[key] = history;
  }

  /// Check if notification should be sent based on rate limiting and importance
  bool _shouldSendNotification(String userId, String notificationType, {bool isImportant = false}) {
    // Important notifications bypass rate limiting
    if (isImportant) {
      return true;
    }
    
    // Check rate limiting for regular notifications
    return !_isRateLimitExceeded(userId, notificationType);
  }

  /// Get rate limit status for a user
  Map<String, int> getRateLimitStatus(String userId, String notificationType) {
    final now = DateTime.now();
    final key = '${userId}_$notificationType';
    final history = _notificationHistory[key] ?? [];
    
    final lastMinute = history.where((timestamp) => now.difference(timestamp).inMinutes < 1).length;
    final lastHour = history.where((timestamp) => now.difference(timestamp).inHours < 1).length;
    final lastDay = history.length;
    
    return {
      'perMinute': lastMinute,
      'perHour': lastHour,
      'perDay': lastDay,
      'maxPerMinute': _maxNotificationsPerMinute,
      'maxPerHour': _maxNotificationsPerHour,
      'maxPerDay': _maxNotificationsPerDay,
    };
  }

  /// Clear rate limit history for a user (admin function)
  void clearRateLimitHistory(String userId, {String? notificationType}) {
    if (notificationType != null) {
      _notificationHistory.remove('${userId}_$notificationType');
    } else {
      // Clear all notification types for this user
      _notificationHistory.removeWhere((key, value) => key.startsWith('${userId}_'));
    }
  }

  /// Check if a status change is important enough to bypass rate limiting
  bool _isImportantStatusChange(String oldStatus, String newStatus) {
    // Important status changes that should bypass rate limiting
    final importantTransitions = [
      ['new', 'contacted'],
      ['contacted', 'quoted'],
      ['quoted', 'confirmed'],
      ['confirmed', 'in_progress'],
      ['in_progress', 'completed'],
      ['new', 'cancelled'],
      ['contacted', 'cancelled'],
      ['quoted', 'cancelled'],
      ['confirmed', 'cancelled'],
    ];

    return importantTransitions.any((transition) => 
        transition[0] == oldStatus && transition[1] == newStatus);
  }
}
