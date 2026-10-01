import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/theme/tokens.dart';
import '../../../../../ui/primitives/primitives.dart';
import '../../domain/analytics_models.dart';
import '../analytics_controller.dart';
import 'analytics_filter_dropdowns.dart';

/// Collapsible glass filter panel: a summary row that expands into date-range
/// pills and the four dropdown filters.
class AnalyticsFiltersPanel extends ConsumerStatefulWidget {
  const AnalyticsFiltersPanel({super.key, required this.onCustomDateRange});

  final Future<void> Function(DateRange currentRange) onCustomDateRange;

  @override
  ConsumerState<AnalyticsFiltersPanel> createState() => _AnalyticsFiltersPanelState();
}

class _AnalyticsFiltersPanelState extends ConsumerState<AnalyticsFiltersPanel> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final s = AppSurfaces.of(context);
    final filters = ref.watch(analyticsControllerProvider).value?.filters;

    final activeCount = filters == null
        ? 0
        : [
            filters.eventType,
            filters.status,
            filters.priority,
            filters.source,
          ].where((f) => f != null).length;
    final summary = [
      if (filters != null) filters.preset.label,
      if (activeCount > 0) '$activeCount active',
    ].join(' · ');

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTokens.space4,
        AppTokens.space1,
        AppTokens.space4,
        AppTokens.space2,
      ),
      child: GlassPanel(
        borderRadius: AppRadius.xLarge,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Pressable(
              onTap: () => setState(() => _expanded = !_expanded),
              borderRadius: AppRadius.xLarge,
              pressedScale: 0.98,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: AppTokens.minTapTarget + 12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTokens.space4,
                    vertical: AppTokens.space2,
                  ),
                  child: Row(
                    children: [
                      DecoratedBox(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: s.accent.withValues(alpha: 0.14),
                        ),
                        child: SizedBox.square(
                          dimension: 36,
                          child: Icon(
                            Icons.tune_rounded,
                            size: AppTokens.iconSmall,
                            color: s.accentInk,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppTokens.space3),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Filters',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            if (summary.isNotEmpty)
                              Text(
                                summary,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: cs.onSurfaceVariant,
                                  fontWeight: FontWeight.w300,
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (activeCount > 0) ...[
                        StatusDot(color: s.accent, size: 7),
                        const SizedBox(width: AppTokens.space3),
                      ],
                      AnimatedRotation(
                        turns: _expanded ? 0.5 : 0,
                        duration: AppMotion.of(context, AppMotion.standard),
                        curve: AppMotion.standardCurve,
                        child: Icon(Icons.expand_more_rounded, color: cs.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            _ExpandReveal(
              child: _expanded
                  ? Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppTokens.space4,
                        AppTokens.space1,
                        AppTokens.space4,
                        AppTokens.space4,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Eyebrow('Date range'),
                          const SizedBox(height: AppTokens.space2),
                          _DateRangePills(onCustomDateRange: widget.onCustomDateRange),
                          const SizedBox(height: AppTokens.space4),
                          const Eyebrow('Refine'),
                          const SizedBox(height: AppTokens.space3),
                          const _DropdownGrid(),
                        ],
                      ),
                    )
                  : const SizedBox(width: double.infinity),
            ),
          ],
        ),
      ),
    );
  }
}

/// Animates height changes of [child]; switches instantly under reduced motion
/// (a zero-duration [AnimatedSize] asserts during layout).
class _ExpandReveal extends StatelessWidget {
  const _ExpandReveal({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (AppMotion.reduced(context)) return child;
    return AnimatedSize(
      duration: AppMotion.gentle,
      curve: AppMotion.standardCurve,
      alignment: Alignment.topCenter,
      child: child,
    );
  }
}

class _DropdownGrid extends StatelessWidget {
  const _DropdownGrid();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = SizedBox(width: AppTokens.space3);
        if (constraints.maxWidth < AppTokens.breakpointTablet) {
          return const Column(
            children: [
              Row(
                children: [
                  Expanded(child: AnalyticsEventTypeFilter()),
                  gap,
                  Expanded(child: AnalyticsStatusFilter()),
                ],
              ),
              SizedBox(height: AppTokens.space3),
              Row(
                children: [
                  Expanded(child: AnalyticsPriorityFilter()),
                  gap,
                  Expanded(child: AnalyticsSourceFilter()),
                ],
              ),
            ],
          );
        }
        return const Row(
          children: [
            Expanded(child: AnalyticsEventTypeFilter()),
            gap,
            Expanded(child: AnalyticsStatusFilter()),
            gap,
            Expanded(child: AnalyticsPriorityFilter()),
            gap,
            Expanded(child: AnalyticsSourceFilter()),
          ],
        );
      },
    );
  }
}

class _DateRangePills extends ConsumerWidget {
  const _DateRangePills({required this.onCustomDateRange});

  final Future<void> Function(DateRange currentRange) onCustomDateRange;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analyticsAsync = ref.watch(analyticsControllerProvider);

    return analyticsAsync.when(
      data: (state) {
        final selected = state.filters.preset;
        return Wrap(
          spacing: AppTokens.space2,
          children: [
            for (final preset in DateRangePreset.values)
              _DatePill(
                label: preset.label,
                selected: selected == preset,
                onTap: () async {
                  if (preset == DateRangePreset.custom) {
                    await onCustomDateRange(state.filters.dateRange);
                  } else {
                    ref.read(analyticsControllerProvider.notifier).updateDateRangePreset(preset);
                  }
                },
              ),
          ],
        );
      },
      loading: () => const SizedBox(
        height: 36,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      error: (error, stack) => Text('Error: $error'),
    );
  }
}

class _DatePill extends StatelessWidget {
  const _DatePill({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = AppSurfaces.of(context);
    final cs = Theme.of(context).colorScheme;
    final duration = AppMotion.of(context, AppMotion.standard);
    final labelStyle = Theme.of(context).textTheme.labelLarge;

    return Semantics(
      selected: selected,
      button: true,
      child: Pressable(
        onTap: onTap,
        borderRadius: AppRadius.full,
        pressedScale: 0.94,
        splash: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppTokens.space1),
          child: AnimatedContainer(
            duration: duration,
            curve: AppMotion.standardCurve,
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: AppTokens.space4),
            decoration: BoxDecoration(
              gradient: selected ? s.inkGradient : null,
              color: selected ? null : s.glassFillStrong,
              borderRadius: AppRadius.full,
              border: Border.all(color: selected ? Colors.transparent : s.microBorderStrong),
              boxShadow: selected ? AppShadows.glow(s.shadow, strength: 0.12) : const [],
            ),
            alignment: Alignment.center,
            child: AnimatedDefaultTextStyle(
              duration: duration,
              style: (labelStyle ?? const TextStyle()).copyWith(
                color: selected ? cs.onPrimary : cs.onSurfaceVariant,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
              ),
              child: Text(label, maxLines: 1),
            ),
          ),
        ),
      ),
    );
  }
}
