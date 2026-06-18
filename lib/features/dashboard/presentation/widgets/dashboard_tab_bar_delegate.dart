import 'package:flutter/material.dart';

class DashboardTabBarDelegate extends SliverPersistentHeaderDelegate {
  DashboardTabBarDelegate(this._tabBar);

  final TabBar _tabBar;

  @override
  double get minExtent => _tabBar.preferredSize.height;

  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Material(elevation: overlapsContent ? 2 : 0, child: _tabBar);
  }

  @override
  bool shouldRebuild(covariant DashboardTabBarDelegate oldDelegate) {
    return oldDelegate._tabBar != _tabBar;
  }
}
