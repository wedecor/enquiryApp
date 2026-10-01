import 'package:flutter/material.dart';

import '../../../../core/theme/tokens.dart';

/// Section outline shown at the top of the create-enquiry form.
class EnquiryFormProgress extends StatelessWidget {
  const EnquiryFormProgress({super.key, required this.sections});

  final List<String> sections;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Semantics(
      label: 'Form sections: ${sections.join(', ')}',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: AppTokens.space3,
          horizontal: AppTokens.space1,
        ),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: AppRadius.medium,
          border: Border.all(color: cs.outlineVariant),
        ),
        child: Row(
          children: [
            for (int i = 0; i < sections.length; i++) ...[
              Expanded(
                child: Column(
                  children: [
                    Container(
                      height: AppTokens.space1,
                      decoration: BoxDecoration(
                        color: cs.tertiary.withValues(alpha: 0.35),
                        borderRadius: AppRadius.small,
                      ),
                    ),
                    const SizedBox(height: AppTokens.space2),
                    Text(
                      sections[i],
                      textAlign: TextAlign.center,
                      style: theme.textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              if (i < sections.length - 1) const SizedBox(width: AppTokens.space1),
            ],
          ],
        ),
      ),
    );
  }
}
