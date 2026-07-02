import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/tokens.dart';
import '../../../../shared/models/user_model.dart';
import 'dashboard_today_section.dart';

/// Welcome header and priority section for the dashboard.
///
/// The search bar lives in [DashboardTabBarDelegate] so it stays pinned.
class DashboardWelcomePanel extends StatelessWidget {
  const DashboardWelcomePanel({
    super.key,
    required this.user,
    required this.isAdmin,
    this.onPriorityBucketTap,
    this.onViewAnalytics,
  });

  final UserModel? user;
  final bool isAdmin;

  /// Called when a priority bucket card is tapped; receives bucket key
  /// ('new' | 'reminders' | 'this_week').
  final void Function(String bucket)? onPriorityBucketTap;

  final VoidCallback? onViewAnalytics;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final todayLabel = DateFormat('EEEE, d MMMM').format(DateTime.now());

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: theme.brightness == Brightness.dark
              ? [cs.surfaceContainerHighest.withValues(alpha: 0.45), cs.surface]
              : [cs.primaryContainer.withValues(alpha: 0.55), cs.surface],
          stops: const [0.0, 0.72],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppTokens.space4,
              AppTokens.space4,
              AppTokens.space4,
              AppTokens.space3,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: cs.primary,
                  child: Text(
                    user?.name.isNotEmpty == true
                        ? user!.name[0].toUpperCase()
                        : 'U',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: cs.onPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: AppTokens.space3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _greeting(user?.name),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: AppTokens.space1),
                      Text(
                        todayLabel,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: AppTokens.space2),
                      _RoleBadge(isAdmin: isAdmin),
                    ],
                  ),
                ),
                if (isAdmin && onViewAnalytics != null)
                  Padding(
                    padding: const EdgeInsets.only(left: AppTokens.space2),
                    child: OutlinedButton.icon(
                      onPressed: onViewAnalytics,
                      style: OutlinedButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppTokens.space3,
                          vertical: AppTokens.space2,
                        ),
                      ),
                      icon: const Icon(
                        Icons.insights_outlined,
                        size: AppTokens.iconSmall,
                      ),
                      label: const Text('Analytics'),
                    ),
                  ),
              ],
            ),
          ),

          DashboardTodaySection(
            isAdmin: isAdmin,
            userId: user?.uid,
            onBucketTap: onPriorityBucketTap,
          ),

          const SizedBox(height: AppTokens.space3),
        ],
      ),
    );
  }

  String _greeting(String? name) {
    final hour = DateTime.now().hour;
    final salutation = name?.isNotEmpty == true
        ? ', ${name!.split(' ').first}'
        : '';
    if (hour < 12) return 'Good morning$salutation';
    if (hour < 17) return 'Good afternoon$salutation';
    return 'Good evening$salutation';
  }
}

class _RoleBadge extends StatelessWidget {
  const _RoleBadge({required this.isAdmin});

  final bool isAdmin;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTokens.space2,
        vertical: AppTokens.space1,
      ),
      decoration: BoxDecoration(
        color: isAdmin ? cs.secondaryContainer : cs.tertiaryContainer,
        borderRadius: AppRadius.full,
      ),
      child: Text(
        isAdmin ? 'Administrator' : 'Staff',
        style: theme.textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w600,
          color: isAdmin ? cs.onSecondaryContainer : cs.onTertiaryContainer,
        ),
      ),
    );
  }
}
