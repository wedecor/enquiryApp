import 'package:flutter/material.dart';

import '../../../../core/a11y/semantics_ext.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../ui/primitives/primitives.dart';

/// Shown to staff who open an enquiry that is assigned to someone else.
class EnquiryAccessDenied extends StatelessWidget {
  const EnquiryAccessDenied({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final s = AppSurfaces.of(context);
    return Center(
      child: Padding(
        padding: AppSpacing.space6,
        child: GlassPanel(
          borderRadius: AppRadius.xLarge,
          padding: const EdgeInsets.all(AppTokens.space6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: s.accent.withValues(alpha: 0.12),
                  border: Border.all(color: s.accent.withValues(alpha: 0.3)),
                ),
                child: Icon(
                  Icons.lock_outline_rounded,
                  size: AppTokens.iconXLarge,
                  color: s.accentInk,
                ),
              ),
              const SizedBox(height: AppTokens.space4),
              const Eyebrow('Restricted', accent: true),
              const SizedBox(height: AppTokens.space1),
              Text(
                'Access Denied',
                style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
              ).withHeaderSemantics(),
              const SizedBox(height: AppTokens.space2),
              Text(
                'You can only view enquiries assigned to you.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: cs.onSurfaceVariant,
                  fontWeight: FontWeight.w300,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
