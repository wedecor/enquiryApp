import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';

/// Quiet glass pill showing how long ago an enquiry arrived.
class AgeChip extends StatelessWidget {
  const AgeChip({super.key, required this.createdAt});

  final DateTime createdAt;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = AppSurfaces.of(context);
    final age = DateTime.now().difference(createdAt);
    final label = _formatAge(age);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: s.glassFill,
        borderRadius: AppRadius.full,
        border: Border.all(color: s.microBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.schedule_rounded, size: 12, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(width: 5),
            Text(
              label,
              maxLines: 1,
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w600,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatAge(Duration age) {
    if (age.inMinutes < 1) return 'Just now';
    if (age.inMinutes < 60) return '${age.inMinutes}m old';
    if (age.inHours < 24) return '${age.inHours}h old';
    if (age.inDays < 7) return '${age.inDays}d old';
    final weeks = age.inDays ~/ 7;
    if (weeks < 5) return '${weeks}w old';
    final months = age.inDays ~/ 30;
    if (months < 12) return '${months}mo old';
    final years = age.inDays ~/ 365;
    return '${years}y old';
  }
}
