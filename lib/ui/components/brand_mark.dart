import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';

/// Gold accent mark + optional “WE DECOR” wordmark set in Marcellus, matching
/// the brand toolkit (wordmark is set as type, never baked into an image).
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
              decoration: const BoxDecoration(
                color: AppColorScheme.accent,
                shape: BoxShape.circle,
              ),
            ),
            if (!compact) ...[
              const SizedBox(width: AppTokens.space2),
              Text(
                'WE DECOR',
                style: GoogleFonts.marcellus(
                  textStyle: theme.textTheme.titleMedium,
                  color: theme.colorScheme.onSurface,
                  letterSpacing: 2,
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
