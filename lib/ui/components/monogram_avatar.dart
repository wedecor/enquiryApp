import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// Initials disc inside a thin gold gradient ring. [dimmed] swaps the ring
/// for a neutral hairline (inactive members).
class MonogramAvatar extends StatelessWidget {
  const MonogramAvatar({super.key, required this.name, this.size = 44, this.dimmed = false});

  final String name;
  final double size;
  final bool dimmed;

  String get _initials {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    final first = parts.first.characters.first;
    if (parts.length == 1) return first.toUpperCase();
    return (first + parts.last.characters.first).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppSurfaces.of(context);
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size > 48 ? 2.5 : 2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: dimmed ? null : s.accentGradient,
        color: dimmed ? s.microBorderStrong : null,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(shape: BoxShape.circle, color: cs.surface),
        child: Center(
          child: Text(
            _initials,
            maxLines: 1,
            style: t.titleSmall?.copyWith(
              fontSize: size * 0.34,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.4,
              color: dimmed ? cs.onSurfaceVariant : cs.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}
