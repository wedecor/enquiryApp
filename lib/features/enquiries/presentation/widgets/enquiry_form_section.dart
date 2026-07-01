import 'package:flutter/material.dart';

import '../../../../core/theme/tokens.dart';

/// Section header + optional card wrapper for the enquiry form.
class EnquiryFormSection extends StatelessWidget {
  const EnquiryFormSection({super.key, required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: AppSpacing.vertical2,
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: theme.colorScheme.outlineVariant)),
            ),
            child: Padding(
              padding: AppSpacing.bottom2,
              child: Text(
                title,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppTokens.space4),
        ...children,
        const SizedBox(height: AppTokens.space6),
      ],
    );
  }
}
