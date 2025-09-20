import 'package:cloud_firestore/cloud_firestore.dart';
import '../../shared/models/user_model.dart';

/// Service for managing notification triggers and sending notifications
class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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
        );
      }

      // Also send to general admin topic
      await _sendNotificationToTopic(
        topic: 'admin',
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

      print(
        'NotificationService: Sent new enquiry notifications to ${adminUsers.length} admins',
      );
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
        body:
            'You have been assigned an enquiry from $customerName for $eventType',
        data: {
          'type': 'enquiry_assigned',
          'enquiryId': enquiryId,
          'customerName': customerName,
          'eventType': eventType,
          'assignedBy': assignedBy,
        },
      );

      // Send notification to user's personal topic
      await _sendNotificationToTopic(
        topic: 'user_$assignedTo',
        title: 'Enquiry Assigned to You',
        body:
            'You have been assigned an enquiry from $customerName for $eventType',
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
          body:
              'Status changed from $oldStatus to $newStatus for $customerName',
          data: {
            'type': 'status_update',
            'enquiryId': enquiryId,
            'customerName': customerName,
            'oldStatus': oldStatus,
            'newStatus': newStatus,
            'updatedBy': updatedBy,
          },
        );
      }

      // Also send to general admin topic
      await _sendNotificationToTopic(
        topic: 'admin',
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

      print(
        'NotificationService: Sent status update notifications to ${adminUsers.length} admins',
      );
    } catch (e) {
      print(
        'NotificationService: Error sending status update notifications: $e',
      );
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
  }) async {
    try {
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
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .add({
            'title': title,
            'body': body,
            'data': data,
            'read': false,
            'createdAt': FieldValue.serverTimestamp(),
          });

      // TODO: Send actual FCM notification
      // This would typically be done via a Cloud Function or server
      print('NotificationService: Would send FCM notification to user $userId');
      print('Title: $title');
      print('Body: $body');
      print('Data: $data');
    } catch (e) {
      print(
        'NotificationService: Error sending notification to user $userId: $e',
      );
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
      await _firestore
          .collection('notifications')
          .doc(topic)
          .collection('messages')
          .add({
            'title': title,
            'body': body,
            'data': data,
            'topic': topic,
            'createdAt': FieldValue.serverTimestamp(),
          });

      // TODO: Send actual FCM notification to topic
      // This would typically be done via a Cloud Function or server
      print('NotificationService: Would send FCM notification to topic $topic');
      print('Title: $title');
      print('Body: $body');
      print('Data: $data');
    } catch (e) {
      print(
        'NotificationService: Error sending notification to topic $topic: $e',
      );
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
  Future<void> markNotificationAsRead(
    String userId,
    String notificationId,
  ) async {
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
        batch.update(doc.reference, {
          'read': true,
          'readAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
    } catch (e) {
      print('NotificationService: Error marking all notifications as read: $e');
    }
  }
}
