import 'package:flutter/material.dart';

import '../../../../core/theme/tokens.dart';
import '../../../../shared/models/user_model.dart';
import 'dashboard_today_section.dart';

/// Welcome header, KPI row, and priority section for the dashboard.
///
/// The search bar has been moved into [DashboardTabBarDelegate] so it stays
/// pinned and accessible without scrolling back to the top.
class DashboardWelcomePanel extends StatelessWidget {
  const DashboardWelcomePanel({
    super.key,
    required this.user,
    required this.isAdmin,
    required this.statsChild,
    this.onPriorityBucketTap,
  });

  final UserModel? user;
  final bool isAdmin;
  final Widget statsChild;

  /// Called when a priority bucket card is tapped; receives bucket key
  /// ('new' | 'reminders' | 'this_week' | 'quote_sent').
  final void Function(String bucket)? onPriorityBucketTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(color: theme.colorScheme.surface, boxShadow: AppShadows.elevation1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Greeting ────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppTokens.space4,
              AppTokens.space3,
              AppTokens.space4,
              AppTokens.space2,
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: Text(
                    user?.name.isNotEmpty == true ? user!.name[0].toUpperCase() : 'U',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
                const SizedBox(width: AppTokens.space2),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _greeting(user?.name),
                        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        isAdmin ? 'Administrator' : 'Staff Member',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── KPI Row (handles its own horizontal padding) ─────────────────
          statsChild,

          // ── Needs Attention ──────────────────────────────────────────────
          DashboardTodaySection(
            isAdmin: isAdmin,
            userId: user?.uid,
            onBucketTap: onPriorityBucketTap,
          ),

          const SizedBox(height: AppTokens.space2),
        ],
      ),
    );
  }

  String _greeting(String? name) {
    final hour = DateTime.now().hour;
    final salutation = name?.isNotEmpty == true ? ', ${name!.split(' ').first}' : '';
    if (hour < 12) return 'Good morning$salutation';
    if (hour < 17) return 'Good afternoon$salutation';
    return 'Good evening$salutation';
  }
}
