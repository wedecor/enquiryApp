import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';

/// Minimal data geometry painted directly — used instead of a charting library.

/// Animates 0 → 1 once on first build (instantly under reduced motion).
class _Grow extends StatelessWidget {
  const _Grow({required this.builder});

  final Widget Function(double t) builder;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: AppMotion.of(context, AppMotion.slow),
      curve: AppMotion.enter,
      builder: (context, t, _) => builder(t),
    );
  }
}

/// Circular progress arc with a rounded cap and an optional centred child.
class RingGauge extends StatelessWidget {
  const RingGauge({
    super.key,
    required this.value,
    this.color,
    this.size = 72,
    this.thickness = 7,
    this.child,
  });

  /// 0..1
  final double value;
  final Color? color;
  final double size;
  final double thickness;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final s = AppSurfaces.of(context);
    final c = color ?? s.accent;
    return _Grow(
      builder: (t) => SizedBox.square(
        dimension: size,
        child: CustomPaint(
          painter: _RingPainter(
            value: value.clamp(0.0, 1.0) * t,
            color: c,
            track: s.microBorderStrong,
            thickness: thickness,
          ),
          child: child == null ? null : Center(child: child),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({
    required this.value,
    required this.color,
    required this.track,
    required this.thickness,
  });

  final double value;
  final Color color;
  final Color track;
  final double thickness;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final arcRect = rect.deflate(thickness / 2);
    final base = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = thickness
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(arcRect, 0, math.pi * 2, false, base..color = track);
    if (value <= 0) return;
    final sweep = math.pi * 2 * value;
    // Paint alpha multiplies the shader, so reset it from the faint track colour.
    base.color = color;
    base.shader = SweepGradient(
      endAngle: sweep < 0.01 ? 0.01 : sweep,
      colors: [color.withValues(alpha: 0.55), color],
      transform: const GradientRotation(-math.pi / 2),
    ).createShader(rect);
    canvas.drawArc(arcRect, -math.pi / 2, sweep, false, base);
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.value != value || old.color != color || old.track != track;
}

/// Row of slim rounded bars that grow upward — a sparkline for counts.
class SparkBars extends StatelessWidget {
  const SparkBars({
    super.key,
    required this.values,
    this.color,
    this.height = 36,
    this.highlightLast = true,
  });

  final List<double> values;
  final Color? color;
  final double height;
  final bool highlightLast;

  @override
  Widget build(BuildContext context) {
    final s = AppSurfaces.of(context);
    return _Grow(
      builder: (t) => SizedBox(
        height: height,
        child: CustomPaint(
          size: Size.infinite,
          painter: _SparkBarsPainter(
            values: values,
            color: color ?? s.accent,
            muted: (color ?? s.accent).withValues(alpha: 0.32),
            t: t,
            highlightLast: highlightLast,
          ),
        ),
      ),
    );
  }
}

class _SparkBarsPainter extends CustomPainter {
  const _SparkBarsPainter({
    required this.values,
    required this.color,
    required this.muted,
    required this.t,
    required this.highlightLast,
  });

  final List<double> values;
  final Color color;
  final Color muted;
  final double t;
  final bool highlightLast;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;
    final maxV = values.reduce(math.max);
    final n = values.length;
    final gap = n > 16 ? 2.0 : 4.0;
    final w = ((size.width - gap * (n - 1)) / n).clamp(1.5, 18.0);
    final total = w * n + gap * (n - 1);
    var x = (size.width - total) / 2;
    for (var i = 0; i < n; i++) {
      final frac = maxV <= 0 ? 0.0 : values[i] / maxV;
      final h = math.max(2.0, frac * size.height * t);
      final r = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, size.height - h, w, h),
        Radius.circular(w / 2),
      );
      final isLast = highlightLast && i == n - 1;
      canvas.drawRRect(r, Paint()..color = isLast || !highlightLast ? color : muted);
      x += w + gap;
    }
  }

  @override
  bool shouldRepaint(_SparkBarsPainter old) =>
      old.t != t || old.values != values || old.color != color;
}

/// One horizontal strip divided into proportional coloured segments.
class ProportionStrip extends StatelessWidget {
  const ProportionStrip({super.key, required this.segments, this.height = 10});

  /// (value, colour) pairs; zero values are skipped.
  final List<(double, Color)> segments;
  final double height;

  @override
  Widget build(BuildContext context) {
    final s = AppSurfaces.of(context);
    final visible = segments.where((e) => e.$1 > 0).toList();
    final total = visible.fold<double>(0, (a, e) => a + e.$1);
    return _Grow(
      builder: (t) => ClipRRect(
        borderRadius: BorderRadius.circular(height),
        child: SizedBox(
          height: height,
          child: total <= 0
              ? ColoredBox(color: s.microBorderStrong)
              : Row(
                  children: [
                    for (var i = 0; i < visible.length; i++) ...[
                      if (i > 0) SizedBox(width: 2 * t),
                      Expanded(
                        flex: math.max(1, (visible[i].$1 / total * 1000 * t).round()),
                        child: ColoredBox(color: visible[i].$2),
                      ),
                    ],
                    if (t < 1)
                      Expanded(
                        flex: math.max(1, ((1 - t) * 1000).round()),
                        child: ColoredBox(color: s.microBorder),
                      ),
                  ],
                ),
        ),
      ),
    );
  }
}

/// Smoothed trend line with a soft gradient wash beneath it and a dot on the
/// latest point. Draws itself left to right on first build.
class TrendLine extends StatelessWidget {
  const TrendLine({super.key, required this.values, this.color, this.height = 120});

  final List<double> values;
  final Color? color;
  final double height;

  @override
  Widget build(BuildContext context) {
    final s = AppSurfaces.of(context);
    return _Grow(
      builder: (t) => SizedBox(
        height: height,
        child: CustomPaint(
          size: Size.infinite,
          painter: _TrendPainter(
            values: values,
            color: color ?? s.accent,
            grid: s.microBorder,
            t: t,
          ),
        ),
      ),
    );
  }
}

class _TrendPainter extends CustomPainter {
  const _TrendPainter({
    required this.values,
    required this.color,
    required this.grid,
    required this.t,
  });

  final List<double> values;
  final Color color;
  final Color grid;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = grid
      ..strokeWidth = 1;
    for (var i = 1; i <= 3; i++) {
      final y = size.height * i / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
    if (values.length < 2) return;

    final maxV = values.reduce(math.max);
    final minV = values.reduce(math.min);
    final span = (maxV - minV).abs() < 1e-9 ? 1.0 : maxV - minV;
    const pad = 8.0;
    final pts = <Offset>[
      for (var i = 0; i < values.length; i++)
        Offset(
          size.width * i / (values.length - 1),
          pad + (size.height - pad * 2) * (1 - (values[i] - minV) / span),
        ),
    ];

    final path = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (var i = 0; i < pts.length - 1; i++) {
      final p0 = pts[i];
      final p1 = pts[i + 1];
      final mx = (p0.dx + p1.dx) / 2;
      path.cubicTo(mx, p0.dy, mx, p1.dy, p1.dx, p1.dy);
    }

    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, size.width * t, size.height));

    final fill = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(
      fill,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color.withValues(alpha: 0.22), color.withValues(alpha: 0)],
        ).createShader(Offset.zero & size),
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.restore();

    if (t >= 1) {
      final last = pts.last;
      canvas.drawCircle(last, 7, Paint()..color = color.withValues(alpha: 0.18));
      canvas.drawCircle(last, 3.5, Paint()..color = color);
    }
  }

  @override
  bool shouldRepaint(_TrendPainter old) => old.t != t || old.values != values || old.color != color;
}
