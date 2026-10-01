import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';
import '../../utils/event_colors.dart';

/// Subtle outlined pill: hairline border, a tiny event-colour dot and the
/// event type in a medium weight.
class EventTypeChip extends StatelessWidget {
  const EventTypeChip({super.key, required this.eventType});

  final String? eventType;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = AppSurfaces.of(context);
    final accent = eventAccent(eventType);
    final label = (eventType ?? 'Event')
        .split(' ')
        .map((word) => word.isEmpty ? word : '${word[0].toUpperCase()}${word.substring(1)}')
        .join(' ');

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: AppRadius.full,
        border: Border.all(color: s.microBorderStrong),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
              child: const SizedBox.square(dimension: 6),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
