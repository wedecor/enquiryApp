import 'package:flutter/material.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/theme/tokens.dart';
import '../../../../../ui/primitives/primitives.dart';

/// Centred spinner with a whisper caption.
class AnalyticsLoadingView extends StatelessWidget {
  const AnalyticsLoadingView({super.key, this.message = 'Loading analytics data...'});

  final String message;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final s = AppSurfaces.of(context);
    return Center(
      child: Padding(
        padding: AppSpacing.space8,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox.square(
              dimension: 28,
              child: CircularProgressIndicator(strokeWidth: 2.4, color: s.accent),
            ),
            const SizedBox(height: AppTokens.space4),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: cs.onSurfaceVariant,
                fontWeight: FontWeight.w300,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Floating glass message panel with an icon medallion, heading, body copy
/// and an optional action.
class AnalyticsMessagePanel extends StatelessWidget {
  const AnalyticsMessagePanel({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.message,
    this.detail,
    this.action,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String message;
  final String? detail;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Center(
      child: SingleChildScrollView(
        padding: AppSpacing.space6,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: GlassPanel(
            strong: true,
            shadow: true,
            borderRadius: AppRadius.xxLarge,
            padding: AppSpacing.space8,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: iconColor.withValues(alpha: 0.12),
                    border: Border.all(color: iconColor.withValues(alpha: 0.24)),
                  ),
                  child: SizedBox.square(
                    dimension: 72,
                    child: Icon(icon, size: AppTokens.iconXLarge, color: iconColor),
                  ),
                ),
                const SizedBox(height: AppTokens.space6),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: AppTokens.space3),
                Text(message, style: theme.textTheme.bodyLarge, textAlign: TextAlign.center),
                if (detail != null) ...[
                  const SizedBox(height: AppTokens.space2),
                  Text(
                    detail!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                      fontWeight: FontWeight.w300,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
                if (action != null) ...[const SizedBox(height: AppTokens.space6), action!],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AnalyticsErrorView extends StatelessWidget {
  const AnalyticsErrorView({super.key, required this.error, required this.onRetry});

  final String error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return AnalyticsMessagePanel(
      icon: Icons.error_outline_rounded,
      iconColor: Theme.of(context).colorScheme.error,
      title: 'Error Loading Data',
      message: error,
      action: OutlinedButton.icon(
        onPressed: onRetry,
        icon: const Icon(Icons.refresh_rounded),
        label: const Text('Try Again'),
      ),
    );
  }
}

class AnalyticsNoAccessView extends StatelessWidget {
  const AnalyticsNoAccessView({super.key, this.onBack});

  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return AnalyticsMessagePanel(
      icon: Icons.security_rounded,
      iconColor: AppColorScheme.snackWarning,
      title: 'Access Restricted',
      message: 'System Analytics is only available to administrators.',
      detail: 'Please contact your administrator if you need access to these features.',
      action: onBack == null
          ? null
          : OutlinedButton.icon(
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back_rounded),
              label: const Text('Go Back'),
            ),
    );
  }
}
