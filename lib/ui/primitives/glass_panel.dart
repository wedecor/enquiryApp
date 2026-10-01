import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';

/// Layered translucent surface: optional backdrop blur, a faint top-down sheen
/// and a 1px micro-border. The app's replacement for [Card].
///
/// Blur is expensive; keep [blur] for a few large surfaces per screen (nav bar,
/// headers, sheets). List items should use the default `blur: false`.
class GlassPanel extends StatelessWidget {
  const GlassPanel({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius,
    this.blur = false,
    this.strong = false,
    this.tint,
    this.gradient,
    this.borderColor,
    this.shadow = false,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;
  final bool blur;

  /// Denser fill for content-heavy surfaces.
  final bool strong;

  /// Faint colour wash over the glass (e.g. a status colour at low alpha).
  final Color? tint;

  /// Replaces the default glass sheen entirely.
  final Gradient? gradient;
  final Color? borderColor;

  /// Long, soft ambient shadow under the panel.
  final bool shadow;

  @override
  Widget build(BuildContext context) {
    final s = AppSurfaces.of(context);
    final radius = borderRadius ?? AppRadius.large;
    final fill = strong ? s.glassFillStrong : s.glassFill;

    final sheen =
        gradient ??
        LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color.alphaBlend(s.edgeHighlight.withValues(alpha: 0.35), fill),
            fill,
            if (tint != null) Color.alphaBlend(tint!, fill) else fill,
          ],
          stops: const [0.0, 0.35, 1.0],
        );

    Widget body = DecoratedBox(
      decoration: BoxDecoration(
        gradient: sheen,
        borderRadius: radius,
        border: Border.all(color: borderColor ?? s.microBorder, width: AppTokens.microBorderWidth),
      ),
      child: padding == null ? child : Padding(padding: padding!, child: child),
    );

    if (blur) {
      body = ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: AppTokens.blurSigma, sigmaY: AppTokens.blurSigma),
          child: body,
        ),
      );
    }

    if (shadow) {
      body = DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: radius,
          boxShadow: [
            BoxShadow(
              color: s.shadow.withValues(alpha: 0.07),
              blurRadius: 30,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: body,
      );
    }
    return body;
  }
}
