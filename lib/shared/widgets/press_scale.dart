import 'package:flutter/material.dart';

import '../../core/theme/tokens.dart';

/// Adds the sink-and-spring press feel to widgets that already handle their
/// own taps (Material buttons, menu buttons). Purely visual: it listens to raw
/// pointer events and never competes in the gesture arena.
class PressScale extends StatefulWidget {
  const PressScale({super.key, required this.child, this.pressedScale = 0.96});

  final Widget child;
  final double pressedScale;

  @override
  State<PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<PressScale> {
  bool _down = false;

  void _set(bool value) {
    if (_down != value) setState(() => _down = value);
  }

  @override
  Widget build(BuildContext context) {
    final reduced = AppMotion.reduced(context);
    return Listener(
      onPointerDown: (_) => _set(true),
      onPointerUp: (_) => _set(false),
      onPointerCancel: (_) => _set(false),
      child: AnimatedScale(
        scale: _down && !reduced ? widget.pressedScale : 1,
        duration: _down ? AppMotion.press : AppMotion.standard,
        curve: _down ? Curves.easeOut : AppMotion.springOut,
        child: widget.child,
      ),
    );
  }
}
