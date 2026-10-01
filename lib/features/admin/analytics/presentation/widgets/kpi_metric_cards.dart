import 'package:flutter/material.dart';

import '../../../../../core/theme/app_theme.dart';
import 'analytics_format.dart';
import 'kpi_card.dart';

/// Specialized KPI cards for the analytics metrics.
class TotalEnquiriesCard extends StatelessWidget {
  const TotalEnquiriesCard({
    super.key,
    required this.count,
    this.deltaPercentage,
    this.isLoading = false,
    this.hero = false,
    this.trend,
  });

  final int count;
  final double? deltaPercentage;
  final bool isLoading;
  final bool hero;
  final List<double>? trend;

  @override
  Widget build(BuildContext context) {
    return KpiCard(
      title: 'Total Enquiries',
      value: isLoading ? '...' : count.toString(),
      deltaPercentage: deltaPercentage,
      icon: Icons.inbox_rounded,
      color: AppColorScheme.chartBlue,
      isLoading: isLoading,
      hero: hero,
      trend: trend,
    );
  }
}

class ActiveEnquiriesCard extends StatelessWidget {
  const ActiveEnquiriesCard({
    super.key,
    required this.count,
    this.deltaPercentage,
    this.isLoading = false,
    this.share,
  });

  final int count;
  final double? deltaPercentage;
  final bool isLoading;
  final double? share;

  @override
  Widget build(BuildContext context) {
    return KpiCard(
      title: 'Active Enquiries',
      value: isLoading ? '...' : count.toString(),
      deltaPercentage: deltaPercentage,
      icon: Icons.pending_actions_rounded,
      color: AppColorScheme.chartAmber,
      subtitle: 'New, In Talks',
      isLoading: isLoading,
      share: share,
    );
  }
}

class WonEnquiriesCard extends StatelessWidget {
  const WonEnquiriesCard({
    super.key,
    required this.count,
    this.deltaPercentage,
    this.isLoading = false,
    this.share,
  });

  final int count;
  final double? deltaPercentage;
  final bool isLoading;
  final double? share;

  @override
  Widget build(BuildContext context) {
    return KpiCard(
      title: 'Won Enquiries',
      value: isLoading ? '...' : count.toString(),
      deltaPercentage: deltaPercentage,
      icon: Icons.check_circle_outline_rounded,
      color: AppColorScheme.chartGreen,
      subtitle: 'Approved, Completed',
      isLoading: isLoading,
      share: share,
    );
  }
}

class LostEnquiriesCard extends StatelessWidget {
  const LostEnquiriesCard({
    super.key,
    required this.count,
    this.deltaPercentage,
    this.isLoading = false,
    this.share,
  });

  final int count;
  final double? deltaPercentage;
  final bool isLoading;
  final double? share;

  @override
  Widget build(BuildContext context) {
    return KpiCard(
      title: 'Lost Enquiries',
      value: isLoading ? '...' : count.toString(),
      deltaPercentage: deltaPercentage,
      icon: Icons.cancel_outlined,
      color: AppColorScheme.chartRed,
      subtitle: 'Not Interested, Closed Lost, Cancelled',
      isLoading: isLoading,
      share: share,
    );
  }
}

class ConversionRateCard extends StatelessWidget {
  const ConversionRateCard({
    super.key,
    required this.rate,
    this.deltaPercentage,
    this.isLoading = false,
  });

  final double rate;
  final double? deltaPercentage;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return KpiCard(
      title: 'Conversion Rate',
      value: isLoading ? '...' : '${rate.toStringAsFixed(1)}%',
      deltaPercentage: deltaPercentage,
      icon: Icons.trending_up_rounded,
      color: AppColorScheme.chartPurple,
      subtitle: 'Won / (Won + Lost)',
      isLoading: isLoading,
      gauge: (rate / 100).clamp(0.0, 1.0),
    );
  }
}

class EstimatedRevenueCard extends StatelessWidget {
  const EstimatedRevenueCard({
    super.key,
    required this.revenue,
    this.deltaPercentage,
    this.isLoading = false,
  });

  final double revenue;
  final double? deltaPercentage;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return KpiCard(
      title: 'Est. Revenue',
      value: isLoading ? '...' : formatAnalyticsCurrency(revenue),
      deltaPercentage: deltaPercentage,
      icon: Icons.payments_outlined,
      color: AppColorScheme.chartCyan,
      subtitle: 'Booked value of enquiries created in this period',
      isLoading: isLoading,
    );
  }
}
