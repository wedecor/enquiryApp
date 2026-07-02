import 'package:flutter/material.dart';

import '../../core/theme/tokens.dart';

class StatsCard extends StatelessWidget {
  const StatsCard({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    this.trendLabel,
    this.trendIcon,
    this.trendColor,
    this.background,
  });

  final IconData icon;
  final String value;
  final String label;
  final String? trendLabel;
  final IconData? trendIcon;
  final Color? trendColor;
  final Color? background;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final Color cardColor =
        background ??
        (colorScheme.brightness == Brightness.dark
            ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.55)
            : colorScheme.surface.withValues(alpha: 0.9));

    return Card.filled(
      color: cardColor,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.large,
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.7),
        ),
      ),
      clipBehavior: Clip.hardEdge,
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.space3),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final maxHeight = constraints.maxHeight;
            final hasBoundedHeight = maxHeight.isFinite;
            final compact = hasBoundedHeight && maxHeight < 130;
            final showTrend = trendLabel != null;

            final titleStyle = theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurfaceVariant,
            );
            final valueStyle =
                (compact
                        ? theme.textTheme.titleLarge
                        : theme.textTheme.headlineSmall)
                    ?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface,
                    );
            final subtitleStyle = theme.textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            );

            final iconBackground = colorScheme.primaryContainer;
            final iconForeground = colorScheme.onPrimaryContainer;
            const iconSize = 36.0;
            const glyphSize = 18.0;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    _iconBox(
                      iconBackground,
                      iconForeground,
                      iconSize,
                      glyphSize,
                    ),
                    const SizedBox(width: AppTokens.space2),
                    Expanded(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: titleStyle,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTokens.space2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(value, maxLines: 1, style: valueStyle),
                ),
                if (showTrend) ...[
                  const SizedBox(height: AppTokens.space1),
                  Row(
                    children: [
                      if (trendIcon != null)
                        Icon(
                          trendIcon,
                          size: 12,
                          color: trendColor ?? colorScheme.primary,
                        ),
                      if (trendIcon != null)
                        const SizedBox(width: AppTokens.space1),
                      Expanded(
                        child: Text(
                          trendLabel!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: subtitleStyle?.copyWith(
                            color: trendColor ?? colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _iconBox(Color bg, Color fg, double size, double glyph) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: bg, borderRadius: AppRadius.medium),
      alignment: Alignment.center,
      child: Icon(icon, size: glyph, color: fg),
    );
  }
}
