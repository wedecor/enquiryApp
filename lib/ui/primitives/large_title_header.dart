import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';
import 'typography.dart';

/// Pinned sliver header with a large typographic title that collapses into a
/// compact glass bar as content scrolls under it.
///
/// ```dart
/// CustomScrollView(slivers: [
///   const LargeTitleHeader(eyebrow: 'Pipeline', title: 'Enquiries'),
///   ...
/// ])
/// ```
class LargeTitleHeader extends StatelessWidget {
  const LargeTitleHeader({
    super.key,
    required this.title,
    this.eyebrow,
    this.lightLead,
    this.actions = const [],
    this.bottom,
    this.bottomHeight = 0,
  });

  final String title;
  final String? eyebrow;

  /// Optional whisper-weight words shown before [title] when expanded.
  final String? lightLead;
  final List<Widget> actions;

  /// Optional row pinned under the title (search, segmented filters...).
  final Widget? bottom;
  final double bottomHeight;

  @override
  Widget build(BuildContext context) {
    return SliverPersistentHeader(
      pinned: true,
      delegate: _LargeTitleDelegate(
        title: title,
        eyebrow: eyebrow,
        lightLead: lightLead,
        actions: actions,
        bottom: bottom,
        bottomHeight: bottomHeight,
        topInset: MediaQuery.paddingOf(context).top,
      ),
    );
  }
}

class _LargeTitleDelegate extends SliverPersistentHeaderDelegate {
  _LargeTitleDelegate({
    required this.title,
    required this.eyebrow,
    required this.lightLead,
    required this.actions,
    required this.bottom,
    required this.bottomHeight,
    required this.topInset,
  });

  final String title;
  final String? eyebrow;
  final String? lightLead;
  final List<Widget> actions;
  final Widget? bottom;
  final double bottomHeight;
  final double topInset;

  static const double _collapsed = 60;
  static const double _expanded = 124;

  @override
  double get minExtent => topInset + _collapsed + bottomHeight;

  @override
  double get maxExtent => topInset + _expanded + bottomHeight;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final s = AppSurfaces.of(context);
    final t = Theme.of(context).textTheme;
    final range = maxExtent - minExtent;
    final p = range <= 0 ? 1.0 : (shrinkOffset / range).clamp(0.0, 1.0);
    final big = t.displayMedium!;
    final small = t.titleLarge!.copyWith(fontWeight: FontWeight.w800);
    final style = TextStyle.lerp(big, small, Curves.easeOut.transform(p))!;

    final titleWidget = lightLead == null
        ? Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: style)
        : SplitHeading(light: lightLead!, bold: title, style: style, maxLines: 1);

    final content = Padding(
      padding: EdgeInsets.only(top: topInset),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppTokens.space5,
                0,
                AppTokens.space2,
                AppTokens.space3,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (eyebrow != null && p < 0.6)
                          Opacity(
                            opacity: (1 - p / 0.6).clamp(0.0, 1.0),
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: AppTokens.space1),
                              child: Eyebrow(eyebrow!, accent: true),
                            ),
                          ),
                        titleWidget,
                      ],
                    ),
                  ),
                  ...actions,
                ],
              ),
            ),
          ),
          if (bottom != null) SizedBox(height: bottomHeight, child: bottom),
        ],
      ),
    );

    // Glass appears only once content slides underneath.
    final glassOpacity = overlapsContent || p > 0.02 ? 1.0 : 0.0;
    return AnimatedContainer(
      duration: AppMotion.quick,
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: glassOpacity > 0 ? s.microBorder : Colors.transparent),
        ),
      ),
      child: ClipRect(
        child: BackdropFilter(
          enabled: glassOpacity > 0,
          filter: ui.ImageFilter.blur(sigmaX: AppTokens.blurSigma, sigmaY: AppTokens.blurSigma),
          child: AnimatedContainer(
            duration: AppMotion.quick,
            color: glassOpacity > 0 ? s.glassFillStrong : Colors.transparent,
            child: content,
          ),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(_LargeTitleDelegate old) =>
      old.title != title ||
      old.eyebrow != eyebrow ||
      old.lightLead != lightLead ||
      old.actions != actions ||
      old.bottom != bottom ||
      old.bottomHeight != bottomHeight ||
      old.topInset != topInset;
}
