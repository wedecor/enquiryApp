import 'package:flutter/material.dart';

import '../../core/theme/tokens.dart';

/// Terracotta dot + optional “We Decor” wordmark.
class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.compact = false, this.showSubtitle = false});

  final bool compact;
  final bool showSubtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                shape: BoxShape.circle,
              ),
            ),
            if (!compact) ...[
              const SizedBox(width: AppTokens.space2),
              Text(
                'We Decor',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ],
        ),
        if (showSubtitle) ...[
          const SizedBox(height: AppTokens.space1),
          Text(
            'Enquiries',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ],
    );
  }
}
