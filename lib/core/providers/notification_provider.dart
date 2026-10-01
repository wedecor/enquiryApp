import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/firestore_service.dart';
import '../services/notification_service.dart';

/// Provider for NotificationService
final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService(ref.watch(firestoreServiceProvider));
});

/// Real-time stream of all notifications for a user (newest first)
final userNotificationsProvider = StreamProvider.family<List<Map<String, dynamic>>, String>((
  ref,
  userId,
) {
  return ref.watch(notificationServiceProvider).watchUserNotifications(userId);
});

/// Real-time unread notification count
final unreadNotificationCountProvider = StreamProvider.family<int, String>((ref, userId) {
  return ref.watch(notificationServiceProvider).watchUnreadCount(userId);
});
