import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/app_notification.dart';

/// Repository for managing user notifications
class NotificationsRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  NotificationsRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance;

  /// Get current user's notifications collection reference
  CollectionReference<Map<String, dynamic>>? _getUserNotificationsCollection() {
    final user = _auth.currentUser;
    if (user == null) return null;
    
    return _firestore
        .collection('notifications')
        .doc(user.uid)
        .collection('items');
  }

  /// Watch user's notifications with optional filters
  Stream<List<AppNotification>> watchMyNotifications({
    int limit = 50,
    NotificationFilter filter = NotificationFilter.all,
  }) {
    final collection = _getUserNotificationsCollection();
    if (collection == null) {
      return Stream.value([]);
    }

    Query query = collection.orderBy('createdAt', descending: true);

    // Apply filters
    switch (filter) {
      case NotificationFilter.unread:
        query = query.where('read', isEqualTo: false);
        break;
      case NotificationFilter.archived:
        query = query.where('archived', isEqualTo: true);
        break;
      case NotificationFilter.all:
        query = query.where('archived', isEqualTo: false);
        break;
    }

    query = query.limit(limit);

    return query.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => AppNotification.fromFirestore(doc))
          .toList();
    });
  }

  /// Get unread notifications count
  Stream<int> watchUnreadCount() {
    final collection = _getUserNotificationsCollection();
    if (collection == null) {
      return Stream.value(0);
    }

    return collection
        .where('read', isEqualTo: false)
        .where('archived', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  /// Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    final collection = _getUserNotificationsCollection();
    if (collection == null) return;

    await collection.doc(notificationId).update({
      'read': true,
    });
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead() async {
    final collection = _getUserNotificationsCollection();
    if (collection == null) return;

    final unreadQuery = collection
        .where('read', isEqualTo: false)
        .where('archived', isEqualTo: false);

    final snapshot = await unreadQuery.get();
    
    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      batch.update(doc.reference, {'read': true});
    }
    
    await batch.commit();
  }

  /// Archive notification
  Future<void> archiveNotification(String notificationId) async {
    final collection = _getUserNotificationsCollection();
    if (collection == null) return;

    await collection.doc(notificationId).update({
      'archived': true,
      'read': true, // Mark as read when archiving
    });
  }

  /// Delete notification
  Future<void> deleteNotification(String notificationId) async {
    final collection = _getUserNotificationsCollection();
    if (collection == null) return;

    await collection.doc(notificationId).delete();
  }

  /// Clear all archived notifications
  Future<void> clearArchived() async {
    final collection = _getUserNotificationsCollection();
    if (collection == null) return;

    final archivedQuery = collection.where('archived', isEqualTo: true);
    final snapshot = await archivedQuery.get();
    
    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    
    await batch.commit();
  }

  /// Create a test notification (for development/testing)
  Future<void> createTestNotification() async {
    final collection = _getUserNotificationsCollection();
    if (collection == null) return;

    final notification = AppNotification(
      id: '', // Will be auto-generated
      type: NotificationType.systemAlert,
      title: 'Test Notification',
      body: 'This is a test notification created at ${DateTime.now()}',
      createdAt: DateTime.now(),
    );

    await collection.add(notification.toFirestore());
  }

  /// Get notification by ID
  Future<AppNotification?> getNotification(String notificationId) async {
    final collection = _getUserNotificationsCollection();
    if (collection == null) return null;

    final doc = await collection.doc(notificationId).get();
    if (!doc.exists) return null;

    return AppNotification.fromFirestore(doc);
  }
}

/// Riverpod provider for notifications repository
final notificationsRepositoryProvider = Provider<NotificationsRepository>((ref) {
  return NotificationsRepository();
});

/// Provider for watching user notifications
final userNotificationsProvider = StreamProvider.family<List<AppNotification>, NotificationFilter>((ref, filter) {
  final repository = ref.watch(notificationsRepositoryProvider);
  return repository.watchMyNotifications(filter: filter);
});

/// Provider for watching unread notifications count
final unreadNotificationsCountProvider = StreamProvider<int>((ref) {
  final repository = ref.watch(notificationsRepositoryProvider);
  return repository.watchUnreadCount();
});
