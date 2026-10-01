import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../ui/primitives/primitives.dart';

/// Full-bleed auth ground: ambient aurora plus two faint orbit arcs with
/// satellite dots echoing the brand seal. The arcs draw in once (no looping
/// animation) and appear instantly when animations are disabled.
class AuthBackdrop extends StatelessWidget {
  const AuthBackdrop({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final s = AppSurfaces.of(context);
    final reduced = AppMotion.reduced(context);
    return AmbientBackdrop(
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: RepaintBoundary(
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: reduced ? 1 : 0, end: 1),
                  duration: reduced ? Duration.zero : const Duration(milliseconds: 1400),
                  curve: AppMotion.enter,
                  builder: (context, t, _) => CustomPaint(
                    painter: _OrbitPainter(progress: t, color: s.accent),
                  ),
                ),
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _OrbitPainter extends CustomPainter {
  const _OrbitPainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final longest = size.longestSide;
    _orbit(
      canvas,
      center: Offset(size.width * 0.96, size.height * 0.08),
      radius: longest * 0.34,
      start: math.pi * 0.52,
      sweep: math.pi * 0.62,
      alpha: 0.32,
    );
    _orbit(
      canvas,
      center: Offset(size.width * 0.02, size.height * 0.94),
      radius: longest * 0.28,
      start: -math.pi * 0.48,
      sweep: math.pi * 0.56,
      alpha: 0.24,
    );
  }

  void _orbit(
    Canvas canvas, {
    required Offset center,
    required double radius,
    required double start,
    required double sweep,
    required double alpha,
  }) {
    final rect = Rect.fromCircle(center: center, radius: radius);
    final drawn = sweep * progress;
    canvas.drawArc(
      rect,
      start,
      drawn,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..strokeCap = StrokeCap.round
        ..color = color.withValues(alpha: alpha * progress),
    );
    canvas.drawArc(
      rect.inflate(18),
      start + sweep * 0.1,
      drawn * 0.7,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8
        ..color = color.withValues(alpha: alpha * 0.5 * progress),
    );
    final head = start + drawn;
    canvas.drawCircle(
      center + Offset(math.cos(head), math.sin(head)) * radius,
      3.5,
      Paint()..color = color.withValues(alpha: 0.7 * progress),
    );
    final trail = start + drawn * 0.45;
    canvas.drawCircle(
      center + Offset(math.cos(trail), math.sin(trail)) * (radius + 18),
      2,
      Paint()..color = color.withValues(alpha: 0.45 * progress),
    );
  }

  @override
  bool shouldRepaint(_OrbitPainter old) => old.progress != progress || old.color != color;
}
