import 'package:flutter/material.dart';

import '../../../../core/theme/tokens.dart';
import '../../../../ui/primitives/primitives.dart';

/// Frosted glass panel for a labelled section on the enquiry details screen:
/// optional eyebrow, heavy title, optional trailing widget, then content.
class EnquiryDetailSection extends StatelessWidget {
  const EnquiryDetailSection({
    super.key,
    required this.title,
    required this.children,
    this.eyebrow,
    this.trailing,
  });

  final String title;
  final List<Widget> children;
  final String? eyebrow;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: AppSpacing.bottom(AppTokens.space3),
      child: GlassPanel(
        borderRadius: AppRadius.xLarge,
        padding: const EdgeInsets.fromLTRB(
          AppTokens.space5,
          AppTokens.space5,
          AppTokens.space5,
          AppTokens.space4,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (eyebrow != null) ...[
                        Eyebrow(eyebrow!),
                        const SizedBox(height: AppTokens.space1),
                      ],
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: t.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                ),
                if (trailing != null) ...[const SizedBox(width: AppTokens.space3), trailing!],
              ],
            ),
            const SizedBox(height: AppTokens.space4),
            ...children,
          ],
        ),
      ),
    );
  }
}
