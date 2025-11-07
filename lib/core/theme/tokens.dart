import 'package:flutter/material.dart';

/// Design tokens for consistent spacing, sizing, and visual elements
class AppTokens {
  // Prevent instantiation
  AppTokens._();

  // === SPACING ===
  static const double space1 = 4.0; // 0.25rem
  static const double space2 = 8.0; // 0.5rem
  static const double space3 = 12.0; // 0.75rem
  static const double space4 = 16.0; // 1rem
  static const double space5 = 20.0; // 1.25rem
  static const double space6 = 24.0; // 1.5rem
  static const double space8 = 32.0; // 2rem
  static const double space10 = 40.0; // 2.5rem
  static const double space12 = 48.0; // 3rem
  static const double space16 = 64.0; // 4rem
  static const double space20 = 80.0; // 5rem

  // === BORDER RADIUS ===
  static const double radiusSmall = 4.0;
  static const double radiusMedium = 8.0;
  static const double radiusLarge = 12.0;
  static const double radiusXLarge = 16.0;
  static const double radiusXXLarge = 24.0;
  static const double radiusFull = 9999.0;

  // === ELEVATION ===
  static const double elevation0 = 0.0;
  static const double elevation1 = 1.0;
  static const double elevation2 = 3.0;
  static const double elevation3 = 6.0;
  static const double elevation4 = 8.0;
  static const double elevation5 = 12.0;

  // === ICON SIZES ===
  static const double iconSmall = 16.0;
  static const double iconMedium = 20.0;
  static const double iconLarge = 24.0;
  static const double iconXLarge = 32.0;

  // === TYPOGRAPHY ===
  static const double fontSizeSmall = 12.0;
  static const double fontSizeBody = 14.0;
  static const double fontSizeBodyLarge = 16.0;
  static const double fontSizeTitle = 18.0;
  static const double fontSizeHeadline = 20.0;
  static const double fontSizeDisplay = 24.0;

  // === LINE HEIGHTS ===
  static const double lineHeightTight = 1.2;
  static const double lineHeightNormal = 1.4;
  static const double lineHeightRelaxed = 1.6;

  // === FONT WEIGHTS ===
  static const String fontWeightLight = '300';
  static const String fontWeightNormal = '400';
  static const String fontWeightMedium = '500';
  static const String fontWeightSemiBold = '600';
  static const String fontWeightBold = '700';

  // === MINIMUM TAP TARGETS ===
  static const double minTapTarget = 48.0;

  // === BREAKPOINTS ===
  static const double breakpointMobile = 480.0;
  static const double breakpointTablet = 768.0;
  static const double breakpointDesktop = 1024.0;

  // === ANIMATION DURATIONS ===
  static const Duration animationFast = Duration(milliseconds: 150);
  static const Duration animationNormal = Duration(milliseconds: 250);
  static const Duration animationSlow = Duration(milliseconds: 350);

  // === ANIMATION CURVES ===
  // Note: Curves cannot be const, so these are removed
}

/// Typography styles using design tokens
class AppTypography {
  AppTypography._();

  static const TextStyle displayLarge = TextStyle(
    fontSize: AppTokens.fontSizeDisplay,
    fontWeight: FontWeight.w700,
    height: AppTokens.lineHeightTight,
  );

  static const TextStyle headlineMedium = TextStyle(
    fontSize: AppTokens.fontSizeHeadline,
    fontWeight: FontWeight.w600,
    height: AppTokens.lineHeightNormal,
  );

  static const TextStyle titleLarge = TextStyle(
    fontSize: AppTokens.fontSizeTitle,
    fontWeight: FontWeight.w600,
    height: AppTokens.lineHeightNormal,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontSize: AppTokens.fontSizeBodyLarge,
    fontWeight: FontWeight.w400,
    height: AppTokens.lineHeightNormal,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: AppTokens.fontSizeBody,
    fontWeight: FontWeight.w400,
    height: AppTokens.lineHeightNormal,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: AppTokens.fontSizeSmall,
    fontWeight: FontWeight.w400,
    height: AppTokens.lineHeightNormal,
  );

  static const TextStyle labelLarge = TextStyle(
    fontSize: AppTokens.fontSizeBody,
    fontWeight: FontWeight.w500,
    height: AppTokens.lineHeightNormal,
  );

  static const TextStyle labelMedium = TextStyle(
    fontSize: AppTokens.fontSizeSmall,
    fontWeight: FontWeight.w500,
    height: AppTokens.lineHeightNormal,
  );
}

/// Spacing utilities using design tokens
class AppSpacing {
  AppSpacing._();

