import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';

/// Small abstract mark for empty / error states: a hairline orbit with an
/// accent arc that sweeps in, a satellite dot and an optional glyph inside.
/// [broken] splits the arc to read as "something interrupted".
class StateAccent extends StatelessWidget {
  const StateAccent({super.key, this.icon, this.color, this.broken = false, this.size = 60});

  final IconData? icon;
  final Color? color;
  final bool broken;
  final double size;

  @override
  Widget build(BuildContext context) {
    final s = AppSurfaces.of(context);
    final cs = Theme.of(context).colorScheme;
    final accent = color ?? s.accent;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: AppMotion.of(context, AppMotion.slow),
      curve: AppMotion.enter,
      builder: (context, t, child) => CustomPaint(
        painter: _AccentPainter(
          progress: t,
          color: accent,
          track: s.microBorderStrong,
          broken: broken,
        ),
        child: child,
      ),
      child: SizedBox.square(
        dimension: size,
        child: icon == null
            ? null
            : Icon(icon, size: size * 0.34, color: cs.onSurfaceVariant.withValues(alpha: 0.8)),
      ),
    );
  }
}

class _AccentPainter extends CustomPainter {
  const _AccentPainter({
    required this.progress,
    required this.color,
    required this.track,
    required this.broken,
  });

  final double progress;
  final Color color;
  final Color track;
  final bool broken;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2 - 4;
    final rect = Rect.fromCircle(center: center, radius: radius);

    canvas.drawCircle(center, radius - 9, Paint()..color = color.withValues(alpha: 0.07));
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = track,
    );

    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..color = color;
    const start = -math.pi / 2;
    final sweep = (broken ? 0.9 : 1.45) * math.pi * progress;
    canvas.drawArc(rect, start, sweep, false, arc);
    if (broken) {
      canvas.drawArc(rect, start + 1.15 * math.pi, 0.45 * math.pi * progress, false, arc);
    }

    final end = start + sweep;
    final head = center + Offset(math.cos(end), math.sin(end)) * radius;
    canvas.drawCircle(head, 3.2, Paint()..color = color);

    final satellite = center + Offset(math.cos(-2.4), math.sin(-2.4)) * (radius + 1);
    canvas.drawCircle(satellite, 2, Paint()..color = color.withValues(alpha: 0.45 * progress));
  }

  @override
  bool shouldRepaint(_AccentPainter old) =>
      old.progress != progress || old.color != color || old.track != track || old.broken != broken;
}
