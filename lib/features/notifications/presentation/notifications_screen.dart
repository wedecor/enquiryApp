import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../domain/app_notification.dart';
import '../data/notifications_repository.dart';
import '../../enquiries/presentation/screens/enquiry_details_screen.dart';

/// Notifications center screen
class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            onSelected: _handleMenuAction,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'mark_all_read',
                child: ListTile(
                  leading: Icon(Icons.mark_email_read),
                  title: Text('Mark All Read'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'clear_archived',
                child: ListTile(
                  leading: Icon(Icons.delete_sweep),
                  title: Text('Clear Archived'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Unread', icon: Icon(Icons.mark_email_unread, size: 20)),
            Tab(text: 'All', icon: Icon(Icons.inbox, size: 20)),
            Tab(text: 'Archived', icon: Icon(Icons.archive, size: 20)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildNotificationsList(NotificationFilter.unread),
          _buildNotificationsList(NotificationFilter.all),
          _buildNotificationsList(NotificationFilter.archived),
        ],
      ),
    );
  }

  Widget _buildNotificationsList(NotificationFilter filter) {
    final notificationsAsync = ref.watch(userNotificationsProvider(filter));

    return notificationsAsync.when(
      data: (notifications) {
        if (notifications.isEmpty) {
          return _buildEmptyState(filter);
        }

        return RefreshIndicator(
          onRefresh: () => ref.refresh(userNotificationsProvider(filter).future),
          child: ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification = notifications[index];
              return _buildNotificationCard(notification, filter);
            },
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => _buildErrorState(error.toString()),
    );
  }

  Widget _buildNotificationCard(AppNotification notification, NotificationFilter filter) {
    final repository = ref.read(notificationsRepositoryProvider);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: notification.read ? 1 : 3,
      child: InkWell(
        onTap: () => _handleNotificationTap(notification),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  // Type icon
                  _getNotificationIcon(notification.type),
                  const SizedBox(width: 12),
                  
                  // Title and timestamp
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          notification.title,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: notification.read ? FontWeight.normal : FontWeight.bold,
                          ),
                        ),
                        Text(
                          _formatTimestamp(notification.createdAt),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Unread indicator
                  if (!notification.read)
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              // Body
              Text(
                notification.body,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              
              const SizedBox(height: 12),
              
              // Actions row
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (notification.enquiryId != null)
                    TextButton.icon(
                      onPressed: () => _openEnquiry(notification.enquiryId!),
                      icon: const Icon(Icons.open_in_new, size: 16),
                      label: const Text('View Enquiry'),
                    ),
                  
                  if (!notification.read)
                    TextButton.icon(
                      onPressed: () => repository.markAsRead(notification.id),
                      icon: const Icon(Icons.mark_email_read, size: 16),
                      label: const Text('Mark Read'),
                    ),
                  
                  if (filter != NotificationFilter.archived)
                    TextButton.icon(
                      onPressed: () => repository.archiveNotification(notification.id),
                      icon: const Icon(Icons.archive, size: 16),
                      label: const Text('Archive'),
                    )
                  else
                    TextButton.icon(
                      onPressed: () => repository.deleteNotification(notification.id),
                      icon: const Icon(Icons.delete, size: 16),
                      label: const Text('Delete'),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _getNotificationIcon(NotificationType type) {
    IconData iconData;
    Color iconColor;

    switch (type) {
      case NotificationType.enquiryUpdate:
        iconData = Icons.update;
        iconColor = Colors.blue;
        break;
      case NotificationType.newEnquiry:
        iconData = Icons.add_circle;
        iconColor = Colors.green;
        break;
      case NotificationType.userInvited:
        iconData = Icons.person_add;
        iconColor = Colors.purple;
        break;
      case NotificationType.systemAlert:
        iconData = Icons.info;
        iconColor = Colors.orange;
        break;
    }

    return CircleAvatar(
      radius: 20,
      backgroundColor: iconColor.withOpacity(0.1),
      child: Icon(iconData, color: iconColor, size: 20),
    );
  }

  Widget _buildEmptyState(NotificationFilter filter) {
    String message;
    IconData icon;

    switch (filter) {
      case NotificationFilter.unread:
        message = 'No unread notifications';
        icon = Icons.mark_email_read;
        break;
      case NotificationFilter.archived:
        message = 'No archived notifications';
        icon = Icons.archive;
        break;
      case NotificationFilter.all:
        message = 'No notifications yet';
        icon = Icons.notifications_none;
        break;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            message,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You\'ll see notifications here when they arrive',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red.shade400),
          const SizedBox(height: 16),
          Text(
            'Error loading notifications',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => ref.invalidate(userNotificationsProvider),
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM d, yyyy').format(timestamp);
    }
  }

  void _handleNotificationTap(AppNotification notification) {
    final repository = ref.read(notificationsRepositoryProvider);
    
    // Mark as read when tapped
    if (!notification.read) {
      repository.markAsRead(notification.id);
    }

    // Navigate to enquiry if available
    if (notification.enquiryId != null) {
      _openEnquiry(notification.enquiryId!);
    }
  }

  void _openEnquiry(String enquiryId) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => EnquiryDetailsScreen(enquiryId: enquiryId),
      ),
    );
  }

  void _handleMenuAction(String action) async {
    final repository = ref.read(notificationsRepositoryProvider);

    switch (action) {
      case 'mark_all_read':
        await repository.markAllAsRead();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('All notifications marked as read')),
          );
        }
        break;
      case 'clear_archived':
        await repository.clearArchived();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Archived notifications cleared')),
          );
        }
        break;
    }
  }
}
