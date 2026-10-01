import 'package:flutter/material.dart';

import '../../../../ui/primitives/primitives.dart';

/// Tiny status dots under a calendar day, plus the event total when a day is
/// double-booked (tinted as a conflict).
class CalendarDayMarkers extends StatelessWidget {
  const CalendarDayMarkers({
    super.key,
    required this.colors,
    required this.total,
    required this.hasConflict,
  });

  /// One colour per status present on the day.
  final List<Color> colors;
  final int total;
  final bool hasConflict;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final color in colors)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 1.5),
            child: StatusDot(color: color, size: 5),
          ),
        if (total > 1)
          Padding(
            padding: const EdgeInsets.only(left: 2),
            child: Text(
              '$total',
              style: theme.textTheme.labelSmall?.copyWith(
                fontSize: 8.5,
                height: 1,
                letterSpacing: 0,
                fontWeight: FontWeight.w800,
                color: hasConflict ? cs.error : cs.onSurfaceVariant,
              ),
            ),
          ),
      ],
    );
  }
}
