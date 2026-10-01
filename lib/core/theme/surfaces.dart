import 'package:flutter/material.dart';

/// Layered-material vocabulary that [ColorScheme] cannot express: the ambient
/// ground gradient, glass fills, hairline micro-borders and the accent sheen.
///
/// Read with `AppSurfaces.of(context)`; never hard-code these colours in widgets.
@immutable
class AppSurfaces extends ThemeExtension<AppSurfaces> {
  const AppSurfaces({
    required this.ground,
    required this.aurora,
    required this.glassFill,
    required this.glassFillStrong,
    required this.microBorder,
    required this.microBorderStrong,
    required this.edgeHighlight,
    required this.accent,
    required this.accentInk,
    required this.accentGradient,
    required this.inkGradient,
    required this.shadow,
  });

  /// Full-screen ground behind every page.
  final Gradient ground;

  /// Soft organic colour fields painted over [ground] (3 colours, already faint).
  final List<Color> aurora;

  /// Translucent panel fill used over a backdrop blur.
  final Color glassFill;

  /// Denser panel fill for nav bars and sheets that hold dense content.
  final Color glassFillStrong;

  /// 1px border at ~0.07 opacity — the default separator.
  final Color microBorder;

  /// 1px border at ~0.14 opacity — focused/selected outlines.
  final Color microBorderStrong;

  /// Top-edge light catch on glass panels.
  final Color edgeHighlight;

  /// Brand gold used for accents (dots, active states, sheen).
  final Color accent;

  /// Gold dark/light enough to be read as text on [glassFill].
  final Color accentInk;

  /// Gold sheen for the single hero call-to-action.
  final Gradient accentGradient;

  /// Charcoal/cream gradient for primary surfaces (buttons, active pills).
  final Gradient inkGradient;

  /// Colour for long, soft ambient shadows.
  final Color shadow;

  static AppSurfaces of(BuildContext context) =>
      Theme.of(context).extension<AppSurfaces>() ?? AppSurfaces.light;

  static const AppSurfaces light = AppSurfaces(
    ground: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFF8F5EF), Color(0xFFF2EDE3), Color(0xFFEDE7DC)],
      stops: [0.0, 0.55, 1.0],
    ),
    aurora: [Color(0x33D9B46E), Color(0x1FCF8A6A), Color(0x1A6E86B8)],
    glassFill: Color(0xB8FFFFFF),
    glassFillStrong: Color(0xE6FFFFFF),
    microBorder: Color(0x12161719),
    microBorderStrong: Color(0x24161719),
    edgeHighlight: Color(0x99FFFFFF),
    accent: Color(0xFFC49A4E),
    accentInk: Color(0xFF8A6420),
    accentGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFE2C383), Color(0xFFC49A4E), Color(0xFFA67C34)],
    ),
    inkGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF2A2D33), Color(0xFF16181C)],
    ),
    shadow: Color(0xFF3A2E1C),
  );

  static const AppSurfaces dark = AppSurfaces(
    ground: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF14171B), Color(0xFF101215), Color(0xFF0C0E11)],
      stops: [0.0, 0.5, 1.0],
    ),
    aurora: [Color(0x26D8B26A), Color(0x1A4E8C8C), Color(0x1A5B6FB8)],
    glassFill: Color(0x991B1E23),
    glassFillStrong: Color(0xE01A1D21),
    microBorder: Color(0x14FFFFFF),
    microBorderStrong: Color(0x29FFFFFF),
    edgeHighlight: Color(0x1FFFFFFF),
    accent: Color(0xFFD8B26A),
    accentInk: Color(0xFFE6C78A),
    accentGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFEBD09A), Color(0xFFD8B26A), Color(0xFFB8914A)],
    ),
    inkGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFF4EEE2), Color(0xFFE2D9C7)],
    ),
    shadow: Color(0xFF000000),
  );

  @override
  AppSurfaces copyWith({
    Gradient? ground,
    List<Color>? aurora,
    Color? glassFill,
    Color? glassFillStrong,
    Color? microBorder,
    Color? microBorderStrong,
    Color? edgeHighlight,
    Color? accent,
    Color? accentInk,
    Gradient? accentGradient,
    Gradient? inkGradient,
    Color? shadow,
  }) {
    return AppSurfaces(
      ground: ground ?? this.ground,
      aurora: aurora ?? this.aurora,
      glassFill: glassFill ?? this.glassFill,
      glassFillStrong: glassFillStrong ?? this.glassFillStrong,
      microBorder: microBorder ?? this.microBorder,
      microBorderStrong: microBorderStrong ?? this.microBorderStrong,
      edgeHighlight: edgeHighlight ?? this.edgeHighlight,
      accent: accent ?? this.accent,
      accentInk: accentInk ?? this.accentInk,
      accentGradient: accentGradient ?? this.accentGradient,
      inkGradient: inkGradient ?? this.inkGradient,
      shadow: shadow ?? this.shadow,
    );
  }

  @override
  AppSurfaces lerp(ThemeExtension<AppSurfaces>? other, double t) {
    if (other is! AppSurfaces) return this;
    Color c(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppSurfaces(
      ground: Gradient.lerp(ground, other.ground, t)!,
      aurora: [
        for (var i = 0; i < aurora.length && i < other.aurora.length; i++)
          c(aurora[i], other.aurora[i]),
      ],
      glassFill: c(glassFill, other.glassFill),
      glassFillStrong: c(glassFillStrong, other.glassFillStrong),
      microBorder: c(microBorder, other.microBorder),
      microBorderStrong: c(microBorderStrong, other.microBorderStrong),
      edgeHighlight: c(edgeHighlight, other.edgeHighlight),
      accent: c(accent, other.accent),
      accentInk: c(accentInk, other.accentInk),
      accentGradient: Gradient.lerp(accentGradient, other.accentGradient, t)!,
      inkGradient: Gradient.lerp(inkGradient, other.inkGradient, t)!,
      shadow: c(shadow, other.shadow),
    );
  }
}
