import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/theme/tokens.dart';

/// Small accent dot with a soft halo; optionally breathes to flag "live" items
/// (e.g. new enquiries). The pulse is disabled under reduced motion.
class StatusDot extends StatelessWidget {
  const StatusDot({super.key, required this.color, this.size = 8, this.pulse = false});

  final Color color;
  final double size;
  final bool pulse;

  @override
  Widget build(BuildContext context) {
    final dot = DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.45), blurRadius: size)],
      ),
      child: SizedBox.square(dimension: size),
    );
    if (!pulse || AppMotion.reduced(context)) return dot;

    final halo =
        DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: 0.35),
              ),
              child: SizedBox.square(dimension: size),
            )
            .animate(onPlay: (c) => c.repeat())
            .scaleXY(begin: 1, end: 2.6, duration: 1600.ms, curve: Curves.easeOut)
            .fadeOut(duration: 1600.ms, curve: Curves.easeOut);

    return SizedBox.square(
      dimension: size,
      child: Stack(clipBehavior: Clip.none, alignment: Alignment.center, children: [halo, dot]),
    );
  }
}
