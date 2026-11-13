import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/logging/logger.dart';
import 'firestore_service.dart';

/// In-app notification inbox service.
///
/// Enquiry notifications (create / assign / status / edit) are generated
/// server-side by the `onEnquiryWrittenNotify` Firestore trigger.
class NotificationService {
  NotificationService(this._firestoreService);

  final FirestoreService _firestoreService;

  FirebaseFirestore get _firestore => _firestoreService.firestore;

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

  /// Cap for the unread badge query; the UI shows "99+" above 99.
  static const int unreadCountCap = 100;

  /// Real-time stream of unread notification count, capped at [unreadCountCap]
  /// so the badge never streams every unread document.
  Stream<int> watchUnreadCount(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .where('read', isEqualTo: false)
        .limit(unreadCountCap)
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
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .where('read', isEqualTo: false)
          .get();

      // Firestore batches hold at most 500 writes; commit in chunks.
      const chunkSize = 450;
      final docs = snapshot.docs;
      for (var start = 0; start < docs.length; start += chunkSize) {
        final end = start + chunkSize < docs.length ? start + chunkSize : docs.length;
        final batch = _firestore.batch();
        for (final doc in docs.sublist(start, end)) {
          batch.update(doc.reference, {'read': true, 'readAt': FieldValue.serverTimestamp()});
        }
        await batch.commit();
      }
    } catch (e, st) {
      Log.e(
        'NotificationService: error marking all notifications as read',
        error: e,
        stackTrace: st,
      );
    }
  }
}
