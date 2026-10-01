import 'package:flutter/material.dart';

import '../../../../../ui/components/glass_dialog.dart';

class ConfirmDialog extends StatelessWidget {
  final String title;
  final String content;
  final VoidCallback onConfirm;
  final String? confirmText;
  final String? cancelText;
  final bool isDestructive;

  const ConfirmDialog({
    super.key,
    required this.title,
    required this.content,
    required this.onConfirm,
    this.confirmText,
    this.cancelText,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GlassDialog(
      eyebrow: 'Confirm',
      title: title,
      icon: isDestructive ? Icons.warning_amber_rounded : Icons.help_outline_rounded,
      iconColor: isDestructive ? cs.error : null,
      content: Text(content),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(cancelText ?? 'Cancel'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.of(context).pop();
            onConfirm();
          },
          style: isDestructive
              ? FilledButton.styleFrom(backgroundColor: cs.error, foregroundColor: cs.onError)
              : null,
          child: Text(confirmText ?? 'Confirm'),
        ),
      ],
    );
  }
}
