import 'package:flutter/material.dart';

import '../../../../core/theme/tokens.dart';

/// Card wrapper for a labelled section on the enquiry details screen.
class EnquiryDetailSection extends StatelessWidget {
  const EnquiryDetailSection({
    super.key,
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: AppSpacing.bottom4,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: AppRadius.large,
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        child: Padding(
          padding: AppSpacing.space4,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppTokens.space3),
              ...children,
            ],
          ),
        ),
      ),
    );
  }
}
