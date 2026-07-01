import 'package:flutter/material.dart';

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
            ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.32)
            : colorScheme.surfaceContainerHighest.withValues(alpha: 0.18));

    return Card.filled(
      color: cardColor,
      clipBehavior: Clip.hardEdge,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final maxHeight = constraints.maxHeight;
            final maxWidth = constraints.maxWidth;
            final hasBoundedHeight = maxHeight.isFinite;
            final hasBoundedWidth = maxWidth.isFinite;

            // Horizontal KPI strip: narrow + short cells.
            final stripMode = hasBoundedWidth && maxWidth <= 180;
            final compact = hasBoundedHeight && maxHeight < 130;
            final ultraCompact = hasBoundedHeight && maxHeight < 80;
            final showTrend =
                trendLabel != null && !ultraCompact && !(stripMode && maxHeight < 110);

            final titleStyle = theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            );
            final valueStyle =
                (compact ? theme.textTheme.titleLarge : theme.textTheme.headlineSmall)?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                );
            final subtitleStyle = theme.textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontSize: 10,
            );

            final iconBackground = colorScheme.primaryContainer;
            final iconForeground = colorScheme.onPrimaryContainer;
            final iconSize = ultraCompact ? 28.0 : (compact ? 30.0 : 34.0);
            final glyphSize = ultraCompact ? 16.0 : (compact ? 17.0 : 19.0);

            if (ultraCompact) {
              return Row(
                children: [
                  _iconBox(iconBackground, iconForeground, iconSize, glyphSize),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(value, maxLines: 1, style: valueStyle),
                        ),
                        Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: titleStyle,
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _iconBox(iconBackground, iconForeground, iconSize, glyphSize),
                    const SizedBox(width: 8),
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
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(value, maxLines: 1, style: valueStyle),
                ),
                if (showTrend) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (trendIcon != null)
                        Icon(trendIcon, size: 12, color: trendColor ?? colorScheme.primary),
                      if (trendIcon != null) const SizedBox(width: 4),
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
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
      alignment: Alignment.center,
      child: Icon(icon, size: glyph, color: fg),
    );
  }
}
