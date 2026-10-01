import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';
import '../primitives/primitives.dart';

/// One option in a [GlassSegmentedTabs].
class GlassSegment {
  const GlassSegment(this.label, {this.icon});

  final String label;
  final IconData? icon;
}

/// Glass pill segmented control driven by a [TabController]. The indicator
/// tracks the controller's animation, so it slides with taps and follows a
/// [TabBarView] swipe. Segments share the width when they fit; otherwise the
/// pill scrolls and keeps the selection centred.
///
/// [subtle] drops the outer pill and uses a glass (not ink) indicator, for a
/// secondary switcher nested under a primary one.
class GlassSegmentedTabs extends StatefulWidget {
  const GlassSegmentedTabs({
    super.key,
    required this.controller,
    required this.segments,
    this.minSegmentWidth = 108,
    this.subtle = false,
  });

  final TabController controller;
  final List<GlassSegment> segments;
  final double minSegmentWidth;
  final bool subtle;

  @override
  State<GlassSegmentedTabs> createState() => _GlassSegmentedTabsState();
}

class _GlassSegmentedTabsState extends State<GlassSegmentedTabs> {
  static const double _height = 48;
  final _scroll = ScrollController();
  List<double> _offsets = const [];
  List<double> _widths = const [];
  double _viewport = 0;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_revealSelected);
  }

  @override
  void didUpdateWidget(GlassSegmentedTabs oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_revealSelected);
      widget.controller.addListener(_revealSelected);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_revealSelected);
    _scroll.dispose();
    super.dispose();
  }

  double _naturalWidth(BuildContext context, GlassSegment segment) {
    final style = Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700);
    final painter = TextPainter(
      text: TextSpan(text: segment.label, style: style),
      maxLines: 1,
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
    )..layout();
    final icon = segment.icon != null ? 24.0 : 0.0;
    final width = painter.width + icon + AppTokens.space4 * 2;
    painter.dispose();
    return width < widget.minSegmentWidth * 0.6 ? widget.minSegmentWidth * 0.6 : width;
  }

  void _revealSelected() {
    if (!mounted || !_scroll.hasClients || _offsets.isEmpty) return;
    final i = widget.controller.index.clamp(0, _offsets.length - 1);
    final position = _scroll.position;
    final target = (_offsets[i] - (_viewport - _widths[i]) / 2).clamp(
      0.0,
      position.maxScrollExtent,
    );
    final duration = AppMotion.of(context, AppMotion.standard);
    if (duration == Duration.zero) {
      _scroll.jumpTo(target);
    } else {
      _scroll.animateTo(target, duration: duration, curve: AppMotion.standardCurve);
    }
  }

  void _select(int index) {
    final duration = AppMotion.of(context, AppMotion.standard);
    widget.controller.animateTo(
      index,
      // A zero duration skips `indexIsChanging`, which TabController listeners rely on.
      duration: duration == Duration.zero ? const Duration(milliseconds: 1) : duration,
      curve: AppMotion.standardCurve,
    );
  }

  BoxDecoration _indicatorDecoration(AppSurfaces s) {
    if (widget.subtle) {
      return BoxDecoration(
        color: s.glassFillStrong,
        borderRadius: AppRadius.full,
        border: Border.all(color: s.microBorderStrong),
        boxShadow: [
          BoxShadow(
            color: s.shadow.withValues(alpha: 0.08),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      );
    }
    return BoxDecoration(
      gradient: s.inkGradient,
      borderRadius: AppRadius.full,
      boxShadow: AppShadows.glow(s.shadow, strength: 0.16),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = AppSurfaces.of(context);
    final cs = Theme.of(context).colorScheme;
    final activeColor = widget.subtle ? cs.onSurface : cs.onPrimary;

    final content = LayoutBuilder(
      builder: (context, constraints) {
        final count = widget.segments.length;
        final natural = [for (final seg in widget.segments) _naturalWidth(context, seg)];
        final total = natural.fold<double>(0, (a, b) => a + b);
        final fits = total <= constraints.maxWidth;
        final extra = fits ? (constraints.maxWidth - total) / count : 0.0;
        final widths = [for (final w in natural) w + extra];
        final offsets = <double>[0];
        for (var i = 0; i < count - 1; i++) {
          offsets.add(offsets[i] + widths[i]);
        }
        _offsets = offsets;
        _widths = widths;
        _viewport = constraints.maxWidth;
        final animation = widget.controller.animation!;

        final track = SizedBox(
          width: offsets.last + widths.last,
          height: _height,
          child: AnimatedBuilder(
            animation: animation,
            builder: (context, _) {
              final position = animation.value.clamp(0.0, count - 1.0);
              final lo = position.floor();
              final hi = position.ceil();
              final f = position - lo;
              return Stack(
                children: [
                  Positioned(
                    left: offsets[lo] + (offsets[hi] - offsets[lo]) * f,
                    top: 0,
                    bottom: 0,
                    width: widths[lo] + (widths[hi] - widths[lo]) * f,
                    child: DecoratedBox(decoration: _indicatorDecoration(s)),
                  ),
                  Positioned.fill(
                    child: Row(
                      children: [
                        for (var i = 0; i < count; i++)
                          SizedBox(
                            width: widths[i],
                            child: _SegmentButton(
                              segment: widget.segments[i],
                              emphasis: (1 - (position - i).abs()).clamp(0.0, 1.0),
                              activeColor: activeColor,
                              selected: widget.controller.index == i,
                              onTap: () => _select(i),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        );

        if (fits) return track;
        return SingleChildScrollView(
          controller: _scroll,
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: track,
        );
      },
    );

    if (widget.subtle) return content;
    return GlassPanel(
      strong: true,
      borderRadius: AppRadius.full,
      padding: const EdgeInsets.all(4),
      child: content,
    );
  }
}

class _SegmentButton extends StatelessWidget {
  const _SegmentButton({
    required this.segment,
    required this.emphasis,
    required this.activeColor,
    required this.selected,
    required this.onTap,
  });

  final GlassSegment segment;

  /// 0..1 — how much the indicator currently sits under this segment.
  final double emphasis;
  final Color activeColor;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final color = Color.lerp(cs.onSurfaceVariant, activeColor, emphasis)!;
    return Semantics(
      selected: selected,
      inMutuallyExclusiveGroup: true,
      child: Pressable(
        onTap: onTap,
        borderRadius: AppRadius.full,
        pressedScale: 0.94,
        splash: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTokens.space3),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (segment.icon != null) ...[
                Icon(segment.icon, size: 18, color: color),
                const SizedBox(width: 6),
              ],
              Flexible(
                child: Text(
                  segment.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: t.labelLarge?.copyWith(
                    color: color,
                    fontWeight: emphasis > 0.5 ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
