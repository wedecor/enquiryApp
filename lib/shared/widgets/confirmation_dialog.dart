import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';
import '../../ui/primitives/primitives.dart';
import 'press_scale.dart';

/// Reusable confirmation dialog widget with consistent styling
///
/// Provides a standardized way to confirm destructive or important actions
/// with clear, non-technical messaging.
class ConfirmationDialog extends StatelessWidget {
  const ConfirmationDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmText,
    this.cancelText,
    this.isDestructive = false,
    this.icon,
  });

  /// Dialog title
  final String title;

  /// Main message explaining what will happen
  final String message;

  /// Text for confirm button (default: "Confirm" or "Delete" if destructive)
  final String? confirmText;

  /// Text for cancel button (default: "Cancel")
  final String? cancelText;

  /// Whether this is a destructive action (affects button color)
  final bool isDestructive;

  /// Optional icon to display
  final IconData? icon;

  /// Show confirmation dialog and return true if confirmed
  static Future<bool> show({
    required BuildContext context,
    required String title,
    required String message,
    String? confirmText,
    String? cancelText,
    bool isDestructive = false,
    IconData? icon,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => ConfirmationDialog(
        title: title,
        message: message,
        confirmText: confirmText,
        cancelText: cancelText,
        isDestructive: isDestructive,
        icon: icon,
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final s = AppSurfaces.of(context);
    final accent = isDestructive ? colorScheme.error : s.accent;
    final confirmLabel = confirmText ?? (isDestructive ? 'Delete' : 'Confirm');
    final cancelLabel = cancelText ?? 'Cancel';

    final confirm = PressScale(
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: isDestructive ? colorScheme.error : colorScheme.primary,
          foregroundColor: isDestructive ? colorScheme.onError : colorScheme.onPrimary,
        ),
        onPressed: () => Navigator.of(context).pop(true),
        child: Text(confirmLabel, textAlign: TextAlign.center),
      ),
    );
    final cancel = PressScale(
      child: OutlinedButton(
        onPressed: () => Navigator.of(context).pop(false),
        child: Text(cancelLabel, textAlign: TextAlign.center),
      ),
    );
    final sideBySide = confirmLabel.length <= 12 && cancelLabel.length <= 12;

    return Dialog(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: AppTokens.space6, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: GlassPanel(
          blur: true,
          strong: true,
          shadow: true,
          borderRadius: AppRadius.xLarge,
          tint: accent.withValues(alpha: 0.05),
          padding: const EdgeInsets.fromLTRB(
            AppTokens.space6,
            AppTokens.space6,
            AppTokens.space6,
            AppTokens.space5,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  if (icon != null) ...[
                    _IconHalo(icon: icon!, color: accent),
                    const SizedBox(width: AppTokens.space3),
                  ],
                  Expanded(
                    child: Eyebrow(
                      isDestructive ? 'Cannot be undone' : 'Please confirm',
                      color: isDestructive ? colorScheme.error : null,
                      accent: !isDestructive,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTokens.space4),
              Text(
                title,
                style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: AppTokens.space2),
              Flexible(
                child: SingleChildScrollView(
                  child: Text(
                    message,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppTokens.space6),
              if (sideBySide)
                Row(
                  children: [
                    Expanded(child: cancel),
                    const SizedBox(width: AppTokens.space3),
                    Expanded(child: confirm),
                  ],
                )
              else ...[
                confirm,
                const SizedBox(height: AppTokens.space2),
                cancel,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _IconHalo extends StatelessWidget {
  const _IconHalo({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.12),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Icon(icon, size: 20, color: color),
    );
  }
}
