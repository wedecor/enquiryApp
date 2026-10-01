import 'package:flutter/material.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/theme/tokens.dart';
import '../../../../../ui/primitives/primitives.dart';

/// Glass KPI tile: tracked eyebrow, Outfit numeral, delta accent and optional
/// geometry. [hero] renders the large lead tile with [trend] spark bars;
/// [gauge] (0..1) adds a ring; [share] (0..1) adds a slim proportion rule.
///
/// Expects a bounded height (the grid sizes rows with [IntrinsicHeight]).
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
    this.hero = false,
    this.trend,
    this.gauge,
    this.share,
  });

  final String title;
  final String value;
  final double? deltaPercentage;
  final IconData icon;
  final Color? color;
  final String? subtitle;
  final bool isLoading;
  final bool hero;
  final List<double>? trend;
  final double? gauge;
  final double? share;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final s = AppSurfaces.of(context);
    final accent = color ?? s.accent;

    final numeralStyle = hero
        ? theme.textTheme.displayLarge?.merge(AppTypography.numeral).copyWith(fontSize: 54)
        : theme.textTheme.headlineMedium?.merge(AppTypography.numeral).copyWith(fontSize: 28);

    final header = Row(
      children: [
        if (hero)
          DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accent.withValues(alpha: 0.14),
              border: Border.all(color: accent.withValues(alpha: 0.24)),
            ),
            child: SizedBox.square(
              dimension: 32,
              child: Icon(icon, size: AppTokens.iconSmall, color: accent),
            ),
          )
        else
          StatusDot(color: accent, size: 7),
        SizedBox(width: hero ? AppTokens.space3 : AppTokens.space2),
        Expanded(
          child: hero
              ? Eyebrow(title, accent: true)
              : Text(
                  title.toUpperCase(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall
                      ?.merge(AppTypography.eyebrow)
                      .copyWith(color: cs.onSurfaceVariant, letterSpacing: 1.2),
                ),
        ),
      ],
    );

    final numeral = isLoading
        ? _LoadingBar(height: hero ? 48 : 28)
        : FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value, maxLines: 1, style: numeralStyle?.copyWith(color: cs.onSurface)),
          );

    final delta = deltaPercentage != null && !isLoading
        ? _DeltaAccent(delta: deltaPercentage!, showCaption: hero)
        : null;

    final children = <Widget>[
      header,
      SizedBox(height: hero ? AppTokens.space5 : AppTokens.space3),
      const Spacer(),
      if (gauge != null && !isLoading)
        Center(
          child: RingGauge(
            value: gauge!,
            color: accent,
            size: 112,
            thickness: 9,
            child: Padding(
              padding: const EdgeInsets.all(AppTokens.space4),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(value, maxLines: 1, style: numeralStyle?.copyWith(color: cs.onSurface)),
              ),
            ),
          ),
        )
      else
        numeral,
      if (gauge != null && !isLoading) const Spacer(),
      if (delta != null) ...[const SizedBox(height: AppTokens.space2), delta],
      if (subtitle != null && !isLoading) ...[
        const SizedBox(height: AppTokens.space2),
        Text(
          subtitle!,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.labelSmall?.copyWith(
            color: cs.onSurfaceVariant,
            fontWeight: FontWeight.w300,
            letterSpacing: 0.1,
          ),
        ),
      ],
      if (share != null && !isLoading) ...[
        const SizedBox(height: AppTokens.space3),
        _ShareRule(value: share!, color: accent),
      ],
      if (hero && trend != null && trend!.isNotEmpty && !isLoading) ...[
        const SizedBox(height: AppTokens.space5),
        SparkBars(values: trend!, color: accent, height: 44),
      ],
    ];

    return GlassPanel(
      strong: hero,
      shadow: hero,
      tint: accent.withValues(alpha: hero ? 0.10 : 0.05),
      borderRadius: hero ? AppRadius.xxLarge : AppRadius.xLarge,
      padding: EdgeInsets.all(hero ? AppTokens.space5 : AppTokens.space4),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
    );
  }
}

class _DeltaAccent extends StatelessWidget {
  const _DeltaAccent({required this.delta, required this.showCaption});

  final double delta;
  final bool showCaption;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isNeutral = delta == 0;
    final isPositive = delta >= 0;

    final Color tone;
    final IconData glyph;
    if (isNeutral) {
      tone = cs.onSurfaceVariant;
      glyph = Icons.remove_rounded;
    } else if (isPositive) {
      tone = AppColorScheme.chartGreen;
      glyph = Icons.north_east_rounded;
    } else {
      tone = AppColorScheme.chartRed;
      glyph = Icons.south_east_rounded;
    }

    final formatted = isNeutral ? '0' : '${isPositive ? '+' : ''}${delta.toStringAsFixed(1)}%';

    final pill = DecoratedBox(
      decoration: BoxDecoration(color: tone.withValues(alpha: 0.12), borderRadius: AppRadius.full),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppTokens.space2, vertical: 3),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(glyph, color: tone, size: 12),
            const SizedBox(width: 3),
            Text(
              formatted,
              maxLines: 1,
              style: theme.textTheme.labelSmall?.copyWith(
                color: tone,
                fontWeight: FontWeight.w800,
                letterSpacing: 0,
              ),
            ),
          ],
        ),
      ),
    );

    return Row(
      children: [
        Flexible(
          child: FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: pill),
        ),
        if (showCaption) ...[
          const SizedBox(width: AppTokens.space2),
          Flexible(
            child: Text(
              'vs previous period',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(
                color: cs.onSurfaceVariant,
                fontWeight: FontWeight.w300,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _ShareRule extends StatelessWidget {
  const _ShareRule({required this.value, required this.color});

  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final s = AppSurfaces.of(context);
    final v = value.clamp(0.0, 1.0);
    return ProportionStrip(height: 4, segments: [(v, color), (1 - v, s.microBorderStrong)]);
  }
}

class _LoadingBar extends StatelessWidget {
  const _LoadingBar({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    final s = AppSurfaces.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(color: s.microBorder, borderRadius: AppRadius.small),
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: const Center(
          child: SizedBox.square(dimension: 16, child: CircularProgressIndicator(strokeWidth: 2)),
        ),
      ),
    );
  }
}
