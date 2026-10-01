import 'package:flutter/material.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/theme/tokens.dart';
import '../../../../../services/dropdown_lookup.dart';
import '../../../../../ui/primitives/primitives.dart';
import '../../domain/analytics_models.dart';
import 'analytics_section_card.dart';

/// Ranked list: heavy rank numerals, count + share, and a thin proportional
/// bar under each row in place of table grid lines.
class TopListTable extends StatelessWidget {
  final String title;
  final List<CategoryCount> data;
  final int maxItems;
  final bool showPercentage;

  const TopListTable({
    super.key,
    required this.title,
    required this.data,
    this.maxItems = 10,
    this.showPercentage = true,
  });

  @override
  Widget build(BuildContext context) {
    return AnalyticsSectionCard(
      eyebrow: 'Ranking',
      title: title,
      child: data.isEmpty
          ? const AnalyticsEmptyState(icon: Icons.format_list_numbered_rounded)
          : _buildList(context),
    );
  }

  Widget _buildList(BuildContext context) {
    final displayData = data.take(maxItems).toList();
    final maxCount = displayData.fold<int>(0, (m, e) => e.count > m ? e.count : m);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: AppTokens.space2),
          child: Row(
            children: [
              const SizedBox(width: 40),
              const Expanded(child: Eyebrow('Name')),
              const SizedBox(width: 56, child: Eyebrow('Count')),
              if (showPercentage)
                const SizedBox(
                  width: 56,
                  child: Align(alignment: Alignment.centerRight, child: Eyebrow('Share')),
                ),
            ],
          ),
        ),
        for (var i = 0; i < displayData.length; i++)
          StaggerIn(
            index: i,
            child: _RankedRow(
              rank: i + 1,
              label: displayData[i].label ?? _formatName(displayData[i].key),
              count: displayData[i].count,
              percentage: showPercentage ? displayData[i].percentage : null,
              fraction: maxCount > 0 ? displayData[i].count / maxCount : 0,
            ),
          ),
      ],
    );
  }

  String _formatName(String value) => DropdownLookup.titleCase(value);
}

class _RankedRow extends StatelessWidget {
  const _RankedRow({
    required this.rank,
    required this.label,
    required this.count,
    required this.percentage,
    required this.fraction,
  });

  final int rank;
  final String label;
  final int count;
  final double? percentage;
  final double fraction;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final s = AppSurfaces.of(context);
    final lead = rank == 1;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTokens.space2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              SizedBox(
                width: 40,
                child: Text(
                  rank.toString().padLeft(2, '0'),
                  style: t.titleLarge
                      ?.merge(AppTypography.numeral)
                      .copyWith(
                        fontSize: 20,
                        color: lead ? s.accentInk : cs.onSurfaceVariant.withValues(alpha: 0.6),
                      ),
                ),
              ),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: t.bodyMedium?.copyWith(
                    fontWeight: lead ? FontWeight.w700 : FontWeight.w500,
                    color: cs.onSurface,
                  ),
                ),
              ),
              SizedBox(
                width: 56,
                child: Text(
                  '$count',
                  maxLines: 1,
                  style: t.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
              if (percentage != null)
                SizedBox(
                  width: 56,
                  child: Text(
                    '${percentage!.toStringAsFixed(1)}%',
                    textAlign: TextAlign.right,
                    maxLines: 1,
                    style: t.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                      fontWeight: FontWeight.w300,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppTokens.space2),
          Padding(
            padding: const EdgeInsets.only(left: 40),
            child: ProportionStrip(
              height: 3,
              segments: [
                (fraction, lead ? s.accent : s.accent.withValues(alpha: 0.55)),
                (1 - fraction, s.microBorder),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
