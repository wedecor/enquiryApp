import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../core/logging/logger.dart';
import '../../shared/models/user_model.dart';
import 'firestore_service.dart';

/// Service for managing notification triggers and sending notifications
class NotificationService {
  NotificationService(this._firestoreService);

  final FirestoreService _firestoreService;

  FirebaseFirestore get _firestore => _firestoreService.firestore;

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

  /// Send notification when an enquiry is assigned.
  ///
  /// Pass [notifyAdmins] false when the same save already notifies admins
  /// (new enquiry, status change), so nobody gets two pushes for one action.
  Future<void> notifyEnquiryAssigned({
    required String enquiryId,
    required String customerName,
    required String eventType,
    required String assignedTo,
    required String assignedBy,
    bool notifyAdmins = true,
  }) async {
    try {
      // Get assigned user details
      final assignedUser = await _getUserById(assignedTo);
      if (assignedUser == null) {
        Log.w('NotificationService: assigned user not found', data: {'assignedTo': assignedTo});
        return;
      }

      if (assignedTo != assignedBy) {
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
      }

      if (!notifyAdmins) return;

      // Admins other than the assigner; the assignee already got their own push.
      final adminUsers = (await _getAdminUsers(
        excludeUserId: assignedBy,
      )).where((admin) => admin.uid != assignedTo).toList();

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
    try {
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
      final adminUsers = await _getAdminUsers(excludeUserId: updatedBy);

      if (adminUsers.isEmpty) {
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
      for (final admin in adminUsers) {
        try {
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
          Log.d(
            'NotificationService: notification sent to admin',
            data: {'adminId': admin.uid, 'adminEmail': admin.email},
          );
        } catch (e, st) {
          Log.e(
            'NotificationService: error sending notification to admin',
            error: e,
            stackTrace: st,
            data: {'adminId': admin.uid},
          );
        }
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
    // ALWAYS log - even in release mode for debugging
    try {
      if (kDebugMode) {
        debugPrint('🔔 NOTIFICATION DEBUG: notifyEnquiryUpdated called');
        debugPrint('   EnquiryId: $enquiryId');
        debugPrint('   Customer: $customerName');
        debugPrint('   EventType: $eventType');
        debugPrint('   UpdatedBy: $updatedBy');
      }

      Log.i(
        'NotificationService: notifyEnquiryUpdated called',
        data: {
          'enquiryId': enquiryId,
          'customerName': customerName,
          'eventType': eventType,
          'updatedBy': updatedBy,
          'assignedTo': assignedTo,
        },
      );

      // Get all admin users EXCEPT the updater
      final adminUsers = await _getAdminUsers(excludeUserId: updatedBy);

      if (adminUsers.isEmpty) {
        if (kDebugMode) {
          debugPrint('⚠️ NOTIFICATION DEBUG: NO ADMIN USERS FOUND!');
          debugPrint('   UpdatedBy: $updatedBy');
          debugPrint('   This means no admins will receive notifications!');
        }
        Log.w(
          'NotificationService: no admin users found to notify for enquiry update',
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
        'NotificationService: sending enquiry update notifications to admins',
        data: {'adminCount': adminUsers.length, 'adminIds': adminUsers.map((u) => u.uid).toList()},
      );

      // Send notification to all admins (excluding the updater)
      for (final admin in adminUsers) {
        try {
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
          Log.d(
            'NotificationService: notification sent to admin',
            data: {'adminId': admin.uid, 'adminEmail': admin.email},
          );
        } catch (e, st) {
          Log.e(
            'NotificationService: error sending notification to admin',
            error: e,
            stackTrace: st,
            data: {'adminId': admin.uid},
          );
        }
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

      // Query for admin users - filter by isActive (backward compatible during migration)
      final query = _firestore.collection('users').where('role', isEqualTo: 'admin');

      final snapshot = await query.get();

      if (kDebugMode) {
        debugPrint('   Found ${snapshot.docs.length} total admin documents in Firestore');
        for (var doc in snapshot.docs) {
          final data = doc.data();
          final isActive = data['isActive'] ?? data['active'] ?? true;
          final willInclude =
              !(excludeUserId != null && doc.id == excludeUserId) && isActive != false;
          debugPrint('   - Admin doc: ${doc.id}');
          debugPrint('     Email: ${data['email']}');
          debugPrint('     Role: ${data['role']}');
          debugPrint(
            '     isActive: ${data['isActive'] ?? data['active'] ?? 'not set (defaulting to true)'}',
          );
          debugPrint('     Will include: $willInclude');
          if (!willInclude) {
            if (excludeUserId != null && doc.id == excludeUserId) {
              debugPrint('       Reason: Matches excluded userId');
            } else if (isActive == false) {
              debugPrint('       Reason: isActive = false');
            }
          }
        }
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
            // Filter out inactive users - backward compatible: check both fields
            // Default to true (active) if field is not set
            final data = doc.data();
            final isActive = data['isActive'] ?? data['active'] ?? true;
            if (isActive == false) {
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

  /// Queues a notification for [userId] by writing `users/{userId}/notifications`.
  ///
  /// The `sendNotificationToUser` Cloud Function picks the document up, looks up
  /// the recipient's device tokens and sends the push. The app must NOT read
  /// another user's tokens itself: `users/{uid}/private/**` is owner-only in the
  /// security rules, so that read failed with permission-denied and — because it
  /// ran before this write — silently stopped every cross-user notification.
  Future<void> _sendNotificationToUser({
    required String userId,
    required String title,
    required String body,
    required Map<String, dynamic> data,
  }) async {
    try {
      final notificationRef = await _firestore
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

      Log.i(
        'NotificationService: notification queued',
        data: {
          'userId': userId,
          'notificationId': notificationRef.id,
          'title': title,
          'type': data['type'],
        },
      );
    } catch (e, st) {
      Log.e(
        'NotificationService: failed to queue notification',
        error: e,
        stackTrace: st,
        data: {'userId': userId, 'title': title},
      );
    }
  }

  /// Real-time stream of all notifications for a user (newest first, max 50)
  Stream<List<Map<String, dynamic>>> watchUserNotifications(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snap) => snap.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList());
  }

  /// Real-time stream of unread notification count
  Stream<int> watchUnreadCount(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .where('read', isEqualTo: false)
        .snapshots()
        .map((snap) => snap.docs.length);
  }

  /// Delete a notification
  Future<void> deleteNotification(String userId, String notificationId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .doc(notificationId)
          .delete();
    } catch (e, st) {
      Log.e('NotificationService: error deleting notification', error: e, stackTrace: st);
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
