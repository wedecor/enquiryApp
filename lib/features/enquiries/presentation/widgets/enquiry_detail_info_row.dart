import 'package:flutter/material.dart';

import '../../../../core/theme/tokens.dart';
import '../../../../ui/primitives/primitives.dart';

/// Tracked eyebrow label stacked over its value — no table columns.
class EnquiryDetailInfoRow extends StatelessWidget {
  const EnquiryDetailInfoRow({
    super.key,
    required this.label,
    required this.value,
    this.maxLines = 3,
    this.leading,
  });

  final String label;
  final dynamic value;

  /// Null lets long values (notes) wrap freely.
  final int? maxLines;

  /// Optional small visual (e.g. a status dot) before the value.
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final text = Text(
      value?.toString() ?? 'N/A',
      maxLines: maxLines,
      overflow: maxLines == null ? null : TextOverflow.ellipsis,
      style: theme.textTheme.bodyLarge?.copyWith(
        fontWeight: FontWeight.w500,
        color: theme.colorScheme.onSurface,
      ),
    );
    return Padding(
      padding: AppSpacing.bottom(AppTokens.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Eyebrow(label),
          const SizedBox(height: AppTokens.space1),
          if (leading == null)
            text
          else
            Row(
              children: [
                leading!,
                const SizedBox(width: AppTokens.space2),
                Flexible(child: text),
              ],
            ),
        ],
      ),
    );
  }
}

/// Lays info rows out in two columns when there is room, one otherwise.
class EnquiryInfoGrid extends StatelessWidget {
  const EnquiryInfoGrid({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        const gap = AppTokens.space4;
        final twoUp = box.maxWidth >= 280;
        final itemWidth = twoUp ? (box.maxWidth - gap) / 2 : box.maxWidth;
        return Wrap(
          spacing: gap,
          children: [for (final child in children) SizedBox(width: itemWidth, child: child)],
        );
      },
    );
  }
}
