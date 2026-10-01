import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';
import '../primitives/primitives.dart';

/// Full-pill call-to-action filled with a theme gradient (ink by default,
/// gold via [accent]). Shows a spinner while [loading]; disabled when
/// [onPressed] is null.
class GradientPillButton extends StatelessWidget {
  const GradientPillButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
    this.accent = false,
    this.height = 52,
  });

  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool loading;
  final bool accent;
  final double height;

  @override
  Widget build(BuildContext context) {
    final s = AppSurfaces.of(context);
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final enabled = onPressed != null && !loading;
    final foreground = accent ? AppColorScheme.brandCharcoal : cs.onPrimary;

    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      excludeSemantics: true,
      child: Pressable(
        onTap: enabled ? onPressed : null,
        borderRadius: AppRadius.full,
        child: AnimatedOpacity(
          opacity: enabled || loading ? 1 : 0.5,
          duration: AppMotion.of(context, AppMotion.quick),
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: accent ? s.accentGradient : s.inkGradient,
              borderRadius: AppRadius.full,
              boxShadow: AppShadows.glow(accent ? s.accent : s.shadow, strength: 0.2),
            ),
            child: SizedBox(
              height: height,
              child: Center(
                child: loading
                    ? SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: foreground),
                      )
                    : Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AppTokens.space4),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (icon != null) ...[
                              Icon(icon, size: 18, color: foreground),
                              const SizedBox(width: AppTokens.space2),
                            ],
                            Flexible(
                              child: Text(
                                label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: t.labelLarge?.copyWith(
                                  color: foreground,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
