import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

import '../../core/logging/logger.dart';
import 'firestore_service.dart';

/// Sends one enquiry event to the `notifyEnquiryEvent` callable.
typedef EnquiryEventAnnouncer = Future<void> Function(Map<String, dynamic> payload);

/// Enquiry notifications (create / assign / status / edit) and the in-app inbox.
///
/// The app no longer writes `users/{uid}/notifications` for other people: the
/// security rules reject it, because any active user could otherwise push any
/// text to any colleague. Each `notify*` method calls the `notifyEnquiryEvent`
/// Cloud Function with the enquiry id and the kind of event; the server checks the
/// caller may act on that enquiry, chooses the recipients (admins other than the
/// actor, and the assignee) and builds the title and body from stored data.
///
/// The methods never throw: a failed notification must not fail the save.
class NotificationService {
  NotificationService(this._firestoreService, {EnquiryEventAnnouncer? announcer})
    : _announcer = announcer ?? _callNotifyEnquiryEvent;

  final FirestoreService _firestoreService;
  final EnquiryEventAnnouncer _announcer;

  FirebaseFirestore get _firestore => _firestoreService.firestore;

  static Future<void> _callNotifyEnquiryEvent(Map<String, dynamic> payload) async {
    final callable = FirebaseFunctions.instanceFor(
      region: 'asia-south1',
    ).httpsCallable('notifyEnquiryEvent');
    await callable.call<dynamic>(payload);
  }

  Future<void> _announce(String enquiryId, String event, Map<String, dynamic> extra) async {
    try {
      await _announcer(<String, dynamic>{'enquiryId': enquiryId, 'event': event, ...extra});
      Log.i('NotificationService: event announced', data: {'enquiryId': enquiryId, 'event': event});
    } catch (e, st) {
      Log.e(
        'NotificationService: failed to announce enquiry event',
        error: e,
        stackTrace: st,
        data: {'enquiryId': enquiryId, 'event': event},
      );
    }
  }

  /// New enquiry: every active admin except the creator.
  Future<void> notifyEnquiryCreated({
    required String enquiryId,
    required String customerName,
    required String eventType,
    required String createdBy,
  }) => _announce(enquiryId, 'created', const {});

  /// Assignment: the enquiry's current assignee ("Assigned to You") and, unless
  /// [notifyAdmins] is false, the other admins. Pass false when the same save
  /// already notifies admins (new enquiry, status change).
  Future<void> notifyEnquiryAssigned({
    required String enquiryId,
    required String customerName,
    required String eventType,
    required String assignedTo,
    required String assignedBy,
    bool notifyAdmins = true,
  }) => _announce(enquiryId, 'assigned', {'notifyAdmins': notifyAdmins});

  /// Status change: admins other than the updater, and the assignee unless
  /// [assignedTo] is null (callers pass null when the assignee gets a separate
  /// "Assigned to You" push). [oldStatusValue] is the previous `statusValue`; the
  /// new status is read from the enquiry on the server.
  Future<void> notifyStatusUpdated({
    required String enquiryId,
    required String customerName,
    required String oldStatus,
    required String newStatus,
    required String updatedBy,
    String? assignedTo,
    String? oldStatusValue,
  }) => _announce(enquiryId, 'status_changed', {
    'oldStatus': oldStatusValue ?? oldStatus,
    'notifyAssignee': assignedTo != null,
  });

  /// Edit: admins other than the updater, and the assignee unless [assignedTo] is null.
  Future<void> notifyEnquiryUpdated({
    required String enquiryId,
    required String customerName,
    required String eventType,
    required String updatedBy,
    String? assignedTo,
  }) => _announce(enquiryId, 'updated', {'notifyAssignee': assignedTo != null});

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
