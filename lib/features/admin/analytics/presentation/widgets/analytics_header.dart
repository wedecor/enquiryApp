import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../../core/theme/tokens.dart';
import '../../domain/analytics_models.dart';
import '../analytics_controller.dart';

/// Warm gradient hero header with title, date range subtitle, and actions.
class AnalyticsHeader extends ConsumerWidget {
  const AnalyticsHeader({
    super.key,
    required this.onExport,
    required this.onRefresh,
  });

  final VoidCallback onExport;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final analyticsAsync = ref.watch(analyticsControllerProvider);

    final dateRangeLabel = analyticsAsync.maybeWhen(
      data: (state) => _formatDateRange(state.filters.dateRange),
      orElse: () => 'Loading date range…',
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: theme.brightness == Brightness.dark
              ? [cs.surfaceContainerHighest.withValues(alpha: 0.45), cs.surface]
              : [cs.primaryContainer.withValues(alpha: 0.65), cs.surface],
          stops: const [0.0, 0.85],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppTokens.space4,
          AppTokens.space4,
          AppTokens.space4,
          AppTokens.space3,
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final narrow = constraints.maxWidth < 400;

            final titleBlock = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Analytics',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppTokens.space1),
                Text(
                  'Business insights',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: AppTokens.space2),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      size: AppTokens.iconSmall,
                      color: cs.primary,
                    ),
                    const SizedBox(width: AppTokens.space2),
                    Expanded(
                      child: Text(
                        dateRangeLabel,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            );

            final actions = Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (narrow)
                  IconButton.outlined(
                    onPressed: onExport,
                    tooltip: 'Export',
                    icon: const Icon(
                      Icons.download_outlined,
                      size: AppTokens.iconMedium,
                    ),
                  )
                else
                  OutlinedButton.icon(
                    onPressed: onExport,
                    style: OutlinedButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTokens.space3,
                        vertical: AppTokens.space2,
                      ),
                    ),
                    icon: const Icon(
                      Icons.download_outlined,
                      size: AppTokens.iconSmall,
                    ),
                    label: const Text('Export'),
                  ),
                const SizedBox(width: AppTokens.space2),
                IconButton.filledTonal(
                  onPressed: onRefresh,
                  tooltip: 'Refresh',
                  icon: const Icon(
                    Icons.refresh_rounded,
                    size: AppTokens.iconMedium,
                  ),
                ),
              ],
            );

            if (narrow) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  titleBlock,
                  const SizedBox(height: AppTokens.space3),
                  Align(alignment: Alignment.centerRight, child: actions),
                ],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: titleBlock),
                const SizedBox(width: AppTokens.space2),
                actions,
              ],
            );
          },
        ),
      ),
    );
  }

  String _formatDateRange(DateRange range) {
    final fmt = DateFormat('d MMM yyyy');
    return '${fmt.format(range.start)} – ${fmt.format(range.end)}';
  }
}
