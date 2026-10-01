import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';

/// Icon set in a soft tinted circle — leading mark for rows and dialogs.
class TintedIconBadge extends StatelessWidget {
  const TintedIconBadge({
    super.key,
    required this.icon,
    this.color,
    this.size = 38,
    this.enabled = true,
  });

  final IconData icon;
  final Color? color;
  final double size;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final base = enabled
        ? (color ?? AppSurfaces.of(context).accentInk)
        : cs.onSurfaceVariant.withValues(alpha: 0.6);
    return AnimatedContainer(
      duration: AppMotion.of(context, AppMotion.standard),
      curve: AppMotion.standardCurve,
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: base.withValues(alpha: 0.12),
        border: Border.all(color: base.withValues(alpha: 0.18)),
      ),
      child: Icon(icon, size: size * 0.48, color: base),
    );
  }
}
