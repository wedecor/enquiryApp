import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../ui/primitives/primitives.dart';

/// One tappable dashboard counter. A null [value] renders a placeholder while
/// data is loading.
class DashboardMetric {
  const DashboardMetric({
    required this.bucket,
    required this.label,
    required this.value,
    this.note,
    this.alert = false,
  });

  final String bucket;
  final String label;
  final int? value;
  final String? note;

  /// Flags the metric as needing attention (error-tinted figure + pulse dot).
  final bool alert;

  String get semanticsLabel => '${value ?? '–'} $label${note != null ? '. $note' : ''}';
}

/// Asymmetric metric cluster: one hero tile with a sparkline beside two
/// stacked compact tiles.
class DashboardMetricCluster extends StatelessWidget {
  const DashboardMetricCluster({
    super.key,
    required this.hero,
    required this.heroUnit,
    required this.heroSeries,
    required this.first,
    required this.second,
    this.onTap,
  });

  final DashboardMetric hero;

  /// Whisper-weight word set beside the hero numeral (e.g. "events").
  final String heroUnit;
  final List<double> heroSeries;
  final DashboardMetric first;
  final DashboardMetric second;
  final void Function(String bucket)? onTap;

  @override
  Widget build(BuildContext context) {
    VoidCallback? tapFor(DashboardMetric m) => onTap == null ? null : () => onTap!(m.bucket);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 11,
            child: StaggerIn(
              index: 0,
              child: _HeroTile(
                metric: hero,
                unit: heroUnit,
                series: heroSeries,
                onTap: tapFor(hero),
              ),
            ),
          ),
          const SizedBox(width: AppTokens.space3),
          Expanded(
            flex: 9,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: StaggerIn(
                    index: 1,
                    child: _CompactTile(metric: first, onTap: tapFor(first)),
                  ),
                ),
                const SizedBox(height: AppTokens.space3),
                Expanded(
                  child: StaggerIn(
                    index: 2,
                    child: _CompactTile(metric: second, onTap: tapFor(second)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TileShell extends StatelessWidget {
  const _TileShell({
    required this.metric,
    required this.onTap,
    required this.radius,
    required this.child,
    this.tint,
    this.shadow = false,
  });

  final DashboardMetric metric;
  final VoidCallback? onTap;
  final BorderRadius radius;
  final Widget child;
  final Color? tint;
  final bool shadow;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: onTap != null,
      label: metric.semanticsLabel,
      excludeSemantics: true,
      child: Pressable(
        onTap: onTap,
        borderRadius: radius,
        child: GlassPanel(
          strong: true,
          shadow: shadow,
          tint: tint,
          borderRadius: radius,
          child: child,
        ),
      ),
    );
  }
}

class _HeroTile extends StatelessWidget {
  const _HeroTile({
    required this.metric,
    required this.unit,
    required this.series,
    required this.onTap,
  });

  final DashboardMetric metric;
  final String unit;
  final List<double> series;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final s = AppSurfaces.of(context);

    return _TileShell(
      metric: metric,
      onTap: onTap,
      radius: AppRadius.xLarge,
      tint: s.accent.withValues(alpha: 0.10),
      shadow: true,
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.space4 + 2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Eyebrow(metric.label, accent: true)),
                Icon(Icons.north_east_rounded, size: AppTokens.iconSmall, color: s.accentInk),
              ],
            ),
            const SizedBox(height: AppTokens.space3),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  metric.value?.toString() ?? '–',
                  style: t.displayLarge?.merge(AppTypography.numeral).copyWith(fontSize: 52),
                ),
                const SizedBox(width: AppTokens.space2),
                Flexible(
                  child: Text(
                    unit,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: t.titleMedium?.copyWith(
                      fontWeight: FontWeight.w300,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTokens.space1),
            Text(
              metric.note ?? 'Next 7 days',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: t.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            ),
            const Spacer(),
            const SizedBox(height: AppTokens.space4),
            // Re-keyed so the bars grow again once live data replaces the placeholder.
            SparkBars(
              key: ValueKey(metric.value == null),
              values: series,
              height: 34,
              highlightLast: false,
            ),
          ],
        ),
      ),
    );
  }
}

class _CompactTile extends StatelessWidget {
  const _CompactTile({required this.metric, required this.onTap});

  final DashboardMetric metric;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return _TileShell(
      metric: metric,
      onTap: onTap,
      radius: AppRadius.large,
      tint: metric.alert ? cs.error.withValues(alpha: 0.06) : null,
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.space3 + 2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Expanded(child: Eyebrow(metric.label)),
                if (metric.alert) StatusDot(color: cs.error, size: 7, pulse: true),
              ],
            ),
            const SizedBox(height: AppTokens.space1 + 2),
            Text(
              metric.value?.toString() ?? '–',
              style: t.headlineLarge
                  ?.merge(AppTypography.numeral)
                  .copyWith(fontSize: 30, color: metric.alert ? cs.error : cs.onSurface),
            ),
            if (metric.note != null) ...[
              const SizedBox(height: 2),
              Text(
                metric.note!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: t.labelSmall?.copyWith(
                  color: cs.onSurfaceVariant,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 0.1,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
