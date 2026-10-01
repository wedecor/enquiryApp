import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/tokens.dart';

/// Small abstract mark for empty states: offset orbit arcs around a gold dot.
/// Draws itself in once (instantly under reduced motion).
class EmptyAccent extends StatelessWidget {
  const EmptyAccent({super.key, this.size = 64});

  final double size;

  @override
  Widget build(BuildContext context) {
    final s = AppSurfaces.of(context);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: AppMotion.of(context, AppMotion.slow),
      curve: AppMotion.enter,
      builder: (context, t, _) => SizedBox.square(
        dimension: size,
        child: CustomPaint(
          painter: _OrbitPainter(t: t, accent: s.accent, track: s.microBorderStrong),
        ),
      ),
    );
  }
}

class _OrbitPainter extends CustomPainter {
  const _OrbitPainter({required this.t, required this.accent, required this.track});

  final double t;
  final Color accent;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2;
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(
      c,
      r - 1,
      stroke
        ..strokeWidth = 1
        ..color = track,
    );

    canvas.drawArc(
      Rect.fromCircle(center: c, radius: r - 1),
      -math.pi * 0.85,
      math.pi * 0.7 * t,
      false,
      stroke
        ..strokeWidth = 2.2
        ..color = accent,
    );

    canvas.drawArc(
      Rect.fromCircle(center: c.translate(r * 0.12, r * 0.08), radius: r * 0.58),
      math.pi * 0.15,
      math.pi * 0.9 * t,
      false,
      stroke
        ..strokeWidth = 1.4
        ..color = accent.withValues(alpha: 0.45),
    );

    final dot = c.translate(-r * 0.05, -r * 0.04);
    canvas.drawCircle(dot, r * 0.22 * t, Paint()..color = accent.withValues(alpha: 0.16));
    canvas.drawCircle(dot, r * 0.1 * t, Paint()..color = accent);
  }

  @override
  bool shouldRepaint(_OrbitPainter old) => old.t != t || old.accent != accent || old.track != track;
}
