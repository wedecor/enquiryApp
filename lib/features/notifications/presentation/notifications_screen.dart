import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/notifications/notification_router.dart';
import '../../../core/providers/notification_provider.dart';
import '../../../core/providers/role_provider.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/tokens.dart';
import '../../../ui/primitives/primitives.dart';
import '../../../ui/components/glass_page_scaffold.dart';
import '../../../ui/components/glass_state_message.dart';
import '../../enquiries/presentation/screens/enquiry_details_screen.dart';
import '../../reengagement/presentation/upcoming_occasions_screen.dart';
import 'widgets/notification_timeline_tile.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserWithFirestoreProvider);

    return userAsync.when(
      loading: () => const GlassPageScaffold(
        eyebrow: 'Inbox',
        title: 'Notifications',
        body: GlassLoadingState(),
      ),
      error: (e, _) => GlassPageScaffold(
        eyebrow: 'Inbox',
        title: 'Notifications',
        body: Center(child: Text('Error: $e')),
      ),
      data: (user) {
        if (user == null) {
          return const GlassPageScaffold(
            eyebrow: 'Inbox',
            title: 'Notifications',
            body: Center(child: Text('Not logged in')),
          );
        }
        return _NotificationsBody(userId: user.uid);
      },
    );
  }
}

class _NotificationsBody extends ConsumerWidget {
  const _NotificationsBody({required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(userNotificationsProvider(userId));
    final service = ref.read(notificationServiceProvider);

    return GlassPageScaffold(
      eyebrow: 'Inbox',
      title: 'Notifications',
      body: notificationsAsync.when(
        loading: () => const GlassLoadingState(),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (notifications) {
          if (notifications.isEmpty) {
            return const GlassStateMessage(
              icon: Icons.notifications_none_rounded,
              title: 'All caught up!',
              message: 'No notifications yet.',
            );
          }
          final unread = notifications.where((n) => n['read'] != true).length;
          return ListView.builder(
            padding: EdgeInsets.fromLTRB(
              AppTokens.space4,
              AppTokens.space3,
              AppTokens.space4,
              AppTokens.space8 + MediaQuery.paddingOf(context).bottom,
            ),
            itemCount: notifications.length + 1,
            itemBuilder: (context, i) {
              if (i == 0) {
                return _TimelineHeader(
                  unread: unread,
                  onMarkAllRead: unread > 0
                      ? () => service.markAllNotificationsAsRead(userId)
                      : null,
                );
              }
              final n = notifications[i - 1];
              return StaggerIn(
                index: i,
                child: NotificationTimelineTile(
                  notification: n,
                  isFirst: i == 1,
                  isLast: i == notifications.length,
                  onTap: () => _handleTap(context, ref, service, n),
                  onDismiss: () => service.deleteNotification(userId, n['id'] as String),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _handleTap(
    BuildContext context,
    WidgetRef ref,
    NotificationService service,
    Map<String, dynamic> notification,
  ) {
    final notifId = notification['id'] as String;
    final enquiryId =
        notification['data']?['enquiryId'] as String? ?? notification['enquiryId'] as String?;

    // Mark as read
    if (notification['read'] != true) {
      service.markNotificationAsRead(userId, notifId);
    }

    // Yearly-reminder summary → Upcoming occasions.
    final type = notification['type'] ?? notification['data']?['type'];
    if (type == reengagementNotificationType && context.mounted) {
      Navigator.of(
        context,
      ).push<void>(MaterialPageRoute<void>(builder: (_) => const UpcomingOccasionsScreen()));
      return;
    }

    // Navigate to enquiry if available
    if (enquiryId != null && context.mounted) {
      Navigator.of(context).push<void>(
        MaterialPageRoute<void>(builder: (_) => EnquiryDetailsScreen(enquiryId: enquiryId)),
      );
    }
  }
}

class _TimelineHeader extends StatelessWidget {
  const _TimelineHeader({required this.unread, required this.onMarkAllRead});

  final int unread;
  final VoidCallback? onMarkAllRead;

  @override
  Widget build(BuildContext context) {
    final s = AppSurfaces.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTokens.space3),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: AppTokens.minTapTarget),
        child: Row(
          children: [
            if (unread > 0) ...[
              StatusDot(color: s.accent),
              const SizedBox(width: AppTokens.space2),
            ],
            Expanded(
              child: Eyebrow(unread > 0 ? '$unread unread' : 'All read', accent: unread > 0),
            ),
            if (onMarkAllRead != null)
              TextButton(onPressed: onMarkAllRead, child: const Text('Mark all read')),
          ],
        ),
      ),
    );
  }
}
