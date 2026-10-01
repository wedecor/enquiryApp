import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/tokens.dart';

/// Tactile tap target: sinks slightly while held and springs back on release,
/// with a light selection haptic. Keeps ink ripple, focus and keyboard support
/// because it is built on [InkWell].
///
/// Use this instead of a bare [InkWell]/[GestureDetector] for anything tappable.
class Pressable extends StatefulWidget {
  const Pressable({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.borderRadius,
    this.pressedScale = 0.97,
    this.haptic = true,
    this.semanticLabel,
    this.splash = true,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final BorderRadius? borderRadius;

  /// Scale while held. 0.97 for rows/cards, ~0.92 for small icon buttons.
  final double pressedScale;
  final bool haptic;
  final String? semanticLabel;

  /// Set false where the surface already shows its own pressed state.
  final bool splash;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _pressed = false;

  bool get _enabled => widget.onTap != null || widget.onLongPress != null;

  void _handleTap() {
    if (widget.haptic) HapticFeedback.selectionClick();
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    final reduced = AppMotion.reduced(context);
    final scale = _pressed && !reduced ? widget.pressedScale : 1.0;

    Widget result = Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: widget.onTap == null ? null : _handleTap,
        onLongPress: widget.onLongPress,
        onHighlightChanged: _enabled ? (v) => setState(() => _pressed = v) : null,
        borderRadius: widget.borderRadius,
        splashFactory: widget.splash ? null : NoSplash.splashFactory,
        highlightColor: Colors.transparent,
        child: widget.child,
      ),
    );

    result = AnimatedScale(
      scale: scale,
      duration: _pressed ? AppMotion.press : AppMotion.standard,
      curve: _pressed ? Curves.easeOut : AppMotion.springOut,
      child: result,
    );

    if (widget.semanticLabel != null) {
      result = Semantics(button: true, label: widget.semanticLabel, child: result);
    }
    return result;
  }
}
