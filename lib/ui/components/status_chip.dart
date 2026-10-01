import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';
import '../primitives/primitives.dart';

/// Soft tinted status pill: a glowing [StatusDot] and the label on a faint
/// wash of the status colour.
class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.status, this.label, this.color});

  final String? status;

  /// Overrides the title-cased [status] text.
  final String? label;

  /// Overrides the theme status colour (e.g. Firestore dropdown colours).
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = color ?? AppColorScheme.statusColorFor(status);
    final text =
        label ??
        (status == null || status!.isEmpty
            ? 'Unknown'
            : status!
                  .replaceAll('_', ' ')
                  .split(' ')
                  .map(
                    (word) => word.isEmpty ? word : '${word[0].toUpperCase()}${word.substring(1)}',
                  )
                  .join(' '));

    return DecoratedBox(
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: AppRadius.full,
        border: Border.all(color: accent.withValues(alpha: 0.26)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            StatusDot(color: accent, size: 7),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