  /// Returns EdgeInsets with consistent spacing
  static EdgeInsets get space1 => const EdgeInsets.all(AppTokens.space1);
  static EdgeInsets get space2 => const EdgeInsets.all(AppTokens.space2);
  static EdgeInsets get space3 => const EdgeInsets.all(AppTokens.space3);
  static EdgeInsets get space4 => const EdgeInsets.all(AppTokens.space4);
  static EdgeInsets get space5 => const EdgeInsets.all(AppTokens.space5);
  static EdgeInsets get space6 => const EdgeInsets.all(AppTokens.space6);
  static EdgeInsets get space8 => const EdgeInsets.all(AppTokens.space8);

  /// Returns EdgeInsets with horizontal spacing
  static EdgeInsets horizontal(double spacing) => EdgeInsets.symmetric(horizontal: spacing);
  static EdgeInsets get horizontal2 => horizontal(AppTokens.space2);
  static EdgeInsets get horizontal4 => horizontal(AppTokens.space4);
  static EdgeInsets get horizontal6 => horizontal(AppTokens.space6);
  static EdgeInsets get horizontal8 => horizontal(AppTokens.space8);

  /// Returns EdgeInsets with vertical spacing
  static EdgeInsets vertical(double spacing) => EdgeInsets.symmetric(vertical: spacing);
  static EdgeInsets get vertical2 => vertical(AppTokens.space2);
  static EdgeInsets get vertical4 => vertical(AppTokens.space4);
  static EdgeInsets get vertical6 => vertical(AppTokens.space6);
  static EdgeInsets get vertical8 => vertical(AppTokens.space8);

  /// Returns EdgeInsets with top spacing
  static EdgeInsets top(double spacing) => EdgeInsets.only(top: spacing);
  static EdgeInsets get top2 => top(AppTokens.space2);
  static EdgeInsets get top4 => top(AppTokens.space4);
  static EdgeInsets get top6 => top(AppTokens.space6);
  static EdgeInsets get top8 => top(AppTokens.space8);

  /// Returns EdgeInsets with bottom spacing
  static EdgeInsets bottom(double spacing) => EdgeInsets.only(bottom: spacing);
  static EdgeInsets get bottom2 => bottom(AppTokens.space2);
  static EdgeInsets get bottom4 => bottom(AppTokens.space4);
  static EdgeInsets get bottom6 => bottom(AppTokens.space6);
  static EdgeInsets get bottom8 => bottom(AppTokens.space8);

  /// Returns EdgeInsets with left spacing
  static EdgeInsets left(double spacing) => EdgeInsets.only(left: spacing);
  static EdgeInsets get left2 => left(AppTokens.space2);
  static EdgeInsets get left4 => left(AppTokens.space4);
  static EdgeInsets get left6 => left(AppTokens.space6);
  static EdgeInsets get left8 => left(AppTokens.space8);

  /// Returns EdgeInsets with right spacing
  static EdgeInsets right(double spacing) => EdgeInsets.only(right: spacing);
  static EdgeInsets get right2 => right(AppTokens.space2);
  static EdgeInsets get right4 => right(AppTokens.space4);
  static EdgeInsets get right6 => right(AppTokens.space6);
  static EdgeInsets get right8 => right(AppTokens.space8);
}

/// Border radius utilities using design tokens
class AppRadius {
  AppRadius._();

  static BorderRadius get small => BorderRadius.circular(AppTokens.radiusSmall);
  static BorderRadius get medium => BorderRadius.circular(AppTokens.radiusMedium);
  static BorderRadius get large => BorderRadius.circular(AppTokens.radiusLarge);
  static BorderRadius get xLarge => BorderRadius.circular(AppTokens.radiusXLarge);
  static BorderRadius get xxLarge => BorderRadius.circular(AppTokens.radiusXXLarge);
  static BorderRadius get full => BorderRadius.circular(AppTokens.radiusFull);

  static BorderRadius only({
    double? topLeft,
    double? topRight,
    double? bottomLeft,
    double? bottomRight,
  }) {
    return BorderRadius.only(
      topLeft: Radius.circular(topLeft ?? 0),
      topRight: Radius.circular(topRight ?? 0),
      bottomLeft: Radius.circular(bottomLeft ?? 0),
      bottomRight: Radius.circular(bottomRight ?? 0),
    );
  }
}

/// Shadow utilities using design tokens
class AppShadows {
  AppShadows._();

  static List<BoxShadow> get elevation1 => [
    BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 1, offset: const Offset(0, 1)),
  ];

  static List<BoxShadow> get elevation2 => [
    BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 3, offset: const Offset(0, 2)),
  ];

  static List<BoxShadow> get elevation3 => [
    BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 6, offset: const Offset(0, 4)),
  ];

  static List<BoxShadow> get elevation4 => [
    BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 6)),
  ];

  static List<BoxShadow> get elevation5 => [
    BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 12, offset: const Offset(0, 8)),
  ];
}
