import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../ui/primitives/primitives.dart';

/// Heavy month with a whisper-weight year; slides when the page turns.
class CalendarMonthTitle extends StatelessWidget {
  const CalendarMonthTitle({super.key, required this.month});

  final DateTime month;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final base = (t.headlineSmall ?? const TextStyle()).copyWith(fontSize: 24, letterSpacing: -0.6);

    return AnimatedSwitcher(
      duration: AppMotion.of(context, AppMotion.standard),
      switchInCurve: AppMotion.enter,
      switchOutCurve: AppMotion.exit,
      layoutBuilder: (current, previous) => Stack(
        alignment: AlignmentDirectional.centerStart,
        children: [...previous, if (current != null) current],
      ),
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween(begin: const Offset(0, 0.3), end: Offset.zero).animate(animation),
          child: child,
        ),
      ),
      child: Text.rich(
        key: ValueKey(DateTime(month.year, month.month)),
        TextSpan(
          children: [
            TextSpan(
              text: DateFormat('MMMM').format(month),
              style: base.copyWith(fontWeight: FontWeight.w800),
            ),
            TextSpan(
              text: ' ${month.year}',
              style: base.copyWith(fontWeight: FontWeight.w300, color: cs.onSurfaceVariant),
            ),
          ],
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class CalendarChevronButton extends StatelessWidget {
  const CalendarChevronButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = AppSurfaces.of(context);
    final cs = Theme.of(context).colorScheme;

    return Tooltip(
      message: tooltip,
      child: Pressable(
        onTap: onTap,
        pressedScale: 0.84,
        borderRadius: AppRadius.full,
        semanticLabel: tooltip,
        child: SizedBox(
          width: 44,
          height: AppTokens.minTapTarget,
          child: Center(
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: s.glassFill,
                border: Border.all(color: s.microBorder),
              ),
              child: SizedBox.square(
                dimension: 36,
                child: Icon(icon, size: AppTokens.iconMedium, color: cs.onSurface),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class CalendarFormatChip extends StatelessWidget {
  const CalendarFormatChip({super.key, required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return Pressable(
      onTap: onTap,
      pressedScale: 0.94,
      borderRadius: AppRadius.full,
      child: SizedBox(
        height: AppTokens.minTapTarget,
        child: Center(
          child: GlassPanel(
            borderRadius: AppRadius.full,
            padding: const EdgeInsets.symmetric(horizontal: AppTokens.space3, vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.unfold_less_rounded,
                  size: AppTokens.iconSmall,
                  color: cs.onSurfaceVariant,
                ),
                const SizedBox(width: AppTokens.space1),
                Text(
                  label,
                  style: t.labelMedium?.copyWith(fontWeight: FontWeight.w700, color: cs.onSurface),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class CalendarLegendItem extends StatelessWidget {
  const CalendarLegendItem({super.key, required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        StatusDot(color: color, size: 6),
        const SizedBox(width: AppTokens.space1 + 1),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }
}
