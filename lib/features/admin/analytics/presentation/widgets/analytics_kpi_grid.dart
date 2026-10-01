import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/tokens.dart';
import '../../../../../ui/primitives/primitives.dart';
import '../../domain/analytics_models.dart';
import '../analytics_controller.dart';
import 'analytics_format.dart';
import 'kpi_metric_cards.dart';

/// Asymmetric KPI layout driven by [analyticsControllerProvider]: one hero
/// metric with spark bars, then smaller glass tiles in staggered columns.
class AnalyticsKpiGrid extends ConsumerWidget {
  const AnalyticsKpiGrid({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analyticsAsync = ref.watch(analyticsControllerProvider);

    return analyticsAsync.when(
      data: (state) {
        if (state.kpiSummary == null) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.fromLTRB(
            AppTokens.space4,
            AppTokens.space2,
            AppTokens.space4,
            AppTokens.space3,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(left: AppTokens.space1),
                child: Eyebrow('Key metrics'),
              ),
              const SizedBox(height: AppTokens.space3),
              _KpiLayout(state: state),
            ],
          ),
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(horizontal: AppTokens.space4, vertical: AppTokens.space6),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Padding(
        padding: const EdgeInsets.fromLTRB(
          AppTokens.space4,
          AppTokens.space3,
          AppTokens.space4,
          AppTokens.space2,
        ),
        child: Text(
          'Unable to load analytics summary',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.error),
        ),
      ),
    );
  }
}

class _KpiLayout extends StatelessWidget {
  const _KpiLayout({required this.state});

  final AnalyticsState state;

  static const double _gap = AppTokens.space3;

  @override
  Widget build(BuildContext context) {
    final kpi = state.kpiSummary!;
    final isLoading = state.isLoading;
    final total = kpi.totalEnquiries;
    double? shareOf(int n) => total > 0 ? n / total : null;

    final trend = bucketValues([for (final p in state.timeSeries) p.count.toDouble()]);

    final hero = StaggerIn(
      index: 0,
      child: TotalEnquiriesCard(
        count: kpi.totalEnquiries,
        deltaPercentage: kpi.deltas.totalEnquiriesChange,
        isLoading: isLoading,
        hero: true,
        trend: trend,
      ),
    );
    final active = StaggerIn(
      index: 1,
      child: ActiveEnquiriesCard(
        count: kpi.activeEnquiries,
        deltaPercentage: kpi.deltas.activeEnquiriesChange,
        isLoading: isLoading,
        share: shareOf(kpi.activeEnquiries),
      ),
    );
    final won = StaggerIn(
      index: 2,
      child: WonEnquiriesCard(
        count: kpi.wonEnquiries,
        deltaPercentage: kpi.deltas.wonEnquiriesChange,
        isLoading: isLoading,
        share: shareOf(kpi.wonEnquiries),
      ),
    );
    final conversion = StaggerIn(
      index: 3,
      child: ConversionRateCard(
        rate: kpi.conversionRate,
        deltaPercentage: kpi.deltas.conversionRateChange,
        isLoading: isLoading,
      ),
    );
    final lost = StaggerIn(
      index: 4,
      child: LostEnquiriesCard(
        count: kpi.lostEnquiries,
        deltaPercentage: kpi.deltas.lostEnquiriesChange,
        isLoading: isLoading,
        share: shareOf(kpi.lostEnquiries),
      ),
    );
    final revenue = StaggerIn(
      index: 5,
      child: EstimatedRevenueCard(
        revenue: kpi.estimatedRevenue,
        deltaPercentage: kpi.deltas.estimatedRevenueChange,
        isLoading: isLoading,
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        if (width >= AppTokens.breakpointTablet) {
          return _row([
            (2, hero),
            (1, _stack([active, won])),
            (1, conversion),
            (1, _stack([lost, revenue])),
          ]);
        }

        if (width >= 520) {
          return Column(
            children: [
              _row([
                (3, hero),
                (2, _stack([active, won])),
              ]),
              const SizedBox(height: _gap),
              _row([
                (2, conversion),
                (3, _stack([lost, revenue])),
              ]),
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            IntrinsicHeight(child: hero),
            const SizedBox(height: _gap),
            _row([
              (1, _stack([active, won])),
              (1, conversion),
            ]),
            const SizedBox(height: _gap),
            _row([(3, revenue), (2, lost)]),
          ],
        );
      },
    );
  }

  /// Equal-height row whose cells share space by flex.
  static Widget _row(List<(int, Widget)> cells) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < cells.length; i++) ...[
            if (i > 0) const SizedBox(width: _gap),
            Expanded(flex: cells[i].$1, child: cells[i].$2),
          ],
        ],
      ),
    );
  }

  static Widget _stack(List<Widget> tiles) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < tiles.length; i++) ...[
          if (i > 0) const SizedBox(height: _gap),
          Expanded(child: tiles[i]),
        ],
      ],
    );
  }
}
