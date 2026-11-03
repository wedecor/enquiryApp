import 'package:flutter/material.dart';

import '../../../../ui/primitives/primitives.dart';

/// Tiny status dots under a calendar day, plus either "N booked" (approved
/// bookings that day, tinted as a conflict when 2+) or the event total.
class CalendarDayMarkers extends StatelessWidget {
  const CalendarDayMarkers({
    super.key,
    required this.colors,
    required this.total,
    required this.hasConflict,
    this.booked = 0,
  });

  /// One colour per status present on the day.
  final List<Color> colors;
  final int total;
  final bool hasConflict;

  /// Approved bookings on the day.
  final int booked;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    // Laid out across the day cell: shrinks to fit narrow cells instead of overflowing.
    return SizedBox(
      height: 9,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final color in colors)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 1.5),
                child: StatusDot(color: color, size: 5),
              ),
            if (booked > 0 || total > 1)
              Padding(
                padding: const EdgeInsets.only(left: 2),
                child: Text(
                  booked > 0 ? '$booked booked' : '$total',
                  maxLines: 1,
                  softWrap: false,
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
        ),
      ),
    );
  }
}
