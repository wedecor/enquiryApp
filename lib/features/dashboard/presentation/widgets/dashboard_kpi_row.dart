import 'package:flutter/material.dart';

import '../../../../core/theme/tokens.dart';

/// Responsive KPI row for the dashboard header.
///
/// - Phone (< 768 px): compact horizontal scrolling strip — one row, no grid stacking.
/// - Tablet (768–1023 px): 3-column grid.
/// - Desktop (≥ 1024 px): 4-column grid.
class DashboardKpiRow extends StatelessWidget {
  const DashboardKpiRow({super.key, required this.items});

  final List<Widget> items;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;

    // ── Phone: horizontal scroll strip ────────────────────────────────────
    if (width < AppTokens.breakpointTablet) {
      return SizedBox(
        height: 118,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: AppTokens.space4),
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(width: AppTokens.space2),
          itemBuilder: (_, i) => SizedBox(width: 168, child: items[i]),
        ),
      );
    }

    // ── Desktop: 4-column grid ─────────────────────────────────────────────
    if (width >= AppTokens.breakpointDesktop) {
      return GridView.count(
        crossAxisCount: 4,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: AppTokens.space3,
        mainAxisSpacing: AppTokens.space3,
        childAspectRatio: 2.1,
        padding: AppSpacing.horizontal4,
        children: items,
      );
    }

    // ── Tablet: 3-column grid ──────────────────────────────────────────────
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: AppTokens.space3,
      mainAxisSpacing: AppTokens.space3,
      childAspectRatio: 1.85,
      padding: AppSpacing.horizontal4,
      children: items,
    );
  }
}
