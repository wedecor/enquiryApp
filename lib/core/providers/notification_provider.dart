import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:we_decor_enquiries/core/services/notification_service.dart';

/// Provider for NotificationService
final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

/// Provider for user notifications stream
final userNotificationsProvider = StreamProvider.family<List<Map<String, dynamic>>, String>((ref, userId) {
  final notificationService = ref.read(notificationServiceProvider);
  
  // This would typically be a stream, but for now we'll return a future
  return Stream.fromFuture(notificationService.getUserNotifications(userId));
});

/// Provider for notification count
final notificationCountProvider = StreamProvider.family<int, String>((ref, userId) {
  final notificationsAsync = ref.watch(userNotificationsProvider(userId));
  
  return notificationsAsync.when(
    data: (notifications) => Stream.value(notifications.length),
    loading: () => Stream.value(0),
    error: (error, stack) => Stream.value(0),
  );
}); 