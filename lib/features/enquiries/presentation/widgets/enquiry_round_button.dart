import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../ui/primitives/primitives.dart';

/// Round frosted icon button used in the enquiry headers and action bars.
/// Passing a null [onTap] renders it dimmed and inert.
class EnquiryRoundButton extends StatelessWidget {
  const EnquiryRoundButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.iconColor,
    this.size = AppTokens.minTapTarget,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;
  final Color? iconColor;
  final double size;

  @override
  Widget build(BuildContext context) {
    final s = AppSurfaces.of(context);
    final cs = Theme.of(context).colorScheme;
    final enabled = onTap != null;

    return Tooltip(
      message: tooltip,
      child: Semantics(
        button: true,
        enabled: enabled,
        label: tooltip,
        onTap: onTap,
        excludeSemantics: true,
        child: Pressable(
          onTap: onTap,
          pressedScale: 0.9,
          borderRadius: AppRadius.full,
          child: AnimatedOpacity(
            opacity: enabled ? 1 : 0.4,
            duration: AppMotion.of(context, AppMotion.quick),
            child: SizedBox.square(
              dimension: size,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: s.glassFillStrong,
                  border: Border.all(color: s.microBorder),
                ),
                child: Icon(icon, size: AppTokens.iconMedium, color: iconColor ?? cs.onSurface),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
