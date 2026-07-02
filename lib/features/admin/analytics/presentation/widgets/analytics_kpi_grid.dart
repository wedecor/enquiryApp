import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/tokens.dart';
import '../../domain/analytics_models.dart';
import '../analytics_controller.dart';
import 'kpi_card.dart';

/// Responsive KPI grid driven by [analyticsControllerProvider].
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
            AppTokens.space3,
            AppTokens.space4,
            AppTokens.space2,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Key metrics',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: AppTokens.space3),
              _KpiGridBody(state: state),
            ],
          ),
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(
          horizontal: AppTokens.space4,
          vertical: AppTokens.space6,
        ),
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
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.error,
          ),
        ),
      ),
    );
  }
}

class _KpiGridBody extends StatelessWidget {
  const _KpiGridBody({required this.state});

  final AnalyticsState state;

  @override
  Widget build(BuildContext context) {
    final kpi = state.kpiSummary!;
    final isLoading = state.isLoading;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final int crossAxisCount;
        final double childAspectRatio;

        if (width < AppTokens.breakpointTablet) {
          crossAxisCount = 2;
          // Taller cells — KPI cards need room for icon, value, subtitle, and delta.
          childAspectRatio = width < 360 ? 0.82 : 0.9;
        } else if (width < AppTokens.breakpointDesktop) {
          crossAxisCount = 3;
          childAspectRatio = 1.15;
        } else {
          crossAxisCount = width >= 1200 ? 4 : 3;
          childAspectRatio = 1.25;
        }

        return GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: AppTokens.space3,
          crossAxisSpacing: AppTokens.space3,
          childAspectRatio: childAspectRatio,
          children: [
            TotalEnquiriesCard(
              count: kpi.totalEnquiries,
              deltaPercentage: kpi.deltas.totalEnquiriesChange,
              isLoading: isLoading,
            ),
            ActiveEnquiriesCard(
              count: kpi.activeEnquiries,
              deltaPercentage: kpi.deltas.activeEnquiriesChange,
              isLoading: isLoading,
            ),
            WonEnquiriesCard(
              count: kpi.wonEnquiries,
              deltaPercentage: kpi.deltas.wonEnquiriesChange,
              isLoading: isLoading,
            ),
            LostEnquiriesCard(
              count: kpi.lostEnquiries,
              deltaPercentage: kpi.deltas.lostEnquiriesChange,
              isLoading: isLoading,
            ),
            ConversionRateCard(
              rate: kpi.conversionRate,
              deltaPercentage: kpi.deltas.conversionRateChange,
              isLoading: isLoading,
            ),
            EstimatedRevenueCard(
              revenue: kpi.estimatedRevenue,
              deltaPercentage: kpi.deltas.estimatedRevenueChange,
              isLoading: isLoading,
            ),
          ],
        );
      },
    );
  }
}
