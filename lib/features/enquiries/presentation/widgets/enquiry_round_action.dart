import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../ui/primitives/primitives.dart';

/// Labelled circular action (Call, WhatsApp, Review…) shown in the enquiry
/// header. The whole column is the tap target.
class EnquiryRoundAction extends StatelessWidget {
  const EnquiryRoundAction({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    required this.semanticLabel,
    this.semanticHint,
    this.enabled = true,
  });

  static const double circleSize = 52;

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;
  final String semanticLabel;
  final String? semanticHint;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final s = AppSurfaces.of(context);
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final tint = enabled ? color : cs.onSurface.withValues(alpha: 0.4);

    return Semantics(
      button: true,
      enabled: enabled,
      label: semanticLabel,
      hint: semanticHint,
      onTap: enabled ? onTap : null,
      excludeSemantics: true,
      child: Pressable(
        onTap: enabled ? onTap : null,
        pressedScale: 0.92,
        borderRadius: AppRadius.large,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTokens.space1),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 64),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: circleSize,
                  height: circleSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color.alphaBlend(tint.withValues(alpha: 0.16), s.glassFillStrong),
                        Color.alphaBlend(tint.withValues(alpha: 0.06), s.glassFillStrong),
                      ],
                    ),
                    border: Border.all(color: tint.withValues(alpha: enabled ? 0.28 : 0.12)),
                    boxShadow: enabled ? AppShadows.glow(tint, strength: 0.14) : null,
                  ),
                  child: Icon(icon, size: AppTokens.iconMedium + 2, color: tint),
                ),
                const SizedBox(height: AppTokens.space1 + 2),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: t.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: enabled ? cs.onSurface : cs.onSurface.withValues(alpha: 0.4),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
