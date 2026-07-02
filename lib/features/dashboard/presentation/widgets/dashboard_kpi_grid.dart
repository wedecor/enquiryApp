import 'package:flutter/material.dart';

import '../../../../core/theme/tokens.dart';

/// Responsive KPI grid for the dashboard overview section.
///
/// - Mobile: 2 columns
/// - Tablet: 3 columns
/// - Desktop: 4 columns
class DashboardKpiGrid extends StatelessWidget {
  const DashboardKpiGrid({super.key, required this.items});

  final List<Widget> items;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final crossAxisCount = width >= AppTokens.breakpointDesktop
            ? 4
            : width >= AppTokens.breakpointTablet
            ? 3
            : 2;

        return GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: AppTokens.space3,
          mainAxisSpacing: AppTokens.space3,
          childAspectRatio: crossAxisCount >= 3 ? 1.7 : 1.45,
          padding: AppSpacing.horizontal4,
          children: items,
        );
      },
    );
  }
}
