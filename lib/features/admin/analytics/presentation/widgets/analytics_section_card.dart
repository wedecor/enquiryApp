import 'package:flutter/material.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/theme/tokens.dart';
import '../../../../../ui/primitives/primitives.dart';

/// Frosted glass section for analytics charts and lists: eyebrow, heavy title,
/// whisper subtitle, then content separated by space instead of dividers.
class AnalyticsSectionCard extends StatelessWidget {
  const AnalyticsSectionCard({
    super.key,
    required this.child,
    this.title,
    this.subtitle,
    this.eyebrow,
    this.trailing,
    this.padding,
  });

  final Widget child;
  final String? title;
  final String? subtitle;
  final String? eyebrow;
  final Widget? trailing;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return GlassPanel(
      strong: true,
      shadow: true,
      borderRadius: AppRadius.xLarge,
      padding: padding ?? const EdgeInsets.all(AppTokens.space5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (title != null) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (eyebrow != null) ...[
                        Eyebrow(eyebrow!, accent: true),
                        const SizedBox(height: AppTokens.space1),
                      ],
                      Text(
                        title!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant,
                            fontWeight: FontWeight.w300,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (trailing != null) ...[const SizedBox(width: AppTokens.space3), trailing!],
              ],
            ),
            const SizedBox(height: AppTokens.space5),
          ],
          child,
        ],
      ),
    );
  }
}

/// Quiet empty state used inside analytics sections.
class AnalyticsEmptyState extends StatelessWidget {
  const AnalyticsEmptyState({
    super.key,
    required this.icon,
    this.message = 'No data available',
    this.hint,
  });

  final IconData icon;
  final String message;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final s = AppSurfaces.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTokens.space8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: s.glassFill,
              border: Border.all(color: s.microBorderStrong),
            ),
            child: SizedBox.square(
              dimension: 56,
              child: Icon(icon, size: AppTokens.iconLarge, color: cs.onSurfaceVariant),
            ),
          ),
          const SizedBox(height: AppTokens.space4),
          Text(
            message,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: cs.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (hint != null) ...[
            const SizedBox(height: AppTokens.space1),
            Text(
              hint!,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: cs.onSurfaceVariant,
                fontWeight: FontWeight.w300,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
