import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../ui/primitives/primitives.dart';

/// Floating glass segmented control for the dashboard status tabs.
///
/// The ink selection slides between segments and the strip scrolls to keep the
/// selected segment centred. The dashboard remounts this widget on every tab
/// change, so the slide starts from [TabController.previousIndex].
class DashboardStatusBar extends StatefulWidget {
  const DashboardStatusBar({super.key, required this.controller, required this.labels});

  final TabController controller;
  final List<String> labels;

  static const double height = 52;

  @override
  State<DashboardStatusBar> createState() => _DashboardStatusBarState();
}

class _DashboardStatusBarState extends State<DashboardStatusBar> {
  static const double _inset = 5;
  static const double _segmentPad = AppTokens.space4;
  static const double _minSegment = 64;

  ScrollController? _scroll;
  List<double> _lefts = const [];
  List<double> _widths = const [];
  double _contentWidth = 0;
  double _viewport = 0;

  late int _index = widget.controller.index;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onIndexChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _reveal(widget.controller.index));
  }

  @override
  void didUpdateWidget(covariant DashboardStatusBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onIndexChanged);
      widget.controller.addListener(_onIndexChanged);
      _index = widget.controller.index;
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onIndexChanged);
    _scroll?.dispose();
    super.dispose();
  }

  void _onIndexChanged() {
    final index = widget.controller.index;
    if (!mounted || index == _index) return;
    setState(() => _index = index);
    _reveal(index);
  }

  double _offsetFor(int index) {
    if (index < 0 || index >= _lefts.length || _viewport <= 0) return 0;
    final maxOffset = math.max(0.0, _contentWidth - _viewport);
    return (_lefts[index] + _widths[index] / 2 - _viewport / 2).clamp(0.0, maxOffset);
  }

  void _reveal(int index) {
    final scroll = _scroll;
    if (!mounted || scroll == null || !scroll.hasClients) return;
    final target = _offsetFor(index);
    if ((scroll.offset - target).abs() < 1) return;
    if (AppMotion.reduced(context)) {
      scroll.jumpTo(target);
    } else {
      scroll.animateTo(target, duration: AppMotion.gentle, curve: AppMotion.standardCurve);
    }
  }

  void _measure(BuildContext context, TextStyle style) {
    final scaler = MediaQuery.textScalerOf(context);
    final direction = Directionality.of(context);
    final lefts = <double>[];
    final widths = <double>[];
    var x = _inset;
    for (final label in widget.labels) {
      final painter = TextPainter(
        text: TextSpan(text: label, style: style),
        textDirection: direction,
        textScaler: scaler,
        maxLines: 1,
      )..layout();
      final w = math.max(painter.width.ceilToDouble() + _segmentPad * 2, _minSegment);
      painter.dispose();
      lefts.add(x);
      widths.add(w);
      x += w;
    }
    _lefts = lefts;
    _widths = widths;
    _contentWidth = x + _inset;
  }

  @override
  Widget build(BuildContext context) {
    final s = AppSurfaces.of(context);
    final cs = Theme.of(context).colorScheme;
    final base = (Theme.of(context).textTheme.labelLarge ?? const TextStyle()).copyWith(
      letterSpacing: 0.1,
    );
    final selectedStyle = base.copyWith(fontWeight: FontWeight.w700, color: cs.onPrimary);
    final idleStyle = base.copyWith(fontWeight: FontWeight.w500, color: cs.onSurfaceVariant);
    _measure(context, selectedStyle);

    final count = widget.labels.length;
    final index = widget.controller.index.clamp(0, count - 1);
    final previous = widget.controller.previousIndex.clamp(0, count - 1);
    const pillHeight = DashboardStatusBar.height - _inset * 2;
    Rect rectFor(int i) => Rect.fromLTWH(_lefts[i], _inset, _widths[i], pillHeight);

    return LayoutBuilder(
      builder: (context, box) {
        _viewport = math.min(_contentWidth, box.maxWidth);
        _scroll ??= ScrollController(initialScrollOffset: _offsetFor(previous));

        final strip = SizedBox(
          width: _contentWidth,
          height: DashboardStatusBar.height,
          child: Stack(
            children: [
              TweenAnimationBuilder<Rect?>(
                tween: RectTween(begin: rectFor(previous), end: rectFor(index)),
                duration: AppMotion.of(context, AppMotion.gentle),
                curve: AppMotion.springOut,
                builder: (context, rect, _) => Positioned.fromRect(
                  rect: rect ?? rectFor(index),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: s.inkGradient,
                      borderRadius: AppRadius.full,
                      boxShadow: AppShadows.glow(s.shadow, strength: 0.16),
                    ),
                  ),
                ),
              ),
              for (var i = 0; i < count; i++)
                Positioned(
                  left: _lefts[i],
                  top: 0,
                  bottom: 0,
                  width: _widths[i],
                  child: _Segment(
                    label: widget.labels[i],
                    selected: i == index,
                    style: i == index ? selectedStyle : idleStyle,
                    onTap: () => widget.controller.animateTo(i),
                  ),
                ),
            ],
          ),
        );

        return Align(
          alignment: AlignmentDirectional.centerStart,
          child: SizedBox(
            width: _viewport,
            child: GlassPanel(
              strong: true,
              shadow: true,
              borderRadius: AppRadius.full,
              child: ClipRRect(
                borderRadius: AppRadius.full,
                child: SingleChildScrollView(
                  controller: _scroll,
                  scrollDirection: Axis.horizontal,
                  child: strip,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({
    required this.label,
    required this.selected,
    required this.style,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final TextStyle style;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      button: true,
      label: label,
      excludeSemantics: true,
      child: Pressable(
        onTap: onTap,
        pressedScale: 0.94,
        splash: false,
        borderRadius: AppRadius.full,
        child: Center(
          child: AnimatedDefaultTextStyle(
            duration: AppMotion.of(context, AppMotion.standard),
            curve: AppMotion.standardCurve,
            style: style,
            child: Text(label, maxLines: 1, softWrap: false),
          ),
        ),
      ),
    );
  }
}
