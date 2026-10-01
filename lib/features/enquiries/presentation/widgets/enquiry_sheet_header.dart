import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../ui/primitives/primitives.dart';
import 'enquiry_round_button.dart';

/// Pinned sliver for pushed enquiry screens: a frosted sheet hanging from the
/// top edge with a back button, eyebrow, large title, optional whisper line,
/// meta row and footer (e.g. contact actions). It collapses into a compact
/// glass bar showing the title beside the back button.
class EnquirySheetHeader extends StatelessWidget {
  const EnquirySheetHeader({
    super.key,
    required this.title,
    this.lightLead,
    this.eyebrow,
    this.subtitle,
    this.meta,
    this.footer,
    this.footerHeight = 0,
    this.actions = const [],
    this.tint,
  });

  final String title;

  /// Whisper-weight words shown before [title] in the expanded state.
  final String? lightLead;
  final String? eyebrow;

  /// Secondary w300 line under the title.
  final String? subtitle;
  final Widget? meta;
  final Widget? footer;

  /// Height reserved for [footer] in the expanded state.
  final double footerHeight;
  final List<Widget> actions;

  /// Faint colour wash over the sheet (e.g. the status colour).
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    final textScale = (MediaQuery.textScalerOf(context).scale(16) / 16).clamp(1.0, 2.0);
    return SliverPersistentHeader(
      pinned: true,
      delegate: _SheetHeaderDelegate(
        title: title,
        lightLead: lightLead,
        eyebrow: eyebrow,
        subtitle: subtitle,
        meta: meta,
        footer: footer,
        footerHeight: footerHeight,
        actions: actions,
        tint: tint,
        topInset: MediaQuery.paddingOf(context).top,
        textScale: textScale,
      ),
    );
  }
}

class _SheetHeaderDelegate extends SliverPersistentHeaderDelegate {
  _SheetHeaderDelegate({
    required this.title,
    required this.lightLead,
    required this.eyebrow,
    required this.subtitle,
    required this.meta,
    required this.footer,
    required this.footerHeight,
    required this.actions,
    required this.tint,
    required this.topInset,
    required this.textScale,
  });

  final String title;
  final String? lightLead;
  final String? eyebrow;
  final String? subtitle;
  final Widget? meta;
  final Widget? footer;
  final double footerHeight;
  final List<Widget> actions;
  final Color? tint;
  final double topInset;
  final double textScale;

  static const double _toolbar = 60;

  double get _bodyHeight {
    var h = AppTokens.space2;
    if (eyebrow != null) h += 15 * textScale + AppTokens.space2;
    h += 38 * textScale;
    if (subtitle != null) h += AppTokens.space1 + 23 * textScale;
    if (meta != null) h += AppTokens.space3 + 24 * textScale;
    if (footer != null) h += AppTokens.space5 + footerHeight;
    return h + AppTokens.space6;
  }

  @override
  double get minExtent => topInset + _toolbar;

  @override
  double get maxExtent => topInset + _toolbar + _bodyHeight;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final range = maxExtent - minExtent;
    final p = range <= 0 ? 1.0 : (shrinkOffset / range).clamp(0.0, 1.0);
    final bodyOpacity = (1 - p * 1.6).clamp(0.0, 1.0);
    final barTitleOpacity = ((p - 0.6) / 0.4).clamp(0.0, 1.0);
    final t = Theme.of(context).textTheme;

    return SizedBox.expand(
      child: Stack(
        children: [
          Positioned.fill(
            child: _SheetSurface(progress: p, tint: tint),
          ),
          if (bodyOpacity > 0)
            Positioned(
              top: topInset + _toolbar,
              left: AppTokens.space5,
              right: AppTokens.space5,
              bottom: 0,
              child: IgnorePointer(
                ignoring: bodyOpacity < 0.6,
                child: ClipRect(
                  child: Opacity(
                    opacity: bodyOpacity,
                    child: OverflowBox(
                      alignment: Alignment.topLeft,
                      minHeight: 0,
                      maxHeight: double.infinity,
                      child: _ExpandedBody(
                        title: title,
                        lightLead: lightLead,
                        eyebrow: eyebrow,
                        subtitle: subtitle,
                        meta: meta,
                        footer: footer,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          Positioned(
            top: topInset,
            left: AppTokens.space3,
            right: AppTokens.space3,
            height: _toolbar,
            child: Row(
              children: [
                if (Navigator.canPop(context))
                  EnquiryRoundButton(
                    icon: Icons.arrow_back_rounded,
                    tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                    onTap: () => Navigator.of(context).maybePop(),
                  ),
                const SizedBox(width: AppTokens.space3),
                Expanded(
                  child: barTitleOpacity > 0
                      ? Opacity(
                          opacity: barTitleOpacity,
                          child: Text(
                            lightLead == null ? title : '$lightLead $title',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: t.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
                for (final action in actions)
                  Padding(
                    padding: const EdgeInsets.only(left: AppTokens.space2),
                    child: action,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(_SheetHeaderDelegate old) => true;
}

class _SheetSurface extends StatelessWidget {
  const _SheetSurface({required this.progress, required this.tint});

  final double progress;
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    final s = AppSurfaces.of(context);
    final radius = BorderRadius.vertical(
      bottom: Radius.circular(AppTokens.radiusXXLarge * (1 - progress)),
    );
    final top = tint == null
        ? s.glassFillStrong
        : Color.alphaBlend(tint!.withValues(alpha: 0.10), s.glassFillStrong);

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            color: s.shadow.withValues(alpha: 0.06 * (1 - progress) + 0.02),
            blurRadius: 30,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: AppTokens.blurSigma, sigmaY: AppTokens.blurSigma),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: radius,
              border: Border.all(color: s.microBorder),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [top, s.glassFillStrong],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ExpandedBody extends StatelessWidget {
  const _ExpandedBody({
    required this.title,
    required this.lightLead,
    required this.eyebrow,
    required this.subtitle,
    required this.meta,
    required this.footer,
  });

  final String title;
  final String? lightLead;
  final String? eyebrow;
  final String? subtitle;
  final Widget? meta;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final titleStyle = t.displayMedium!.copyWith(fontWeight: FontWeight.w800);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppTokens.space2),
        if (eyebrow != null) ...[
          Eyebrow(eyebrow!, accent: true),
          const SizedBox(height: AppTokens.space2),
        ],
        if (lightLead == null)
          Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: titleStyle)
        else
          SplitHeading(light: lightLead!, bold: title, style: titleStyle, maxLines: 1),
        if (subtitle != null) ...[
          const SizedBox(height: AppTokens.space1),
          Text(
            subtitle!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: t.bodyLarge?.copyWith(fontWeight: FontWeight.w300, color: cs.onSurfaceVariant),
          ),
        ],
        if (meta != null) ...[const SizedBox(height: AppTokens.space3), meta!],
        if (footer != null) ...[const SizedBox(height: AppTokens.space5), footer!],
      ],
    );
  }
}
