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

    final Color cardColor = background ??
        (colorScheme.brightness == Brightness.dark
            ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.32)
            : colorScheme.surfaceContainerHighest.withValues(alpha: 0.18));

    return Card.filled(
      color: cardColor,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final maxHeight = constraints.maxHeight.isFinite
                ? constraints.maxHeight
                : double.infinity;
            final compact = maxHeight < 130;

            final titleStyle = theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            );
            final valueStyle = (compact
                    ? theme.textTheme.headlineSmall
                    : theme.textTheme.headlineMedium)
                ?.copyWith(
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
            );
            final subtitleStyle = theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            );

            final iconBackground = colorScheme.primaryContainer;
            final iconForeground = colorScheme.onPrimaryContainer;

            return SizedBox(
              height: constraints.maxHeight,
              child: Column(
                mainAxisSize: MainAxisSize.max,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: compact ? 32 : 36,
                        height: compact ? 32 : 36,
                        decoration: BoxDecoration(
                          color: iconBackground,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.center,
                        child: Icon(
                          icon,
                          size: compact ? 18 : 20,
                          color: iconForeground,
                        ),
                      ),
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
                  const SizedBox(height: 6),
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          value,
                          maxLines: 1,
                          style: valueStyle,
                        ),
                      ),
                    ),
                  ),
                  if (trendLabel != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        if (trendIcon != null)
                          Icon(
                            trendIcon,
                            size: compact ? 14 : 16,
                            color: trendColor ?? colorScheme.primary,
                          ),
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
                  ] else ...[
                    const SizedBox(height: 2),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
