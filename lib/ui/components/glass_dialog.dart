import 'package:flutter/material.dart';

import '../../core/theme/tokens.dart';
import '../primitives/primitives.dart';
import 'tinted_icon_badge.dart';

/// Frosted dialog: optional tinted icon, eyebrow, heavy title, scrollable
/// content and right-aligned actions. Drop-in replacement for [AlertDialog].
class GlassDialog extends StatelessWidget {
  const GlassDialog({
    super.key,
    required this.content,
    this.title,
    this.eyebrow,
    this.icon,
    this.iconColor,
    this.actions = const [],
    this.maxWidth = 440,
  });

  final String? title;
  final String? eyebrow;
  final IconData? icon;
  final Color? iconColor;
  final Widget content;
  final List<Widget> actions;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    return Dialog(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(
        horizontal: AppTokens.space5,
        vertical: AppTokens.space6,
      ),
      shape: RoundedRectangleBorder(borderRadius: AppRadius.xLarge),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: GlassPanel(
          blur: true,
          strong: true,
          shadow: true,
          borderRadius: AppRadius.xLarge,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppTokens.space6,
              AppTokens.space6,
              AppTokens.space6,
              AppTokens.space4,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (icon != null) ...[
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TintedIconBadge(icon: icon!, color: iconColor, size: 48),
                  ),
                  const SizedBox(height: AppTokens.space4),
                ],
                if (eyebrow != null) ...[
                  Eyebrow(eyebrow!, accent: true),
                  const SizedBox(height: AppTokens.space1),
                ],
                if (title != null) ...[
                  Text(
                    title!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: t.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: AppTokens.space4),
                ],
                Flexible(
                  child: SingleChildScrollView(
                    child: DefaultTextStyle.merge(
                      style: t.bodyMedium?.copyWith(color: cs.onSurfaceVariant, height: 1.45),
                      child: content,
                    ),
                  ),
                ),
                if (actions.isNotEmpty) ...[
                  const SizedBox(height: AppTokens.space5),
                  OverflowBar(
                    alignment: MainAxisAlignment.end,
                    overflowAlignment: OverflowBarAlignment.end,
                    spacing: AppTokens.space2,
                    overflowSpacing: AppTokens.space2,
                    children: actions,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
