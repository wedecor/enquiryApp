import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../ui/primitives/primitives.dart';

/// Glass filter pill. Selecting it morphs the fill to solid ink with a gold
/// dot that slides in; [onDeleted] turns it into a removable "active filter"
/// pill (the whole pill removes, the close glyph is the affordance).
class FilterPill extends StatelessWidget {
  const FilterPill({
    super.key,
    required this.label,
    this.selected = false,
    this.icon,
    this.onTap,
    this.onDeleted,
    this.tooltip,
  });

  final String label;
  final bool selected;
  final IconData? icon;
  final VoidCallback? onTap;
  final VoidCallback? onDeleted;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final s = AppSurfaces.of(context);
    final duration = AppMotion.of(context, AppMotion.standard);
    final fg = selected ? cs.surface : cs.onSurface;

    Widget pill = Pressable(
      onTap: onTap ?? onDeleted,
      borderRadius: AppRadius.full,
      pressedScale: 0.94,
      child: Padding(
        // 40px pill inside a 48px tap target.
        padding: const EdgeInsets.symmetric(vertical: AppTokens.space1),
        child: AnimatedContainer(
          duration: duration,
          curve: AppMotion.standardCurve,
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: selected ? cs.onSurface : s.glassFillStrong,
            borderRadius: AppRadius.full,
            border: Border.all(color: selected ? cs.onSurface : s.microBorderStrong),
            boxShadow: selected ? AppShadows.glow(s.shadow, strength: 0.14) : const [],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedSize(
                duration: duration,
                curve: AppMotion.standardCurve,
                child: selected
                    ? Padding(
                        padding: const EdgeInsets.only(right: AppTokens.space2),
                        child: StatusDot(color: s.accent, size: 6),
                      )
                    : const SizedBox.shrink(),
              ),
              if (icon != null) ...[Icon(icon, size: 16, color: fg), const SizedBox(width: 6)],
              AnimatedDefaultTextStyle(
                duration: duration,
                style: theme.textTheme.labelLarge!.copyWith(
                  color: fg,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                ),
                child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
              if (onDeleted != null) ...[
                const SizedBox(width: 6),
                Icon(Icons.close_rounded, size: 14, color: fg.withValues(alpha: 0.7)),
              ],
            ],
          ),
        ),
      ),
    );

    pill = Semantics(selected: selected, button: true, label: tooltip, child: pill);
    if (tooltip != null) pill = Tooltip(message: tooltip!, child: pill);
    return pill;
  }
}
