import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../ui/primitives/primitives.dart';

/// Read-only status: glass pill with a coloured dot.
class EnquiryStatusChip extends StatelessWidget {
  const EnquiryStatusChip({super.key, required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final s = AppSurfaces.of(context);
    final t = Theme.of(context).textTheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Color.alphaBlend(color.withValues(alpha: 0.10), s.glassFillStrong),
        borderRadius: AppRadius.full,
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTokens.space3,
          vertical: AppTokens.space1 + 2,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            StatusDot(color: color),
            const SizedBox(width: AppTokens.space2),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: t.labelLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Glass pill that hosts the compact status dropdown.
class EnquiryStatusPill extends StatelessWidget {
  const EnquiryStatusPill({super.key, required this.color, required this.child});

  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final s = AppSurfaces.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: s.glassFillStrong,
        borderRadius: AppRadius.full,
        border: Border.all(color: color.withValues(alpha: 0.32)),
      ),
      child: Padding(
        padding: const EdgeInsets.only(left: AppTokens.space3, right: AppTokens.space2),
        child: child,
      ),
    );
  }
}

/// Dot + label used inside dropdown items.
class EnquiryStatusLabel extends StatelessWidget {
  const EnquiryStatusLabel({super.key, required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        StatusDot(color: color, size: 7),
        const SizedBox(width: AppTokens.space2),
        Flexible(child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis)),
      ],
    );
  }
}

/// One selectable row in the expanded status list; the selected row gains a
/// gold outline, wash and check.
class EnquiryStatusOption extends StatelessWidget {
  const EnquiryStatusOption({
    super.key,
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final Color color;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final s = AppSurfaces.of(context);
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final duration = AppMotion.of(context, AppMotion.standard);

    return Semantics(
      selected: selected,
      child: Pressable(
        onTap: onTap,
        borderRadius: AppRadius.large,
        child: AnimatedContainer(
          duration: duration,
          curve: AppMotion.standardCurve,
          constraints: const BoxConstraints(minHeight: 56),
          padding: const EdgeInsets.symmetric(horizontal: AppTokens.space4),
          decoration: BoxDecoration(
            borderRadius: AppRadius.large,
            color: selected
                ? Color.alphaBlend(s.accent.withValues(alpha: 0.12), s.glassFillStrong)
                : s.glassFill,
            border: Border.all(
              color: selected ? s.accent.withValues(alpha: 0.7) : s.microBorder,
              width: selected ? 1.4 : 1,
            ),
            boxShadow: selected ? AppShadows.glow(s.accent, strength: 0.14) : null,
          ),
          child: Row(
            children: [
              StatusDot(color: color, size: 10, pulse: selected),
              const SizedBox(width: AppTokens.space3),
              Expanded(
                child: AnimatedDefaultTextStyle(
                  duration: duration,
                  style: (t.bodyLarge ?? const TextStyle()).copyWith(
                    color: cs.onSurface,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w400,
                  ),
                  child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
              ),
              AnimatedScale(
                scale: selected ? 1 : 0,
                duration: duration,
                curve: AppMotion.springOut,
                child: Icon(
                  Icons.check_circle_rounded,
                  color: s.accent,
                  size: AppTokens.iconMedium,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
