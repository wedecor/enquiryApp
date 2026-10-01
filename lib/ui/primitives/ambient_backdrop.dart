import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// Page ground: the theme gradient with three soft organic colour fields
/// painted behind the content, so glass panels have something to refract.
class AmbientBackdrop extends StatelessWidget {
  const AmbientBackdrop({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final s = AppSurfaces.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(gradient: s.ground),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: RepaintBoundary(
              child: IgnorePointer(child: CustomPaint(painter: _AuroraPainter(s.aurora))),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _AuroraPainter extends CustomPainter {
  const _AuroraPainter(this.colors);

  final List<Color> colors;

  // Relative centre and radius (as a fraction of the longest side) per field.
  static const _fields = [
    (Offset(0.88, 0.04), 0.62),
    (Offset(0.02, 0.46), 0.52),
    (Offset(0.70, 0.98), 0.58),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final longest = size.longestSide;
    for (var i = 0; i < _fields.length && i < colors.length; i++) {
      final (rel, r) = _fields[i];
      final center = Offset(rel.dx * size.width, rel.dy * size.height);
      final radius = r * longest;
      final paint = Paint()
        ..shader = RadialGradient(
          colors: [colors[i], colors[i].withValues(alpha: 0)],
        ).createShader(Rect.fromCircle(center: center, radius: radius));
      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(_AuroraPainter old) => old.colors != colors;
}
