import 'package:flutter/material.dart';

import '../../../../core/theme/tokens.dart';

/// Card wrapper for a labelled section on the enquiry details screen.
class EnquiryDetailSection extends StatelessWidget {
  const EnquiryDetailSection({super.key, required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: AppSpacing.bottom4,
      child: Padding(
        padding: AppSpacing.space4,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: AppTokens.space4),
            ...children,
          ],
        ),
      ),
    );
  }
}
