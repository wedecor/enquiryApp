import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';
import '../primitives/primitives.dart';

/// Glass metric tile: tracked eyebrow label, a heavy Outfit numeral and an
/// optional trend line led by a small glyph. The [icon] sits quietly in the
/// corner in the accent ink instead of a filled box.
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

  /// Optional colour wash over the glass.
  final Color? background;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final s = AppSurfaces.of(context);

    return GlassPanel(
      strong: true,
      borderRadius: AppRadius.large,
      tint: background,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxHeight.isFinite && constraints.maxHeight < 130;
          final pad = compact ? AppTokens.space3 : AppTokens.space4;
          final trendTint = trendColor ?? s.accentInk;

          final numeralStyle = theme.textTheme.displayMedium?.copyWith(
            fontSize: compact ? 26 : 32,
            fontWeight: FontWeight.w800,
            height: 1,
            letterSpacing: -1.1,
            color: colorScheme.onSurface,
            fontFeatures: const [FontFeature.tabularFigures()],
          );

          return Padding(
            padding: EdgeInsets.all(pad),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Expanded(child: Eyebrow(label)),
                    const SizedBox(width: AppTokens.space2),
                    Icon(icon, size: 16, color: s.accentInk),
                  ],
                ),
                SizedBox(height: compact ? AppTokens.space1 : AppTokens.space2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(value, maxLines: 1, style: numeralStyle),
                ),
                if (trendLabel != null) ...[
                  SizedBox(height: compact ? 2 : AppTokens.space1),
                  Row(
                    children: [
                      if (trendIcon != null) ...[
                        Icon(trendIcon, size: 12, color: trendTint),
                        const SizedBox(width: AppTokens.space1),
                      ] else ...[
                        StatusDot(color: trendTint, size: 5),
                        const SizedBox(width: 6),
                      ],
                      Expanded(
                        child: Text(
                          trendLabel!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: trendTint,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.1,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
