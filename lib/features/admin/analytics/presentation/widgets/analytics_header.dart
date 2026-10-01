import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/theme/tokens.dart';
import '../../../../../ui/primitives/primitives.dart';
import '../analytics_controller.dart';
import 'analytics_format.dart';

/// Editorial intro for the analytics body: date-range eyebrow, split heading
/// and round glass Export / Refresh actions. [onBack] adds a back button and
/// the page title for the standalone (non-shell) route.
class AnalyticsHeader extends ConsumerWidget {
  const AnalyticsHeader({super.key, required this.onExport, required this.onRefresh, this.onBack});

  final VoidCallback onExport;
  final VoidCallback onRefresh;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final s = AppSurfaces.of(context);
    final analyticsAsync = ref.watch(analyticsControllerProvider);

    final dateRangeLabel = analyticsAsync.maybeWhen(
      data: (state) => formatAnalyticsDateRange(state.filters.dateRange),
      orElse: () => 'Loading date range…',
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTokens.space5,
        AppTokens.space5,
        AppTokens.space4,
        AppTokens.space3,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final narrow = constraints.maxWidth < 400;

          final titleBlock = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  StatusDot(color: s.accent, size: 6),
                  const SizedBox(width: AppTokens.space2),
                  Flexible(child: Eyebrow(dateRangeLabel, accent: true)),
                ],
              ),
              const SizedBox(height: AppTokens.space2),
              SplitHeading(
                light: 'Business',
                bold: 'insights',
                style: theme.textTheme.displaySmall,
                maxLines: 1,
              ),
            ],
          );

          final actions = Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (narrow)
                _RoundAction(icon: Icons.download_rounded, tooltip: 'Export', onTap: onExport)
              else
                _ExportPill(onTap: onExport),
              const SizedBox(width: AppTokens.space2),
              _RoundAction(icon: Icons.refresh_rounded, tooltip: 'Refresh', onTap: onRefresh),
            ],
          );

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (onBack != null) ...[
                Row(
                  children: [
                    _RoundAction(icon: Icons.arrow_back_rounded, tooltip: 'Back', onTap: onBack!),
                    const SizedBox(width: AppTokens.space3),
                    Expanded(
                      child: Text(
                        'Analytics',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTokens.space5),
              ],
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(child: titleBlock),
                  const SizedBox(width: AppTokens.space3),
                  actions,
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ExportPill extends StatelessWidget {
  const _ExportPill({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = AppSurfaces.of(context);
    final cs = Theme.of(context).colorScheme;

    return Tooltip(
      message: 'Export',
      child: Pressable(
        onTap: onTap,
        borderRadius: AppRadius.full,
        pressedScale: 0.94,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: s.glassFillStrong,
            borderRadius: AppRadius.full,
            border: Border.all(color: s.microBorder),
          ),
          child: SizedBox(
            height: AppTokens.minTapTarget,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppTokens.space4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.download_rounded, size: AppTokens.iconSmall, color: cs.onSurface),
                  const SizedBox(width: AppTokens.space2),
                  Text(
                    'Export',
                    style: Theme.of(
                      context,
                    ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RoundAction extends StatelessWidget {
  const _RoundAction({required this.icon, required this.tooltip, required this.onTap});

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = AppSurfaces.of(context);
    final cs = Theme.of(context).colorScheme;

    return Tooltip(
      message: tooltip,
      child: Pressable(
        onTap: onTap,
        pressedScale: 0.9,
        borderRadius: AppRadius.full,
        semanticLabel: tooltip,
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: s.glassFillStrong,
            border: Border.all(color: s.microBorder),
          ),
          child: SizedBox.square(
            dimension: AppTokens.minTapTarget,
            child: Icon(icon, size: AppTokens.iconMedium, color: cs.onSurface),
          ),
        ),
      ),
    );
  }
}
