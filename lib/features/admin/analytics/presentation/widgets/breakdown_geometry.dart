import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/theme/tokens.dart';
import '../../../../../ui/primitives/primitives.dart';

/// One legend entry: dot, label, heavy count and whisper percentage.
class BreakdownLegendRow extends StatelessWidget {
  const BreakdownLegendRow({
    super.key,
    required this.color,
    required this.label,
    required this.count,
    required this.percentage,
  });

  final Color color;
  final String label;
  final int count;
  final double percentage;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          StatusDot(color: color, size: 8),
          const SizedBox(width: AppTokens.space3),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: t.bodyMedium?.copyWith(color: cs.onSurface),
            ),
          ),
          const SizedBox(width: AppTokens.space2),
          Text(
            '$count',
            style: t.bodyMedium?.copyWith(
              fontWeight: FontWeight.w800,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          SizedBox(
            width: 52,
            child: Text(
              '${percentage.toStringAsFixed(1)}%',
              textAlign: TextAlign.right,
              maxLines: 1,
              style: t.bodySmall?.copyWith(
                color: cs.onSurfaceVariant,
                fontWeight: FontWeight.w300,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Animates 0 → 1 once, instantly under reduced motion.
class _Reveal extends StatelessWidget {
  const _Reveal({required this.builder});

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

/// Donut of rounded arc segments separated by small gaps, sweeping in
/// clockwise from 12 o'clock. [child] sits in the centre.
class SegmentedRing extends StatelessWidget {
  const SegmentedRing({
    super.key,
    required this.segments,
    this.size = 160,
    this.thickness = 14,
    this.child,
  });

  final List<(double, Color)> segments;
  final double size;
  final double thickness;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final s = AppSurfaces.of(context);
    return _Reveal(
      builder: (t) => SizedBox.square(
        dimension: size,
        child: CustomPaint(
          painter: _SegmentedRingPainter(
            segments: segments,
            thickness: thickness,
            track: s.microBorder,
            t: t,
          ),
          child: child == null ? null : Center(child: child),
        ),
      ),
    );
  }
}

class _SegmentedRingPainter extends CustomPainter {
  const _SegmentedRingPainter({
    required this.segments,
    required this.thickness,
    required this.track,
    required this.t,
  });

  final List<(double, Color)> segments;
  final double thickness;
  final Color track;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(thickness / 2);
    final radius = rect.width / 2;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = thickness
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, 0, math.pi * 2, false, paint..color = track);

    final visible = segments.where((e) => e.$1 > 0).toList();
    final total = visible.fold<double>(0, (a, e) => a + e.$1);
    if (total <= 0 || t <= 0) return;

    final capAngle = visible.length > 1 ? (thickness / 2) / radius : 0.0;
    final gap = visible.length > 1 ? capAngle * 2 + 0.05 : 0.0;
    final revealed = math.pi * 2 * t;
    var start = -math.pi / 2;
    var consumed = 0.0;

    for (final (value, color) in visible) {
      final full = value / total * math.pi * 2;
      final shown = math.min(full, revealed - consumed);
      if (shown <= 0) break;
      final sweep = math.max(0.001, shown - gap);
      canvas.drawArc(rect, start + capAngle, sweep, false, paint..color = color);
      start += full;
      consumed += full;
    }
  }

  @override
  bool shouldRepaint(_SegmentedRingPainter old) =>
      old.t != t || old.segments != segments || old.track != track;
}

/// Grid of dots ([columns] × [rows]) where each dot is one share of the
/// total, filled in reading order and coloured by segment.
class DotMatrix extends StatelessWidget {
  const DotMatrix({super.key, required this.segments, this.columns = 20, this.rows = 5});

  final List<(double, Color)> segments;
  final int columns;
  final int rows;

  @override
  Widget build(BuildContext context) {
    final s = AppSurfaces.of(context);
    return AspectRatio(
      aspectRatio: columns / rows,
      child: _Reveal(
        builder: (t) => CustomPaint(
          painter: _DotMatrixPainter(
            cells: _allocate(segments, columns * rows),
            columns: columns,
            rows: rows,
            empty: s.microBorderStrong,
            t: t,
          ),
        ),
      ),
    );
  }

  /// Largest-remainder allocation of [count] cells across [segments].
  static List<Color> _allocate(List<(double, Color)> segments, int count) {
    final visible = segments.where((e) => e.$1 > 0).toList();
    final total = visible.fold<double>(0, (a, e) => a + e.$1);
    if (total <= 0) return const [];
    final exact = [for (final e in visible) e.$1 / total * count];
    final whole = [for (final x in exact) x.floor()];
    var remaining = count - whole.fold<int>(0, (a, b) => a + b);
    final order = List.generate(visible.length, (i) => i)
      ..sort((a, b) => (exact[b] - whole[b]).compareTo(exact[a] - whole[a]));
    for (final i in order) {
      if (remaining <= 0) break;
      whole[i]++;
      remaining--;
    }
    return [for (var i = 0; i < visible.length; i++) ...List.filled(whole[i], visible[i].$2)];
  }
}

class _DotMatrixPainter extends CustomPainter {
  const _DotMatrixPainter({
    required this.cells,
    required this.columns,
    required this.rows,
    required this.empty,
    required this.t,
  });

  final List<Color> cells;
  final int columns;
  final int rows;
  final Color empty;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final pitch = math.min(size.width / columns, size.height / rows);
    final radius = pitch * 0.34;
    final revealed = (cells.length * t).round();
    final paint = Paint();
    for (var i = 0; i < columns * rows; i++) {
      final col = i % columns;
      final row = i ~/ columns;
      final center = Offset(pitch * (col + 0.5), pitch * (row + 0.5));
      final filled = i < revealed;
      paint.color = filled ? cells[i] : empty;
      canvas.drawCircle(center, filled ? radius : radius * 0.7, paint);
    }
  }

  @override
  bool shouldRepaint(_DotMatrixPainter old) =>
      old.t != t || old.cells != cells || old.empty != empty;
}
