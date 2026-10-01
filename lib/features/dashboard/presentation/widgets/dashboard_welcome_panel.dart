import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../shared/models/user_model.dart';
import '../../../../ui/primitives/primitives.dart';
import 'dashboard_today_section.dart';

/// Editorial dashboard hero: date eyebrow, split-weight greeting and the
/// asymmetric metric cluster.
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

  static String _greeting(DateTime now) {
    if (now.hour < 12) return 'Good morning,';
    if (now.hour < 17) return 'Good afternoon,';
    return 'Good evening,';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final todayLabel = DateFormat('EEE, d MMM yyyy').format(now);
    final firstName = (user?.name ?? '').trim().split(RegExp(r'\s+')).first;
    final hasName = firstName.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTokens.space4,
        AppTokens.space3,
        AppTokens.space4,
        AppTokens.space2,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppTokens.space1),
            child: Row(
              children: [
                Expanded(
                  child: Eyebrow(isAdmin ? todayLabel : '$todayLabel · My enquiries', accent: true),
                ),
                if (isAdmin && onViewAnalytics != null) _AnalyticsChip(onTap: onViewAnalytics!),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppTokens.space1,
              AppTokens.space1,
              AppTokens.space1,
              AppTokens.space5,
            ),
            child: SplitHeading(
              light: hasName ? _greeting(now) : "Here's your",
              bold: hasName ? firstName : 'Today',
              style: theme.textTheme.headlineLarge?.copyWith(letterSpacing: -0.8, height: 1.1),
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

/// Gold-inked glass chip that opens Analytics; keeps a 48px tap height.
class _AnalyticsChip extends StatelessWidget {
  const _AnalyticsChip({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = AppSurfaces.of(context);
    final t = Theme.of(context).textTheme;

    return Pressable(
      onTap: onTap,
      pressedScale: 0.94,
      borderRadius: AppRadius.full,
      child: SizedBox(
        height: AppTokens.minTapTarget,
        child: Center(
          child: GlassPanel(
            strong: true,
            borderRadius: AppRadius.full,
            borderColor: s.accent.withValues(alpha: 0.35),
            padding: const EdgeInsets.symmetric(
              horizontal: AppTokens.space3 + 2,
              vertical: AppTokens.space2,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.insights_outlined, size: AppTokens.iconSmall, color: s.accentInk),
                const SizedBox(width: AppTokens.space1 + 2),
                Text(
                  'Analytics',
                  style: t.labelLarge?.copyWith(fontWeight: FontWeight.w700, color: s.accentInk),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
