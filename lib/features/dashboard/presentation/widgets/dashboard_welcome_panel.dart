import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/tokens.dart';
import '../../../../shared/models/user_model.dart';
import 'dashboard_today_section.dart';

/// Dashboard summary: date line + counter strip.
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
    final todayLabel = DateFormat('EEE, d MMM yyyy').format(DateTime.now());

    // One slim context line + the counter strip. No greeting, avatar or role
    // badge — the app bar already says where you are.
    return ColoredBox(
      color: cs.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppTokens.space4,
              AppTokens.space2,
              AppTokens.space2,
              AppTokens.space2,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    isAdmin ? todayLabel : '$todayLabel · My enquiries',
                    style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                  ),
                ),
                if (isAdmin && onViewAnalytics != null)
                  TextButton.icon(
                    onPressed: onViewAnalytics,
                    style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                    icon: const Icon(Icons.insights_outlined, size: AppTokens.iconSmall),
                    label: const Text('Analytics'),
                  ),
              ],
            ),
          ),
          DashboardTodaySection(
            isAdmin: isAdmin,
            userId: user?.uid,
            onBucketTap: onPriorityBucketTap,
          ),
        ],
      ),
    );
  }
}
