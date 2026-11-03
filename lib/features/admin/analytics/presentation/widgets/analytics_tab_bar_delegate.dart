import 'package:flutter/material.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/theme/tokens.dart';
import '../../../../../ui/primitives/primitives.dart';

/// Pinned header holding the analytics tab pill. The pill is frosted glass so
/// content and the ambient ground blur softly beneath it.
class AnalyticsTabBarDelegate extends SliverPersistentHeaderDelegate {
  AnalyticsTabBarDelegate(this._tabBar);

  final TabBar _tabBar;

  static const double _pillPadding = 4;
  static const double _verticalInset = AppTokens.space2;

  double get _extent => _tabBar.preferredSize.height + _pillPadding * 2 + _verticalInset * 2;

  @override
  double get minExtent => _extent;

  @override
  double get maxExtent => _extent;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTokens.space4, vertical: _verticalInset),
      child: AnimatedContainer(
        duration: AppMotion.of(context, AppMotion.standard),
        curve: AppMotion.standardCurve,
        decoration: BoxDecoration(
          borderRadius: AppRadius.full,
          boxShadow: overlapsContent
              ? AppShadows.glow(AppSurfaces.of(context).shadow, strength: 0.10)
              : const [],
        ),
        child: GlassPanel(
          blur: true,
          strong: true,
          borderRadius: AppRadius.full,
          padding: const EdgeInsets.all(_pillPadding),
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

/// Tab pill whose ink indicator slides between Overview, Trends, Breakdown and
/// Tables. Labels scale down rather than truncate on narrow phones.
TabBar buildAnalyticsTabBar({required BuildContext context, required TabController controller}) {
  final cs = Theme.of(context).colorScheme;
  final s = AppSurfaces.of(context);
  final label = Theme.of(context).textTheme.labelLarge;

  Tab tab(String text) => Tab(
    height: 44,
    child: FittedBox(
      fit: BoxFit.scaleDown,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppTokens.space2),
        child: Text(text, maxLines: 1),
      ),
    ),
  );

  return TabBar(
    controller: controller,
    // Seven tabs: scroll sideways on phones instead of squeezing labels.
    isScrollable: true,
    tabAlignment: TabAlignment.start,
    dividerColor: Colors.transparent,
    indicatorSize: TabBarIndicatorSize.tab,
    labelPadding: const EdgeInsets.symmetric(horizontal: 2),
    splashBorderRadius: AppRadius.full,
    indicator: BoxDecoration(
      gradient: s.inkGradient,
      borderRadius: AppRadius.full,
      boxShadow: AppShadows.glow(s.shadow, strength: 0.14),
    ),
    labelColor: cs.onPrimary,
    unselectedLabelColor: cs.onSurfaceVariant,
    labelStyle: label?.copyWith(fontWeight: FontWeight.w800, letterSpacing: 0.1),
    unselectedLabelStyle: label?.copyWith(fontWeight: FontWeight.w500),
    tabs: [
      tab('Overview'),
      tab('Pipeline'),
      tab('Team'),
      tab('Money'),
      tab('Trends'),
      tab('Breakdown'),
      tab('Tables'),
    ],
  );
}
