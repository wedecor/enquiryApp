import 'package:flutter/material.dart';

import '../../../../core/theme/tokens.dart';

/// Pinned sliver header combining pill-style status tabs with a search field.
class DashboardTabBarDelegate extends SliverPersistentHeaderDelegate {
  DashboardTabBarDelegate(
    this._tabBar, {
    this.searchController,
    this.searchQuery = '',
    this.onClearSearch,
  });

  final TabBar _tabBar;
  final TextEditingController? searchController;
  final String searchQuery;
  final VoidCallback? onClearSearch;

  static const double _searchFieldHeight = 44.0;
  static const double _searchRowHeight =
      AppTokens.space2 + _searchFieldHeight + AppTokens.space3;

  @override
  double get minExtent => _tabBar.preferredSize.height + _searchRowHeight;

  @override
  double get maxExtent => _tabBar.preferredSize.height + _searchRowHeight;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final tabHeight = _tabBar.preferredSize.height;

    return Material(
      elevation: overlapsContent ? AppTokens.elevation1 : 0,
      color: cs.surface,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: cs.surface,
          border: Border(
            top: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.6)),
            bottom: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.8)),
          ),
          boxShadow: overlapsContent ? AppShadows.elevation1 : null,
        ),
        child: SizedBox(
          height: minExtent,
          child: Column(
            children: [
              SizedBox(height: tabHeight, child: _tabBar),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppTokens.space4,
                    AppTokens.space1,
                    AppTokens.space4,
                    AppTokens.space3,
                  ),
                  child: SizedBox(
                    height: _searchFieldHeight,
                    child: TextField(
                      controller: searchController,
                      decoration: InputDecoration(
                        hintText: 'Search by name or phone…',
                        hintStyle: theme.textTheme.bodyMedium?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                        prefixIcon: Icon(
                          Icons.search_rounded,
                          size: AppTokens.iconMedium,
                          color: cs.onSurfaceVariant,
                        ),
                        suffixIcon: searchQuery.isNotEmpty
                            ? IconButton(
                                tooltip: 'Clear search',
                                icon: const Icon(
                                  Icons.clear_rounded,
                                  size: AppTokens.iconSmall,
                                ),
                                onPressed: onClearSearch,
                              )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: AppRadius.full,
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: AppRadius.full,
                          borderSide: BorderSide(
                            color: cs.outlineVariant.withValues(alpha: 0.6),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: AppRadius.full,
                          borderSide: BorderSide(color: cs.primary, width: 1.5),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 0,
                          horizontal: AppTokens.space3,
                        ),
                        filled: true,
                        fillColor: cs.surfaceContainerHighest.withValues(
                          alpha: 0.45,
                        ),
                        isDense: true,
                      ),
                      textInputAction: TextInputAction.search,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant DashboardTabBarDelegate old) {
    return old._tabBar != _tabBar ||
        old.searchQuery != searchQuery ||
        old.searchController != searchController;
  }
}
