import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/theme/tokens.dart';

/// Fades and lifts a child into place, delayed by its [index] so lists and
/// grids cascade in. Only the first [maxStaggered] items are delayed so long
/// lists never feel slow. No-op under reduced motion.
class StaggerIn extends StatelessWidget {
  const StaggerIn({
    super.key,
    required this.index,
    required this.child,
    this.maxStaggered = 10,
    this.offsetY = 0.06,
  });

  final int index;
  final Widget child;
  final int maxStaggered;

  /// Vertical start offset as a fraction of the child's height.
  final double offsetY;

  @override
  Widget build(BuildContext context) {
    if (AppMotion.reduced(context)) return child;
    final delay = AppMotion.stagger * index.clamp(0, maxStaggered);
    return child
        .animate(delay: delay)
        .fadeIn(duration: AppMotion.gentle, curve: AppMotion.enter)
        .slideY(begin: offsetY, end: 0, duration: AppMotion.gentle, curve: AppMotion.enter);
  }
}
