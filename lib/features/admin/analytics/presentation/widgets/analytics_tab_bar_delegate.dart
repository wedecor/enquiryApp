import 'package:flutter/material.dart';

import '../../../../../core/theme/tokens.dart';

/// Pinned pill-style tab bar for the analytics screen.
class AnalyticsTabBarDelegate extends SliverPersistentHeaderDelegate {
  AnalyticsTabBarDelegate(this._tabBar);

  final TabBar _tabBar;

  @override
  double get minExtent => _tabBar.preferredSize.height + AppTokens.space2;

  @override
  double get maxExtent => _tabBar.preferredSize.height + AppTokens.space2;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final cs = Theme.of(context).colorScheme;

    return Material(
      color: cs.surface,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: cs.surface,
          border: Border(bottom: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.7))),
          boxShadow: overlapsContent ? AppShadows.elevation1 : null,
        ),
        child: Padding(
          padding: const EdgeInsets.only(bottom: AppTokens.space2),
          child: SizedBox(height: _tabBar.preferredSize.height, child: _tabBar),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant AnalyticsTabBarDelegate oldDelegate) {
    return oldDelegate._tabBar != _tabBar;
  }
}

/// Builds a pill-style tab bar matching the main dashboard aesthetic.
TabBar buildAnalyticsTabBar({required BuildContext context, required TabController controller}) {
  final cs = Theme.of(context).colorScheme;

  return TabBar(
    controller: controller,
    isScrollable: true,
    tabAlignment: TabAlignment.start,
    dividerColor: Colors.transparent,
    indicatorSize: TabBarIndicatorSize.tab,
    labelPadding: const EdgeInsets.symmetric(horizontal: AppTokens.space2),
    indicatorPadding: const EdgeInsets.symmetric(vertical: AppTokens.space1),
    padding: const EdgeInsets.symmetric(horizontal: AppTokens.space4, vertical: AppTokens.space2),
    indicator: BoxDecoration(borderRadius: AppRadius.full, color: cs.primaryContainer),
    labelColor: cs.onPrimaryContainer,
    unselectedLabelColor: cs.onSurfaceVariant,
    labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: AppTokens.fontSizeBody),
    unselectedLabelStyle: const TextStyle(
      fontWeight: FontWeight.w500,
      fontSize: AppTokens.fontSizeBody,
    ),
    tabs: const [
      Tab(
        height: 40,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: AppTokens.space4),
          child: Text('Overview'),
        ),
      ),
      Tab(
        height: 40,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: AppTokens.space4),
          child: Text('Trends'),
        ),
      ),
      Tab(
        height: 40,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: AppTokens.space4),
          child: Text('Breakdown'),
        ),
      ),
      Tab(
        height: 40,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: AppTokens.space4),
          child: Text('Tables'),
        ),
      ),
    ],
  );
}
