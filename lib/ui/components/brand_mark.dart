import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/tokens.dart';

/// The real WD monogram (gold on dark surfaces, charcoal on light, per the brand
/// kit) plus the optional "WE DECOR" wordmark set in Marcellus.
class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.compact = false, this.showSubtitle = false, this.size = 22});

  final bool compact;
  final bool showSubtitle;

  /// Height of the monogram.
  final double size;

  static const String goldAsset = 'assets/brand/wd_mark_gold.png';
  static const String inkAsset = 'assets/brand/wd_mark_ink.png';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              theme.brightness == Brightness.dark ? goldAsset : inkAsset,
              height: size,
              filterQuality: FilterQuality.high,
              semanticLabel: compact ? 'We Decor' : null,
              excludeFromSemantics: !compact,
            ),
            if (!compact) ...[
              const SizedBox(width: AppTokens.space2 + 2),
              Text(
                'WE DECOR',
                style: GoogleFonts.marcellus(
                  textStyle: theme.textTheme.titleMedium,
                  color: theme.colorScheme.onSurface,
                  letterSpacing: 3,
                ),
              ),
            ],
          ],
        ),
        if (showSubtitle) ...[
          const SizedBox(height: AppTokens.space1),
          Text(
            'ENQUIRIES',
            style: theme.textTheme.labelSmall
                ?.merge(AppTypography.eyebrow)
                .copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ],
    );
  }
}
