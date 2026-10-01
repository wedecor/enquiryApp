import 'package:flutter/material.dart';

import '../../../../core/a11y/semantics_ext.dart';
import '../../../../core/theme/tokens.dart';

/// Shown to staff who open an enquiry that is assigned to someone else.
class EnquiryAccessDenied extends StatelessWidget {
  const EnquiryAccessDenied({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Center(
      child: Padding(
        padding: AppSpacing.space6,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock, size: AppTokens.space16, color: cs.onSurfaceVariant),
            const SizedBox(height: AppTokens.space4),
            Text(
              'Access Denied',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
            ).withHeaderSemantics(),
            const SizedBox(height: AppTokens.space2),
            Text(
              'You can only view enquiries assigned to you.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
