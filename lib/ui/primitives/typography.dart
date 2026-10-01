import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';

/// Tracked uppercase micro-label ("EYEBROW") placed above headings and numbers.
class Eyebrow extends StatelessWidget {
  const Eyebrow(this.text, {super.key, this.color, this.accent = false});

  final String text;
  final Color? color;

  /// Use the gold accent ink instead of the muted variant colour.
  final bool accent;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final s = AppSurfaces.of(context);
    return Text(
      text.toUpperCase(),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: Theme.of(context).textTheme.labelSmall
          ?.merge(AppTypography.eyebrow)
          .copyWith(color: color ?? (accent ? s.accentInk : cs.onSurfaceVariant)),
    );
  }
}

/// Heading that pairs a whisper-weight lead with a heavy keyword:
/// `SplitHeading(light: 'Good evening,', bold: 'Ilyas')`.
class SplitHeading extends StatelessWidget {
  const SplitHeading({
    super.key,
    required this.light,
    required this.bold,
    this.style,
    this.stacked = false,
    this.maxLines = 2,
  });

  final String light;
  final String bold;
  final TextStyle? style;

  /// Put the bold word on its own line.
  final bool stacked;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    final base = style ?? Theme.of(context).textTheme.headlineMedium!;
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: stacked ? '$light\n' : '$light ',
            style: base.copyWith(fontWeight: FontWeight.w300),
          ),
          TextSpan(
            text: bold,
            style: base.copyWith(fontWeight: FontWeight.w800),
          ),
        ],
      ),
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
    );
  }
}

/// Section header: eyebrow, title and an optional trailing action, separated
/// from content by space rather than a box.
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.eyebrow,
    this.trailing,
    this.padding = const EdgeInsets.fromLTRB(
      AppTokens.space5,
      AppTokens.space6,
      AppTokens.space5,
      AppTokens.space3,
    ),
  });

  final String title;
  final String? eyebrow;
  final Widget? trailing;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (eyebrow != null) ...[
                  Eyebrow(eyebrow!),
                  const SizedBox(height: AppTokens.space1),
                ],
                Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: t.titleLarge),
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}
