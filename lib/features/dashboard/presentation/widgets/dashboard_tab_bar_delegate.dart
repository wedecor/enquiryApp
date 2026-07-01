import 'package:flutter/material.dart';

/// Pinned sliver header that combines the status [TabBar] with an always-visible
/// search field below it.
///
/// Keeping the search pinned (not in the scrollable welcome header) means users
/// can filter enquiries without first scrolling back to the top.
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

  static const double _searchFieldHeight = 40.0;
  // 4 (top pad) + field + 8 (bottom pad); +8 buffer for Material 3 dense fields on phone
  static const double _searchRowHeight = 4.0 + _searchFieldHeight + 8.0 + 8.0;

  @override
  double get minExtent => _tabBar.preferredSize.height + _searchRowHeight;

  @override
  double get maxExtent => _tabBar.preferredSize.height + _searchRowHeight;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final theme = Theme.of(context);
    final tabHeight = _tabBar.preferredSize.height;
    return Material(
      elevation: overlapsContent ? 2 : 0,
      color: theme.colorScheme.surface,
      child: SizedBox(
        height: minExtent,
        child: Column(
          children: [
            SizedBox(height: tabHeight, child: _tabBar),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
                child: SizedBox(
                  height: _searchFieldHeight,
                  child: TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                      hintText: 'Search by name or phone…',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      suffixIcon: searchQuery.isNotEmpty
                          ? IconButton(
                              tooltip: 'Clear search',
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: onClearSearch,
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(color: theme.colorScheme.primary, width: 1.5),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 14),
                      filled: true,
                      fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
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
    );
  }

  @override
  bool shouldRebuild(covariant DashboardTabBarDelegate old) {
    return old._tabBar != _tabBar ||
        old.searchQuery != searchQuery ||
        old.searchController != searchController;
  }
}
