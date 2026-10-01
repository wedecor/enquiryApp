import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/tokens.dart';
import 'dashboard_search_field.dart';
import 'dashboard_status_bar.dart';

/// Pinned frosted band holding the status segmented bar and the search pill.
/// The band only gains a fill and hairline once content scrolls beneath it.
class DashboardTabBarDelegate extends SliverPersistentHeaderDelegate {
  DashboardTabBarDelegate({
    required this.controller,
    required this.labels,
    this.searchController,
    this.searchQuery = '',
    this.onClearSearch,
  });

  final TabController controller;
  final List<String> labels;
  final TextEditingController? searchController;
  final String searchQuery;
  final VoidCallback? onClearSearch;

  static const double _top = AppTokens.space2;
  static const double _gap = AppTokens.space2;
  static const double _bottom = AppTokens.space3;
  static const double _extent =
      _top + DashboardStatusBar.height + _gap + DashboardSearchField.height + _bottom;

  @override
  double get minExtent => _extent;

  @override
  double get maxExtent => _extent;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final s = AppSurfaces.of(context);
    final floating = shrinkOffset > 0 || overlapsContent;

    return ClipRect(
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: AppTokens.blurSigma, sigmaY: AppTokens.blurSigma),
        child: AnimatedContainer(
          duration: AppMotion.of(context, AppMotion.standard),
          curve: AppMotion.standardCurve,
          color: floating ? s.glassFill : s.glassFill.withValues(alpha: 0),
          foregroundDecoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: floating ? s.microBorder : s.microBorder.withValues(alpha: 0),
              ),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(AppTokens.space4, _top, AppTokens.space4, _bottom),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DashboardStatusBar(controller: controller, labels: labels),
              const SizedBox(height: _gap),
              DashboardSearchField(
                controller: searchController,
                query: searchQuery,
                onClear: onClearSearch,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant DashboardTabBarDelegate old) {
    return old.controller != controller ||
        old.labels != labels ||
        old.searchQuery != searchQuery ||
        old.searchController != searchController ||
        old.onClearSearch != onClearSearch;
  }
}
