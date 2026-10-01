import 'package:flutter/material.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/theme/tokens.dart';
import '../../../../../ui/primitives/primitives.dart';
import '../../domain/analytics_models.dart';
import 'analytics_format.dart';
import 'analytics_section_card.dart';
import 'breakdown_geometry.dart';

Color _paletteColor(int index) =>
    AppColorScheme.chartPalette[index % AppColorScheme.chartPalette.length];

int _sum(Iterable<CategoryCount> items) => items.fold<int>(0, (a, e) => a + e.count);

/// Event type mix as a segmented arc ring with the total at its centre.
class EventTypePieChart extends StatelessWidget {
  final List<CategoryCount> data;
  final String title;

  const EventTypePieChart({super.key, required this.data, required this.title});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return AnalyticsSectionCard(
        eyebrow: 'Mix',
        title: title,
        child: const AnalyticsEmptyState(icon: Icons.donut_large_rounded),
      );
    }

    final items = data.take(8).toList();
    final t = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    final ring = SegmentedRing(
      segments: [
        for (var i = 0; i < items.length; i++) (items[i].count.toDouble(), _paletteColor(i)),
      ],
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.space6),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${_sum(data)}',
                style: t.displayMedium?.merge(AppTypography.numeral).copyWith(color: cs.onSurface),
              ),
              const SizedBox(height: 2),
              const Eyebrow('events'),
            ],
          ),
        ),
      ),
    );

    final legend = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < items.length; i++)
          BreakdownLegendRow(
            color: _paletteColor(i),
            label: categoryLabel(items[i]),
            count: items[i].count,
            percentage: items[i].percentage,
          ),
      ],
    );

    return AnalyticsSectionCard(
      eyebrow: 'Mix',
      title: title,
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < AppTokens.breakpointMobile - 40) {
            return Column(
              children: [
                ring,
                const SizedBox(height: AppTokens.space5),
                legend,
              ],
            );
          }
          return Row(
            children: [
              ring,
              const SizedBox(width: AppTokens.space6),
              Expanded(child: legend),
            ],
          );
        },
      ),
    );
  }
}

/// Source mix as a 100-dot matrix: each dot is one percent of enquiries.
class SourceBarChart extends StatelessWidget {
  final List<CategoryCount> data;
  final String title;

  const SourceBarChart({super.key, required this.data, required this.title});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return AnalyticsSectionCard(
        eyebrow: 'Channels',
        title: title,
        child: const AnalyticsEmptyState(icon: Icons.grain_rounded),
      );
    }

    final items = data.take(10).toList();
    return AnalyticsSectionCard(
      eyebrow: 'Channels',
      title: title,
      subtitle: 'Each dot is roughly 1% of enquiries',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DotMatrix(
            segments: [
              for (var i = 0; i < items.length; i++) (items[i].count.toDouble(), _paletteColor(i)),
            ],
          ),
          const SizedBox(height: AppTokens.space4),
          for (var i = 0; i < items.length; i++)
            BreakdownLegendRow(
              color: _paletteColor(i),
              label: categoryLabel(items[i]),
              count: items[i].count,
              percentage: items[i].percentage,
            ),
        ],
      ),
    );
  }
}

/// Status pipeline as one proportional strip with a status-coloured legend.
class StatusStackedBarChart extends StatelessWidget {
  final List<CategoryCount> data;
  final String title;

  const StatusStackedBarChart({super.key, required this.data, required this.title});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return AnalyticsSectionCard(
        eyebrow: 'Pipeline',
        title: title,
        child: const AnalyticsEmptyState(icon: Icons.stacked_bar_chart_rounded),
      );
    }

    final t = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return AnalyticsSectionCard(
      eyebrow: 'Pipeline',
      title: title,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '${_sum(data)}',
                style: t.displayMedium?.merge(AppTypography.numeral).copyWith(color: cs.onSurface),
              ),
              const SizedBox(width: AppTokens.space2),
              Flexible(
                child: Text(
                  'enquiries by status',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: t.bodyMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w300,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTokens.space4),
          ProportionStrip(
            height: 14,
            segments: [
              for (final item in data)
                (item.count.toDouble(), AppColorScheme.statusColorFor(item.key)),
            ],
          ),
          const SizedBox(height: AppTokens.space4),
          for (final item in data)
            BreakdownLegendRow(
              color: AppColorScheme.statusColorFor(item.key),
              label: statusCategoryLabel(item),
              count: item.count,
              percentage: item.percentage,
            ),
        ],
      ),
    );
  }
}
