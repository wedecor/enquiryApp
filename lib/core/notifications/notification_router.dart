import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

import '../../features/enquiries/presentation/screens/enquiry_details_screen.dart';
import '../../features/notifications/presentation/notifications_screen.dart';

/// App-wide keys so push notifications can be shown and opened without a
/// BuildContext. Wired into [MaterialApp] in main.dart.
final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<ScaffoldMessengerState> appScaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

/// Shows and routes push notifications.
///
/// * Foreground: Android/iOS do not display FCM notifications while the app is
///   open, so we show an in-app banner (SnackBar) with a "View" action.
/// * Tapped from the system tray: opens the enquiry it refers to (or the
///   notifications list when there is no enquiry).
class NotificationRouter {
  NotificationRouter._();

  static void showForeground(RemoteMessage message) {
    final title = message.notification?.title ?? message.data['title']?.toString();
    final body = message.notification?.body ?? message.data['body']?.toString();
    if (title == null && body == null) return;

    final messenger = appScaffoldMessengerKey.currentState;
    if (messenger == null) return;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 6),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (title != null)
                Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
              if (body != null) Text(body, maxLines: 3, overflow: TextOverflow.ellipsis),
            ],
          ),
          action: SnackBarAction(label: 'View', onPressed: () => open(message)),
        ),
      );
  }

  /// Opens the screen a notification refers to.
  static void open(RemoteMessage message) {
    final navigator = appNavigatorKey.currentState;
    if (navigator == null) return;
    final enquiryId = message.data['enquiryId']?.toString();
    if (enquiryId != null && enquiryId.isNotEmpty) {
      navigator.push<void>(
        MaterialPageRoute<void>(builder: (_) => EnquiryDetailsScreen(enquiryId: enquiryId)),
      );
    } else {
      navigator.push<void>(MaterialPageRoute<void>(builder: (_) => const NotificationsScreen()));
    }
  }
}
