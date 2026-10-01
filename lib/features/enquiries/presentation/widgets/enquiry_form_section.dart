import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../ui/primitives/primitives.dart';

/// Extra bottom scroll padding for form fields so a focused field is scrolled
/// clear of the floating glass action bar.
const EdgeInsets kEnquiryFieldScrollPadding = EdgeInsets.fromLTRB(20, 20, 20, 140);

/// Vertical gap between stacked fields inside a form section.
const double kEnquiryFieldGap = AppTokens.space4;

/// Frosted glass panel for one enquiry form section: a tracked eyebrow, then
/// the [title] as a split heading (whisper lead, heavy last word).
class EnquiryFormSection extends StatelessWidget {
  const EnquiryFormSection({
    super.key,
    required this.title,
    required this.children,
    this.eyebrow,
    this.eyebrowIcon,
  });

  final String title;
  final List<Widget> children;
  final String? eyebrow;
  final IconData? eyebrowIcon;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final s = AppSurfaces.of(context);
    final split = title.lastIndexOf(' ');
    final style = t.headlineSmall;

    return Padding(
      padding: AppSpacing.bottom(AppTokens.space3),
      child: GlassPanel(
        borderRadius: AppRadius.xLarge,
        padding: const EdgeInsets.all(AppTokens.space5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (eyebrow != null) ...[
              Row(
                children: [
                  if (eyebrowIcon != null) ...[
                    Icon(eyebrowIcon, size: AppTokens.iconSmall - 2, color: s.accentInk),
                    const SizedBox(width: AppTokens.space1),
                  ],
                  Flexible(child: Eyebrow(eyebrow!, accent: true)),
                ],
              ),
              const SizedBox(height: AppTokens.space1),
            ],
            if (split <= 0)
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: style?.copyWith(fontWeight: FontWeight.w800),
              )
            else
              SplitHeading(
                light: title.substring(0, split),
                bold: title.substring(split + 1),
                style: style,
              ),
            const SizedBox(height: AppTokens.space5),
            ...children,
          ],
        ),
      ),
    );
  }
}

/// Two fields side by side when there is room, stacked otherwise.
class EnquiryFieldPair extends StatelessWidget {
  const EnquiryFieldPair({super.key, required this.first, required this.second});

  final Widget first;
  final Widget second;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        if (box.maxWidth < 440) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              first,
              const SizedBox(height: kEnquiryFieldGap),
              second,
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: first),
            const SizedBox(width: AppTokens.space3),
            Expanded(child: second),
          ],
        );
      },
    );
  }
}
