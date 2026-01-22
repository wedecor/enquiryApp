import 'package:flutter/material.dart';

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

    return AlertDialog(
      icon: icon != null
          ? Icon(icon, color: isDestructive ? colorScheme.error : colorScheme.primary, size: 48)
          : null,
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(cancelText ?? 'Cancel'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: isDestructive ? colorScheme.error : colorScheme.primary,
            foregroundColor: isDestructive ? colorScheme.onError : colorScheme.onPrimary,
          ),
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(confirmText ?? (isDestructive ? 'Delete' : 'Confirm')),
        ),
      ],
    );
  }
}
