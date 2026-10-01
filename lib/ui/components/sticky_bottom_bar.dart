import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';

/// Pinned bottom action area (detail/form screens): frosted glass that lets
/// content blur through, separated from the page by a 1px micro-border.
class StickyBottomBar extends StatelessWidget {
  const StickyBottomBar({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final s = AppSurfaces.of(context);
    // Always span the full width, even inside a Column with centred children,
    // so the bar reads as a bar and the action stretches edge to edge.
    return SizedBox(
      width: double.infinity,
      child: ClipRect(
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: AppTokens.blurSigma, sigmaY: AppTokens.blurSigma),
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color.alphaBlend(s.edgeHighlight.withValues(alpha: 0.25), s.glassFillStrong),
                  s.glassFillStrong,
                ],
              ),
              border: Border(top: BorderSide(color: s.microBorder)),
            ),
            child: Material(
              type: MaterialType.transparency,
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppTokens.space4,
                    AppTokens.space3,
                    AppTokens.space4,
                    AppTokens.space3,
                  ),
                  child: SizedBox(width: double.infinity, child: child),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
