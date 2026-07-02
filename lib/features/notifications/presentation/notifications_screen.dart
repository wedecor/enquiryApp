import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/notification_provider.dart';
import '../../../core/providers/role_provider.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/tokens.dart';
import '../../enquiries/presentation/screens/enquiry_details_screen.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserWithFirestoreProvider);

    return userAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
      data: (user) {
        if (user == null) {
          return const Scaffold(body: Center(child: Text('Not logged in')));
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          notificationsAsync.whenOrNull(
                data: (notifications) {
                  final hasUnread = notifications.any((n) => n['read'] != true);
                  if (!hasUnread) return null;
                  return TextButton(
                    onPressed: () => service.markAllNotificationsAsRead(userId),
                    child: const Text('Mark all read'),
                  );
                },
              ) ??
              const SizedBox.shrink(),
        ],
      ),
      body: notificationsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (notifications) {
          if (notifications.isEmpty) {
            return _EmptyState();
          }
          return ListView.separated(
            itemCount: notifications.length,
            separatorBuilder: (_, __) => const Divider(height: 1, indent: 72),
            itemBuilder: (context, i) {
              final n = notifications[i];
              return _NotificationTile(
                notification: n,
                onTap: () => _handleTap(context, ref, service, n),
                onDismiss: () =>
                    service.deleteNotification(userId, n['id'] as String),
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
        notification['data']?['enquiryId'] as String? ??
        notification['enquiryId'] as String?;

    // Mark as read
    if (notification['read'] != true) {
      service.markNotificationAsRead(userId, notifId);
    }

    // Navigate to enquiry if available
    if (enquiryId != null && context.mounted) {
      Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => EnquiryDetailsScreen(enquiryId: enquiryId),
        ),
      );
    }
  }
}

// ── Notification tile ─────────────────────────────────────────────────────────

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.notification,
    required this.onTap,
    required this.onDismiss,
  });

  final Map<String, dynamic> notification;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isRead = notification['read'] == true;
    final title = notification['title'] as String? ?? 'Notification';
    final body = notification['body'] as String? ?? '';
    final type =
        notification['data']?['type'] as String? ??
        notification['type'] as String? ??
        '';
    final createdAt = _parseDate(notification['createdAt']);

    return Dismissible(
      key: Key(notification['id'] as String? ?? UniqueKey().toString()),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppTokens.space4),
        color: cs.errorContainer,
        child: Icon(Icons.delete_outline, color: cs.onErrorContainer),
      ),
      onDismissed: (_) => onDismiss(),
      child: InkWell(
        onTap: onTap,
        child: Container(
          color: isRead ? null : cs.primaryContainer.withValues(alpha: 0.15),
          padding: const EdgeInsets.symmetric(
            horizontal: AppTokens.space3,
            vertical: AppTokens.space3,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _iconColor(type, cs).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _iconFor(type),
                  size: 20,
                  color: _iconColor(type, cs),
                ),
              ),
              const SizedBox(width: AppTokens.space3),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: isRead
                                  ? FontWeight.normal
                                  : FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (!isRead) ...[
                          const SizedBox(width: AppTokens.space2),
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: cs.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (body.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        body,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    if (createdAt != null) ...[
                      const SizedBox(height: AppTokens.space1),
                      Text(
                        _relativeTime(createdAt),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: cs.onSurfaceVariant.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _iconFor(String type) {
    return switch (type) {
      'new_enquiry' => Icons.fiber_new_outlined,
      'enquiry_assigned' || 'assignment' => Icons.assignment_ind_outlined,
      'status_update' || 'statusChange' => Icons.update_outlined,
      'enquiry_updated' || 'enquiryUpdate' => Icons.edit_note_outlined,
      'payment_update' || 'paymentUpdate' => Icons.payments_outlined,
      _ => Icons.notifications_outlined,
    };
  }

  Color _iconColor(String type, ColorScheme cs) {
    return switch (type) {
      'new_enquiry' => AppColorScheme.statusColorFor('new'),
      'enquiry_assigned' || 'assignment' => cs.primary,
      'status_update' ||
      'statusChange' => AppColorScheme.statusColorFor('approved'),
      'payment_update' ||
      'paymentUpdate' => AppColorScheme.statusColorFor('completed'),
      _ => cs.secondary,
    };
  }

  DateTime? _parseDate(dynamic v) {
    if (v is Timestamp) return v.toDate();
    if (v is DateTime) return v;
    return null;
  }

  String _relativeTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.notifications_none_outlined,
            size: 64,
            color: cs.onSurfaceVariant,
          ),
          const SizedBox(height: AppTokens.space3),
          Text(
            'All caught up!',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: AppTokens.space1),
          Text(
            'No notifications yet.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: cs.onSurfaceVariant.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}
