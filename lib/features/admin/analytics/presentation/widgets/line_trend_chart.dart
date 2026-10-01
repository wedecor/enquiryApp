import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/theme/tokens.dart';
import '../../../../../ui/primitives/primitives.dart';
import '../../domain/analytics_models.dart';
import 'analytics_section_card.dart';

/// Enquiry trend: headline total/peak/average figures over a smoothed
/// [TrendLine] with sparse date ticks.
class LineTrendChart extends StatelessWidget {
  final List<SeriesPoint> data;
  final String title;
  final String? subtitle;

  const LineTrendChart({super.key, required this.data, required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) {
    return AnalyticsSectionCard(
      eyebrow: 'Trend',
      title: title,
      subtitle: subtitle,
      child: data.isEmpty
          ? const AnalyticsEmptyState(
              icon: Icons.show_chart_rounded,
              hint: 'Select a different date range or filters',
            )
          : _buildChart(context),
    );
  }

  Widget _buildChart(BuildContext context) {
    final s = AppSurfaces.of(context);
    final values = [for (final p in data) p.count.toDouble()];
    final total = data.fold<int>(0, (sum, p) => sum + p.count);
    final peak = data.map((p) => p.count).reduce(math.max);
    final average = total / data.length;

    final ticks = <SeriesPoint>[
      data.first,
      if (data.length > 2) data[data.length ~/ 2],
      if (data.length > 1) data.last,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              flex: 3,
              child: _Figure(value: '$total', label: 'enquiries', large: true),
            ),
            Expanded(
              flex: 2,
              child: _Figure(value: '$peak', label: 'peak'),
            ),
            Expanded(
              flex: 2,
              child: _Figure(value: average.toStringAsFixed(1), label: 'average'),
            ),
          ],
        ),
        const SizedBox(height: AppTokens.space5),
        TrendLine(values: values, color: s.accent, height: 200),
        const SizedBox(height: AppTokens.space2),
        Row(
          mainAxisAlignment: ticks.length == 1
              ? MainAxisAlignment.start
              : MainAxisAlignment.spaceBetween,
          children: [for (final p in ticks) _Tick(label: _formatDate(p.x))],
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;

    if (difference == 0) {
      return 'Today';
    } else if (difference == 1) {
      return 'Yesterday';
    } else if (difference < 7) {
      return _getDayName(date.weekday);
    } else {
      return '${date.day}/${date.month}';
    }
  }

  String _getDayName(int weekday) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[weekday - 1];
  }
}

class _Figure extends StatelessWidget {
  const _Figure({required this.value, required this.label, this.large = false});

  final String value;
  final String label;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final style = large
        ? t.displayMedium?.merge(AppTypography.numeral)
        : t.titleLarge?.merge(AppTypography.numeral).copyWith(fontSize: 20);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(value, maxLines: 1, style: style?.copyWith(color: cs.onSurface)),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: t.bodySmall?.copyWith(color: cs.onSurfaceVariant, fontWeight: FontWeight.w300),
        ),
      ],
    );
  }
}

class _Tick extends StatelessWidget {
  const _Tick({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Text(
      label,
      maxLines: 1,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        color: cs.onSurfaceVariant,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.6,
      ),
    );
  }
}
