import 'package:flutter/material.dart';

/// KPI card widget displaying a metric with delta change
class KpiCard extends StatelessWidget {
  final String title;
  final String value;
  final double? deltaPercentage;
  final IconData icon;
  final Color? color;
  final String? subtitle;
  final bool isLoading;

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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cardColor = color ?? theme.colorScheme.primary;

    return Card(
      elevation: 2,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [cardColor.withOpacity(0.1), cardColor.withOpacity(0.05)],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header row with icon and delta
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: cardColor, size: 24),
                if (deltaPercentage != null && !isLoading)
                  _buildDeltaIndicator(deltaPercentage!, theme),
              ],
            ),

            const SizedBox(height: 12),

            // Title
            Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
                fontWeight: FontWeight.w500,
              ),
            ),

            const SizedBox(height: 4),

            // Value
            if (isLoading)
              Container(
                height: 32,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurface.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
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
              Text(
                value,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),

            // Subtitle if provided
            if (subtitle != null && !isLoading) ...[
              const SizedBox(height: 4),
              Text(
                subtitle!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDeltaIndicator(double deltaPercentage, ThemeData theme) {
    final isPositive = deltaPercentage >= 0;
    final isNeutral = deltaPercentage == 0;

    Color deltaColor;
    IconData deltaIcon;

    if (isNeutral) {
      deltaColor = theme.colorScheme.onSurface.withOpacity(0.5);
      deltaIcon = Icons.remove;
    } else if (isPositive) {
      deltaColor = Colors.green;
      deltaIcon = Icons.trending_up;
    } else {
      deltaColor = Colors.red;
      deltaIcon = Icons.trending_down;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: deltaColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(deltaIcon, color: deltaColor, size: 16),
          const SizedBox(width: 4),
          Text(
            '${isNeutral
                ? '0'
                : isPositive
                ? '+'
                : ''}${deltaPercentage.toStringAsFixed(1)}%',
            style: theme.textTheme.bodySmall?.copyWith(
              color: deltaColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Specialized KPI cards for different metrics
class TotalEnquiriesCard extends StatelessWidget {
  final int count;
  final double? deltaPercentage;
  final bool isLoading;

  const TotalEnquiriesCard({
    super.key,
    required this.count,
    this.deltaPercentage,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return KpiCard(
      title: 'Total Enquiries',
      value: isLoading ? '...' : count.toString(),
      deltaPercentage: deltaPercentage,
      icon: Icons.inbox,
      color: const Color(0xFF2563EB), // Blue
      isLoading: isLoading,
    );
  }
}

class ActiveEnquiriesCard extends StatelessWidget {
  final int count;
  final double? deltaPercentage;
  final bool isLoading;

  const ActiveEnquiriesCard({
    super.key,
    required this.count,
    this.deltaPercentage,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return KpiCard(
      title: 'Active Enquiries',
      value: isLoading ? '...' : count.toString(),
      deltaPercentage: deltaPercentage,
      icon: Icons.pending,
      color: Colors.orange,
      subtitle: 'New, In Progress, Quote Sent',
      isLoading: isLoading,
    );
  }
}

class WonEnquiriesCard extends StatelessWidget {
  final int count;
  final double? deltaPercentage;
  final bool isLoading;

  const WonEnquiriesCard({
    super.key,
    required this.count,
    this.deltaPercentage,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return KpiCard(
      title: 'Won Enquiries',
      value: isLoading ? '...' : count.toString(),
      deltaPercentage: deltaPercentage,
      icon: Icons.check_circle,
      color: Colors.green,
      subtitle: 'Confirmed, Completed',
      isLoading: isLoading,
    );
  }
}

class LostEnquiriesCard extends StatelessWidget {
  final int count;
  final double? deltaPercentage;
  final bool isLoading;

  const LostEnquiriesCard({
    super.key,
    required this.count,
    this.deltaPercentage,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return KpiCard(
      title: 'Lost Enquiries',
      value: isLoading ? '...' : count.toString(),
      deltaPercentage: deltaPercentage,
      icon: Icons.cancel,
      color: Colors.red,
      subtitle: 'Cancelled, Closed Lost',
      isLoading: isLoading,
    );
  }
}

class ConversionRateCard extends StatelessWidget {
  final double rate;
  final double? deltaPercentage;
  final bool isLoading;

  const ConversionRateCard({
    super.key,
    required this.rate,
    this.deltaPercentage,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return KpiCard(
      title: 'Conversion Rate',
      value: isLoading ? '...' : '${rate.toStringAsFixed(1)}%',
      deltaPercentage: deltaPercentage,
      icon: Icons.trending_up,
      color: Colors.purple,
      subtitle: 'Won / (Won + Lost)',
      isLoading: isLoading,
    );
  }
}

class EstimatedRevenueCard extends StatelessWidget {
  final double revenue;
  final double? deltaPercentage;
  final bool isLoading;

  const EstimatedRevenueCard({
    super.key,
    required this.revenue,
    this.deltaPercentage,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return KpiCard(
      title: 'Est. Revenue',
      value: isLoading ? '...' : _formatCurrency(revenue),
      deltaPercentage: deltaPercentage,
      icon: Icons.attach_money,
      color: Colors.teal,
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
