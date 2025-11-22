import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../shared/models/user_model.dart';
import '../../utils/logger.dart';

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
      // Get all admin users EXCEPT the creator
      final adminUsers = await _getAdminUsers(excludeUserId: createdBy);

      // Send notification to all admins (excluding the creator)
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

      Log.i(
        'NotificationService: sent new enquiry notifications',
        data: {'adminCount': adminUsers.length},
      );
    } catch (e, st) {
      Log.e(
        'NotificationService: error sending new enquiry notifications',
        error: e,
        stackTrace: st,
      );
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
        Log.w('NotificationService: assigned user not found', data: {'assignedTo': assignedTo});
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

      // Get all admin users EXCEPT the assigner
      final adminUsers = await _getAdminUsers(excludeUserId: assignedBy);

      // Send notification to all admins (excluding the assigner)
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

      Log.i(
        'NotificationService: sent assignment notifications',
        data: {'adminCount': adminUsers.length},
      );
    } catch (e, st) {
      Log.e(
        'NotificationService: error sending assignment notifications',
        error: e,
        stackTrace: st,
      );
    }
  }

  /// Send notification when enquiry status is updated
  Future<void> notifyStatusUpdated({
    required String enquiryId,
    required String customerName,
    required String oldStatus,
    required String newStatus,
    required String updatedBy,
    String? assignedTo,
  }) async {
    // ALWAYS log - even in release mode for debugging
    print('🔔🔔🔔 NOTIFY STATUS UPDATED CALLED 🔔🔔🔔');
    print('   EnquiryId: $enquiryId');
    print('   Customer: $customerName');
    print('   Status: $oldStatus → $newStatus');
    print('   UpdatedBy: $updatedBy');
    print('   AssignedTo: $assignedTo');
    
    try {
      // Always log to console for debugging (especially on web)
      if (kDebugMode) {
        debugPrint('🔔 NOTIFICATION DEBUG: notifyStatusUpdated called');
        debugPrint('   EnquiryId: $enquiryId');
        debugPrint('   Customer: $customerName');
        debugPrint('   Status: $oldStatus → $newStatus');
        debugPrint('   UpdatedBy: $updatedBy');
      }

      Log.i(
        'NotificationService: notifyStatusUpdated called',
        data: {
          'enquiryId': enquiryId,
          'customerName': customerName,
          'oldStatus': oldStatus,
          'newStatus': newStatus,
          'updatedBy': updatedBy,
          'assignedTo': assignedTo,
        },
      );

      // Get all admin users EXCEPT the updater
      print('🔍 Getting admin users (excluding: $updatedBy)...');
      final adminUsers = await _getAdminUsers(excludeUserId: updatedBy);
      print('🔍 Found ${adminUsers.length} admin users');

      if (adminUsers.isEmpty) {
        print('⚠️⚠️⚠️ NO ADMIN USERS FOUND! ⚠️⚠️⚠️');
        print('   UpdatedBy: $updatedBy');
        print('   This means no admins will receive notifications!');
        if (kDebugMode) {
          debugPrint('⚠️ NOTIFICATION DEBUG: NO ADMIN USERS FOUND!');
          debugPrint('   UpdatedBy: $updatedBy');
          debugPrint('   This means no admins will receive notifications!');
        }
        Log.w(
          'NotificationService: no admin users found to notify',
          data: {'updatedBy': updatedBy},
        );
        return;
      }

      if (kDebugMode) {
        debugPrint('✅ NOTIFICATION DEBUG: Found ${adminUsers.length} admin users');
        for (var admin in adminUsers) {
          debugPrint('   - Admin: ${admin.email} (${admin.uid})');
        }
      }

      Log.i(
        'NotificationService: sending status update notifications to admins',
        data: {'adminCount': adminUsers.length, 'adminIds': adminUsers.map((u) => u.uid).toList()},
      );

      // Send notification to all admins (excluding the updater)
      print('📤 Sending notifications to ${adminUsers.length} admins...');
      for (final admin in adminUsers) {
        try {
          print('   📤 Sending to admin: ${admin.email} (${admin.uid})');
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
          );
          print('   ✅ Sent to admin: ${admin.email}');
          Log.d(
            'NotificationService: notification sent to admin',
            data: {'adminId': admin.uid, 'adminEmail': admin.email},
          );
        } catch (e, st) {
          print('   ❌ ERROR sending to admin ${admin.email}: $e');
          print('   Stack: $st');
          Log.e(
            'NotificationService: error sending notification to admin',
            error: e,
            stackTrace: st,
            data: {'adminId': admin.uid},
          );
        }
      }
      print('✅✅✅ Finished sending notifications ✅✅✅');

      // Also send notification to assigned user if they exist and are different from updater
      if (assignedTo != null && assignedTo != updatedBy) {
        final assignedUser = await _getUserById(assignedTo);
        if (assignedUser != null) {
          // Only send if they're not already an admin (to avoid duplicate)
          final isAssignedUserAdmin = adminUsers.any((admin) => admin.uid == assignedTo);
          if (!isAssignedUserAdmin) {
            await _sendNotificationToUser(
              userId: assignedTo,
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
          }
        }
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

      Log.i(
        'NotificationService: sent status change notifications',
        data: {
          'adminCount': adminUsers.length,
          'assignedTo': assignedTo,
          'enquiryId': enquiryId,
          'updatedBy': updatedBy,
        },
      );
    } catch (e, st) {
      // Log error but don't fail the status update
      Log.e(
        'NotificationService: CRITICAL ERROR sending status change notifications',
        error: e,
        stackTrace: st,
        data: {
          'enquiryId': enquiryId,
          'updatedBy': updatedBy,
          'assignedTo': assignedTo,
          'note': 'Status update succeeded but notifications failed',
        },
      );
      // Don't rethrow - allow status update to succeed even if notifications fail
    }
  }

  /// Send notification when an enquiry is updated (edited)
  Future<void> notifyEnquiryUpdated({
    required String enquiryId,
    required String customerName,
    required String eventType,
    required String updatedBy,
    String? assignedTo,
  }) async {
    try {
      // Get all admin users EXCEPT the updater
      final adminUsers = await _getAdminUsers(excludeUserId: updatedBy);

      // Send notification to all admins (excluding the updater)
      for (final admin in adminUsers) {
        await _sendNotificationToUser(
          userId: admin.uid,
          title: 'Enquiry Updated',
          body: 'Enquiry from $customerName for $eventType has been updated',
          data: {
            'type': 'enquiry_updated',
            'enquiryId': enquiryId,
            'customerName': customerName,
            'eventType': eventType,
            'updatedBy': updatedBy,
          },
        );
      }

      // Also send notification to assigned user if they exist and are different from updater
      if (assignedTo != null && assignedTo != updatedBy) {
        final assignedUser = await _getUserById(assignedTo);
        if (assignedUser != null) {
          // Only send if they're not already an admin (to avoid duplicate)
          final isAssignedUserAdmin = adminUsers.any((admin) => admin.uid == assignedTo);
          if (!isAssignedUserAdmin) {
            await _sendNotificationToUser(
              userId: assignedTo,
              title: 'Enquiry Updated',
              body: 'Enquiry from $customerName for $eventType has been updated',
              data: {
                'type': 'enquiry_updated',
                'enquiryId': enquiryId,
                'customerName': customerName,
                'eventType': eventType,
                'updatedBy': updatedBy,
              },
            );
          }
        }
      }

      // Also send to general admin topic
      await _sendNotificationToTopic(
        topic: 'admin',
        title: 'Enquiry Updated',
        body: 'Enquiry from $customerName for $eventType has been updated',
        data: {
          'type': 'enquiry_updated',
          'enquiryId': enquiryId,
          'customerName': customerName,
          'eventType': eventType,
          'updatedBy': updatedBy,
        },
      );

      Log.i(
        'NotificationService: sent enquiry update notifications',
        data: {'adminCount': adminUsers.length, 'assignedTo': assignedTo},
      );
    } catch (e, st) {
      Log.e(
        'NotificationService: error sending enquiry update notifications',
        error: e,
        stackTrace: st,
      );
    }
  }

  /// Get all admin users, optionally excluding a specific user
  Future<List<UserModel>> _getAdminUsers({String? excludeUserId}) async {
    try {
      if (kDebugMode) {
        debugPrint('🔍 NOTIFICATION DEBUG: Querying for admin users...');
        debugPrint('   Excluding userId: $excludeUserId');
      }

      // Query for admin users - don't filter by isActive as it might not exist on all users
      final query = _firestore.collection('users').where('role', isEqualTo: 'admin');

      final snapshot = await query.get();

      if (kDebugMode) {
        debugPrint('   Found ${snapshot.docs.length} total admin documents in Firestore');
      }

      final adminUsers = snapshot.docs
          .where((doc) {
            // Exclude the specified user if provided
            if (excludeUserId != null && doc.id == excludeUserId) {
              if (kDebugMode) {
                debugPrint('   ⏭️ Excluding admin: ${doc.id} (matches updatedBy)');
              }
              return false;
            }
            // Filter out inactive users if isActive field exists and is false
            final data = doc.data();
            final isActive = data['isActive'];
            if (isActive != null && isActive == false) {
              if (kDebugMode) {
                debugPrint('   ⏭️ Excluding admin: ${doc.id} (isActive = false)');
              }
              return false;
            }
            return true;
          })
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

      if (kDebugMode) {
        debugPrint('✅ NOTIFICATION DEBUG: Found ${adminUsers.length} admin users to notify');
        for (var admin in adminUsers) {
          debugPrint('   - ${admin.email} (${admin.uid})');
        }
      }

      Log.i(
        'NotificationService: found admin users',
        data: {
          'totalAdmins': adminUsers.length,
          'excludedUserId': excludeUserId,
          'adminIds': adminUsers.map((u) => u.uid).toList(),
        },
      );

      return adminUsers;
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('❌ NOTIFICATION DEBUG: ERROR getting admin users: $e');
      }
      Log.e('NotificationService: error getting admin users', error: e, stackTrace: st);
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
    } catch (e, st) {
      Log.e('NotificationService: error getting user by ID', error: e, stackTrace: st);
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

      // Read tokens from private subcollection to check if user has tokens
      final tokensSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('private')
          .doc('notifications')
          .collection('tokens')
          .limit(10)
          .get();

      final tokenCount = tokensSnapshot.docs.length;
      final tokens = tokensSnapshot.docs
          .map((doc) => doc.get('token') as String?)
          .where((token) => token != null && token.isNotEmpty)
          .cast<String>()
          .toList();

      Log.i(
        'NotificationService: checking tokens for user',
        data: {
          'userId': userId,
          'tokenDocumentCount': tokenCount,
          'validTokenCount': tokens.length,
        },
      );

      // Store notification in Firestore for the user
      // This will trigger the Cloud Function sendNotificationToUser
      // We store it even if there are no tokens - the Cloud Function will handle it
      DocumentReference? notificationRef;
      try {
        notificationRef = await _firestore
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

        if (kDebugMode) {
          print('✅ NOTIFICATION STORED: ${notificationRef.id}');
          debugPrint('✅ Notification stored in Firestore: ${notificationRef.id}');
        }
      } catch (firestoreError, stackTrace) {
        // Log Firestore error explicitly
        print('❌ ERROR storing notification in Firestore: $firestoreError');
        debugPrint('❌ ERROR storing notification: $firestoreError');
        Log.e(
          'NotificationService: CRITICAL ERROR storing notification in Firestore',
          error: firestoreError,
          stackTrace: stackTrace,
          data: {'userId': userId, 'title': title},
        );
        rethrow; // Re-throw so we know it failed
      }

      if (notificationRef != null) {
        if (kDebugMode) {
          debugPrint('📝 NOTIFICATION DEBUG: Stored notification in Firestore');
          debugPrint('   UserId: $userId');
          debugPrint('   NotificationId: ${notificationRef.id}');
          debugPrint('   Title: $title');
          debugPrint('   Body: $body');
          debugPrint('   HasTokens: ${tokens.isNotEmpty}');
          debugPrint('   TokenCount: ${tokens.length}');
          if (tokens.isEmpty) {
            debugPrint(
              '   ⚠️ WARNING: User has NO FCM tokens - notification may not be delivered!',
            );
          }
        }

        Log.i(
          'NotificationService: notification stored in Firestore',
          data: {
            'userId': userId,
            'notificationId': notificationRef.id,
            'title': title,
            'body': body,
            'hasTokens': tokens.isNotEmpty,
            'tokenCount': tokens.length,
            'data': data,
          },
        );

        if (tokens.isEmpty) {
          Log.w(
            'NotificationService: notification stored but user has no FCM tokens',
            data: {
              'userId': userId,
              'notificationId': notificationRef.id,
              'note': 'Cloud Function will attempt to send but may fail if no tokens exist',
            },
          );
        }
      }
    } catch (e, st) {
      Log.e('NotificationService: error sending notification to user', error: e, stackTrace: st);
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

      Log.d(
        'NotificationService: stubbed FCM send to topic',
        data: {'topic': topic, 'title': title, 'body': body, 'data': data},
      );
    } catch (e, st) {
      Log.e('NotificationService: error sending notification to topic', error: e, stackTrace: st);
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
    } catch (e, st) {
      Log.e('NotificationService: error getting user notifications', error: e, stackTrace: st);
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
    } catch (e, st) {
      Log.e('NotificationService: error marking notification as read', error: e, stackTrace: st);
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
    } catch (e, st) {
      Log.e(
        'NotificationService: error marking all notifications as read',
        error: e,
        stackTrace: st,
      );
    }
  }
}
