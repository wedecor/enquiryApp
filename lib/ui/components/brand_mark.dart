import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';

/// Gold seal (a gradient disc inside a broken orbit ring) plus the optional
/// "WE DECOR" wordmark set in Marcellus, matching the brand toolkit.
class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.compact = false, this.showSubtitle = false, this.size = 22});

  final bool compact;
  final bool showSubtitle;
  final double size;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = AppSurfaces.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox.square(
              dimension: size,
              child: CustomPaint(
                painter: _SealPainter(gradient: s.accentGradient, ring: s.accent),
              ),
            ),
            if (!compact) ...[
              const SizedBox(width: AppTokens.space2 + 2),
              Text(
                'WE DECOR',
                style: GoogleFonts.marcellus(
                  textStyle: theme.textTheme.titleMedium,
                  color: theme.colorScheme.onSurface,
                  letterSpacing: 3,
                ),
              ),
            ],
          ],
        ),
        if (showSubtitle) ...[
          const SizedBox(height: AppTokens.space1),
          Text(
            'ENQUIRIES',
            style: theme.textTheme.labelSmall
                ?.merge(AppTypography.eyebrow)
                .copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ],
    );
  }
}

class _SealPainter extends CustomPainter {
  const _SealPainter({required this.gradient, required this.ring});

  final Gradient gradient;
  final Color ring;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2;
    final rect = Rect.fromCircle(center: c, radius: r);

    canvas.drawArc(
      rect.deflate(0.75),
      -math.pi * 0.35,
      math.pi * 1.55,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round
        ..color = ring.withValues(alpha: 0.55),
    );
    canvas.drawCircle(c, r * 0.5, Paint()..shader = gradient.createShader(rect));
    canvas.drawCircle(Offset(c.dx + r * 0.72, c.dy - r * 0.72), r * 0.12, Paint()..color = ring);
  }

  @override
  bool shouldRepaint(_SealPainter old) => old.gradient != gradient || old.ring != ring;
}
