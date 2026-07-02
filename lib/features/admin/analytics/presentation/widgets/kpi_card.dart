import 'package:flutter/material.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/theme/tokens.dart';

/// KPI card widget displaying a metric with delta change.
class KpiCard extends StatelessWidget {
  const KpiCard({
    super.key,
    required this.title,
    required this.value,
    this.deltaPercentage,
    required this.icon,
    this.color,
    this.subtitle,
    this.isLoading = false,
  });

  final String title;
  final String value;
  final double? deltaPercentage;
  final IconData icon;
  final Color? color;
  final String? subtitle;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final accent = color ?? cs.primary;

    final cardColor = cs.brightness == Brightness.dark
        ? cs.surfaceContainerHighest.withValues(alpha: 0.55)
        : cs.surface.withValues(alpha: 0.95);

    return Card.filled(
      color: cardColor,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.large,
        side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.7)),
      ),
      clipBehavior: Clip.hardEdge,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTokens.space2,
          vertical: AppTokens.space3,
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact =
                constraints.maxHeight.isFinite && constraints.maxHeight < 130;
            final narrow =
                constraints.maxWidth.isFinite && constraints.maxWidth < 150;
            final iconSize = compact ? 30.0 : 36.0;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SizedBox(
                  width: double.infinity,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: iconSize,
                        height: iconSize,
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.15),
                          borderRadius: AppRadius.medium,
                        ),
                        alignment: Alignment.center,
                        child: Icon(
                          icon,
                          color: accent,
                          size: compact
                              ? AppTokens.iconSmall
                              : AppTokens.iconMedium,
                        ),
                      ),
                      if (deltaPercentage != null && !isLoading) ...[
                        const Spacer(),
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerRight,
                            child: _buildDeltaIndicator(
                              deltaPercentage!,
                              theme,
                              decimals: narrow ? 0 : 1,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: AppTokens.space1),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                    fontSize: compact ? AppTokens.fontSizeSmall : null,
                  ),
                ),
                const SizedBox(height: AppTokens.space1),
                if (isLoading)
                  Container(
                    height: compact ? 22 : 28,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: cs.onSurface.withValues(alpha: 0.08),
                      borderRadius: AppRadius.small,
                    ),
                    child: const Center(
                      child: SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  )
                else
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      value,
                      maxLines: 1,
                      style:
                          (compact
                                  ? theme.textTheme.titleLarge
                                  : theme.textTheme.headlineSmall)
                              ?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: cs.onSurface,
                              ),
                    ),
                  ),
                if (subtitle != null && !isLoading && !compact) ...[
                  const SizedBox(height: AppTokens.space1),
                  Text(
                    subtitle!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildDeltaIndicator(
    double deltaPercentage,
    ThemeData theme, {
    int decimals = 1,
  }) {
    final isPositive = deltaPercentage >= 0;
    final isNeutral = deltaPercentage == 0;

    Color deltaColor;
    IconData deltaIcon;

    if (isNeutral) {
      deltaColor = theme.colorScheme.onSurfaceVariant;
      deltaIcon = Icons.remove_rounded;
    } else if (isPositive) {
      deltaColor = AppColorScheme.chartGreen;
      deltaIcon = Icons.trending_up_rounded;
    } else {
      deltaColor = AppColorScheme.chartRed;
      deltaIcon = Icons.trending_down_rounded;
    }

    final formatted = isNeutral
        ? '0'
        : '${isPositive ? '+' : ''}${deltaPercentage.toStringAsFixed(decimals)}%';

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTokens.space2,
        vertical: AppTokens.space1,
      ),
      decoration: BoxDecoration(
        color: deltaColor.withValues(alpha: 0.12),
        borderRadius: AppRadius.full,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(deltaIcon, color: deltaColor, size: 12),
          const SizedBox(width: AppTokens.space1),
          Text(
            formatted,
            maxLines: 1,
            style: theme.textTheme.labelSmall?.copyWith(
              color: deltaColor,
              fontWeight: FontWeight.w600,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

/// Specialized KPI cards for different metrics.
class TotalEnquiriesCard extends StatelessWidget {
  const TotalEnquiriesCard({
    super.key,
    required this.count,
    this.deltaPercentage,
    this.isLoading = false,
  });

  final int count;
  final double? deltaPercentage;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return KpiCard(
      title: 'Total Enquiries',
      value: isLoading ? '...' : count.toString(),
      deltaPercentage: deltaPercentage,
      icon: Icons.inbox_rounded,
      color: AppColorScheme.chartBlue,
      isLoading: isLoading,
    );
  }
}

class ActiveEnquiriesCard extends StatelessWidget {
  const ActiveEnquiriesCard({
    super.key,
    required this.count,
    this.deltaPercentage,
    this.isLoading = false,
  });

  final int count;
  final double? deltaPercentage;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return KpiCard(
      title: 'Active Enquiries',
      value: isLoading ? '...' : count.toString(),
      deltaPercentage: deltaPercentage,
      icon: Icons.pending_actions_rounded,
      color: AppColorScheme.chartAmber,
      subtitle: 'New, In Progress, Quote Sent',
      isLoading: isLoading,
    );
  }
}

class WonEnquiriesCard extends StatelessWidget {
  const WonEnquiriesCard({
    super.key,
    required this.count,
    this.deltaPercentage,
    this.isLoading = false,
  });

  final int count;
  final double? deltaPercentage;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return KpiCard(
      title: 'Won Enquiries',
      value: isLoading ? '...' : count.toString(),
      deltaPercentage: deltaPercentage,
      icon: Icons.check_circle_outline_rounded,
      color: AppColorScheme.chartGreen,
      subtitle: 'Confirmed, Completed',
      isLoading: isLoading,
    );
  }
}

class LostEnquiriesCard extends StatelessWidget {
  const LostEnquiriesCard({
    super.key,
    required this.count,
    this.deltaPercentage,
    this.isLoading = false,
  });

  final int count;
  final double? deltaPercentage;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return KpiCard(
      title: 'Lost Enquiries',
      value: isLoading ? '...' : count.toString(),
      deltaPercentage: deltaPercentage,
      icon: Icons.cancel_outlined,
      color: AppColorScheme.chartRed,
      subtitle: 'Cancelled, Closed Lost',
      isLoading: isLoading,
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
      value: isLoading ? '...' : _formatCurrency(revenue),
      deltaPercentage: deltaPercentage,
      icon: Icons.payments_outlined,
      color: AppColorScheme.chartCyan,
      subtitle: 'Total Cost Sum',
      isLoading: isLoading,
    );
  }

  String _formatCurrency(double amount) {
    if (amount == 0) return '—';

    if (amount >= 1000000) {
      return '₹${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 100000) {
      return '₹${(amount / 100000).toStringAsFixed(1)}L';
    } else if (amount >= 1000) {
      return '₹${(amount / 1000).toStringAsFixed(1)}K';
    } else {
      return '₹${amount.toStringAsFixed(0)}';
    }
  }
}
