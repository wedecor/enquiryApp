import 'package:flutter/material.dart';

import '../../../../../core/theme/tokens.dart';

/// Consistent surface card for analytics charts and tables.
class AnalyticsSectionCard extends StatelessWidget {
  const AnalyticsSectionCard({
    super.key,
    required this.child,
    this.title,
    this.subtitle,
    this.padding,
  });

  final Widget child;
  final String? title;
  final String? subtitle;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Card.filled(
      color: cs.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.large,
        side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.7)),
      ),
      clipBehavior: Clip.hardEdge,
      child: Padding(
        padding: padding ?? const EdgeInsets.all(AppTokens.space4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title != null) ...[
              Text(
                title!,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: AppTokens.space1),
                Text(
                  subtitle!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
              const SizedBox(height: AppTokens.space4),
            ],
            child,
          ],
        ),
      ),
    );
  }
}
