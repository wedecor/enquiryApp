import 'package:flutter/material.dart';

import 'tokens.dart';

/// Light and dark color schemes following Material 3 design
class AppColorScheme {
  AppColorScheme._();

  /// Light color scheme
  static const ColorScheme light = ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xFF2563EB), // Blue 600
    onPrimary: Color(0xFFFFFFFF), // White
    primaryContainer: Color(0xFFDBEAFE), // Blue 100
    onPrimaryContainer: Color(0xFF1E3A8A), // Blue 800
    secondary: Color(0xFF059669), // Emerald 600
    onSecondary: Color(0xFFFFFFFF), // White
    secondaryContainer: Color(0xFFD1FAE5), // Emerald 100
    onSecondaryContainer: Color(0xFF064E3B), // Emerald 800
    tertiary: Color(0xFF7C3AED), // Violet 600
    onTertiary: Color(0xFFFFFFFF), // White
    tertiaryContainer: Color(0xFFEDE9FE), // Violet 100
    onTertiaryContainer: Color(0xFF4C1D95), // Violet 800
    error: Color(0xFFDC2626), // Red 600
    onError: Color(0xFFFFFFFF), // White
    errorContainer: Color(0xFFFEE2E2), // Red 100
    onErrorContainer: Color(0xFF991B1B), // Red 800
    surface: Color(0xFFFFFFFF), // White
    onSurface: Color(0xFF111827), // Gray 900
    surfaceContainerHighest: Color(0xFFF9FAFB), // Gray 50
    onSurfaceVariant: Color(0xFF6B7280), // Gray 500
    outline: Color(0xFFD1D5DB), // Gray 300
    outlineVariant: Color(0xFFE5E7EB), // Gray 200
    shadow: Color(0xFF000000), // Black
    scrim: Color(0xFF000000), // Black
    inverseSurface: Color(0xFF111827), // Gray 900
    onInverseSurface: Color(0xFFF9FAFB), // Gray 50
    inversePrimary: Color(0xFF60A5FA), // Blue 400
    surfaceTint: Color(0xFF2563EB), // Blue 600
  );

  /// Dark color scheme
  static const ColorScheme dark = ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFF60A5FA), // Blue 400
    onPrimary: Color(0xFF000000), // Black for better contrast
    primaryContainer: Color(0xFF1E40AF), // Blue 700
    onPrimaryContainer: Color(0xFFDBEAFE), // Blue 100
    secondary: Color(0xFF34D399), // Emerald 400
    onSecondary: Color(0xFF000000), // Black for better contrast
    secondaryContainer: Color(0xFF047857), // Emerald 700
    onSecondaryContainer: Color(0xFFD1FAE5), // Emerald 100
    tertiary: Color(0xFFA78BFA), // Violet 400
    onTertiary: Color(0xFF000000), // Black for better contrast
    tertiaryContainer: Color(0xFF6D28D9), // Violet 700
    onTertiaryContainer: Color(0xFFEDE9FE), // Violet 100
    error: Color(0xFFF87171), // Red 400
    onError: Color(0xFF000000), // Black for better contrast
    errorContainer: Color(0xFFB91C1C), // Red 700
    onErrorContainer: Color(0xFFFEE2E2), // Red 100
    surface: Color(0xFF111827), // Gray 900
    onSurface: Color(0xFFF9FAFB), // Gray 50
    surfaceContainerHighest: Color(0xFF1F2937), // Gray 800
    onSurfaceVariant: Color(0xFF9CA3AF), // Gray 400
    outline: Color(0xFF4B5563), // Gray 600
    outlineVariant: Color(0xFF374151), // Gray 700
    shadow: Color(0xFF000000), // Black
    scrim: Color(0xFF000000), // Black
    inverseSurface: Color(0xFFF9FAFB), // Gray 50
    onInverseSurface: Color(0xFF111827), // Gray 900
    inversePrimary: Color(0xFF2563EB), // Blue 600
    surfaceTint: Color(0xFF60A5FA), // Blue 400
  );

  /// Additional semantic colors
  static const Color success = Color(0xFF059669); // Emerald 600
  static const Color warning = Color(0xFFD97706); // Amber 600
  static const Color info = Color(0xFF0EA5E9); // Sky 500

  /// Success colors for light theme
  static const Color successLight = Color(0xFF059669);
  static const Color onSuccessLight = Color(0xFFFFFFFF);
  static const Color successContainerLight = Color(0xFFD1FAE5);
  static const Color onSuccessContainerLight = Color(0xFF064E3B);

  /// Success colors for dark theme
  static const Color successDark = Color(0xFF34D399);
  static const Color onSuccessDark = Color(0xFF064E3B);
  static const Color successContainerDark = Color(0xFF047857);
  static const Color onSuccessContainerDark = Color(0xFFD1FAE5);

  /// Warning colors for light theme
  static const Color warningLight = Color(0xFFD97706);
  static const Color onWarningLight = Color(0xFFFFFFFF);
  static const Color warningContainerLight = Color(0xFFFEF3C7);
  static const Color onWarningContainerLight = Color(0xFF92400E);

  /// Warning colors for dark theme
  static const Color warningDark = Color(0xFFFBBF24);
  static const Color onWarningDark = Color(0xFF92400E);
  static const Color warningContainerDark = Color(0xFFB45309);
  static const Color onWarningContainerDark = Color(0xFFFEF3C7);
}

/// Theme configuration for the app
class AppTheme {
  AppTheme._();

  /// Light theme configuration
  static ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    colorScheme: AppColorScheme.light,
    brightness: Brightness.light,

    // App bar theme
    appBarTheme: AppBarTheme(
      backgroundColor: AppColorScheme.light.surface,
      foregroundColor: AppColorScheme.light.onSurface,
      elevation: AppTokens.elevation1,
      centerTitle: false,
      titleTextStyle: AppTypography.headlineMedium.copyWith(color: AppColorScheme.light.onSurface),
    ),

    // Card theme
    cardTheme: CardThemeData(
      elevation: AppTokens.elevation2,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.medium),
      color: AppColorScheme.light.surface,
      surfaceTintColor: AppColorScheme.light.surfaceTint,
    ),

    // Elevated button theme
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColorScheme.light.primary,
        foregroundColor: AppColorScheme.light.onPrimary,
        elevation: AppTokens.elevation2,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.medium),
        padding: EdgeInsets.symmetric(horizontal: AppTokens.space6, vertical: AppTokens.space3),
        textStyle: AppTypography.labelLarge,
      ),
    ),

    // Text button theme
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColorScheme.light.primary,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.medium),
        padding: EdgeInsets.symmetric(horizontal: AppTokens.space4, vertical: AppTokens.space2),
        textStyle: AppTypography.labelLarge,
      ),
    ),

    // Outlined button theme
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColorScheme.light.primary,
        side: BorderSide(color: AppColorScheme.light.outline),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.medium),
        padding: EdgeInsets.symmetric(horizontal: AppTokens.space6, vertical: AppTokens.space3),
        textStyle: AppTypography.labelLarge,
      ),
    ),

    // Input decoration theme
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColorScheme.light.surfaceContainerHighest,
      border: OutlineInputBorder(
        borderRadius: AppRadius.medium,
        borderSide: BorderSide(color: AppColorScheme.light.outline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: AppRadius.medium,
        borderSide: BorderSide(color: AppColorScheme.light.outline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: AppRadius.medium,
        borderSide: BorderSide(color: AppColorScheme.light.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: AppRadius.medium,
        borderSide: BorderSide(color: AppColorScheme.light.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: AppRadius.medium,
        borderSide: BorderSide(color: AppColorScheme.light.error, width: 2),
      ),
      contentPadding: EdgeInsets.symmetric(
        horizontal: AppTokens.space4,
        vertical: AppTokens.space3,
      ),
    ),

    // Text theme
    textTheme: TextTheme(
      displayLarge: AppTypography.displayLarge.copyWith(color: AppColorScheme.light.onSurface),
      headlineMedium: AppTypography.headlineMedium.copyWith(color: AppColorScheme.light.onSurface),
      titleLarge: AppTypography.titleLarge.copyWith(color: AppColorScheme.light.onSurface),
      bodyLarge: AppTypography.bodyLarge.copyWith(color: AppColorScheme.light.onSurface),
      bodyMedium: AppTypography.bodyMedium.copyWith(color: AppColorScheme.light.onSurface),
      bodySmall: AppTypography.bodySmall.copyWith(color: AppColorScheme.light.onSurfaceVariant),
      labelLarge: AppTypography.labelLarge.copyWith(color: AppColorScheme.light.onSurface),
      labelMedium: AppTypography.labelMedium.copyWith(color: AppColorScheme.light.onSurfaceVariant),
    ),

    // Chip theme
    chipTheme: ChipThemeData(
      backgroundColor: AppColorScheme.light.surfaceContainerHighest,
      selectedColor: AppColorScheme.light.primaryContainer,
      labelStyle: AppTypography.labelMedium.copyWith(color: AppColorScheme.light.onSurface),
      shape: RoundedRectangleBorder(borderRadius: AppRadius.full),
      padding: EdgeInsets.symmetric(horizontal: AppTokens.space3, vertical: AppTokens.space1),
    ),

    // Switch theme
    switchTheme: SwitchThemeData(
      thumbColor: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) {
          return AppColorScheme.light.primary;
        }
        return AppColorScheme.light.onSurfaceVariant;
      }),
      trackColor: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) {
          return AppColorScheme.light.primaryContainer;
        }
        return AppColorScheme.light.surfaceContainerHighest;
      }),
    ),

    // Divider theme
    dividerTheme: DividerThemeData(
      color: AppColorScheme.light.outlineVariant,
      thickness: 1,
      space: 1,
    ),
  );

  /// Dark theme configuration
  static ThemeData get darkTheme => ThemeData(
    useMaterial3: true,
    colorScheme: AppColorScheme.dark,
    brightness: Brightness.dark,

    // App bar theme
    appBarTheme: AppBarTheme(
      backgroundColor: AppColorScheme.dark.surface,
      foregroundColor: AppColorScheme.dark.onSurface,
      elevation: AppTokens.elevation1,
      centerTitle: false,
      titleTextStyle: AppTypography.headlineMedium.copyWith(color: AppColorScheme.dark.onSurface),
    ),

    // Card theme
    cardTheme: CardThemeData(
      elevation: AppTokens.elevation2,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.medium),
      color: AppColorScheme.dark.surface,
      surfaceTintColor: AppColorScheme.dark.surfaceTint,
    ),

    // Elevated button theme
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColorScheme.dark.primary,
        foregroundColor: AppColorScheme.dark.onPrimary,
        elevation: AppTokens.elevation2,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.medium),
        padding: EdgeInsets.symmetric(horizontal: AppTokens.space6, vertical: AppTokens.space3),
        textStyle: AppTypography.labelLarge,
      ),
    ),

    // Text button theme
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColorScheme.dark.primary,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.medium),
        padding: EdgeInsets.symmetric(horizontal: AppTokens.space4, vertical: AppTokens.space2),
        textStyle: AppTypography.labelLarge,
      ),
    ),

    // Outlined button theme
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColorScheme.dark.primary,
        side: BorderSide(color: AppColorScheme.dark.outline),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.medium),
        padding: EdgeInsets.symmetric(horizontal: AppTokens.space6, vertical: AppTokens.space3),
        textStyle: AppTypography.labelLarge,
      ),
    ),

    // Input decoration theme
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColorScheme.dark.surfaceContainerHighest,
      border: OutlineInputBorder(
        borderRadius: AppRadius.medium,
        borderSide: BorderSide(color: AppColorScheme.dark.outline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: AppRadius.medium,
        borderSide: BorderSide(color: AppColorScheme.dark.outline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: AppRadius.medium,
        borderSide: BorderSide(color: AppColorScheme.dark.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: AppRadius.medium,
        borderSide: BorderSide(color: AppColorScheme.dark.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: AppRadius.medium,
        borderSide: BorderSide(color: AppColorScheme.dark.error, width: 2),
      ),
      contentPadding: EdgeInsets.symmetric(
        horizontal: AppTokens.space4,
        vertical: AppTokens.space3,
      ),
    ),

    // Text theme
    textTheme: TextTheme(
      displayLarge: AppTypography.displayLarge.copyWith(color: AppColorScheme.dark.onSurface),
      headlineMedium: AppTypography.headlineMedium.copyWith(color: AppColorScheme.dark.onSurface),
      titleLarge: AppTypography.titleLarge.copyWith(color: AppColorScheme.dark.onSurface),
      bodyLarge: AppTypography.bodyLarge.copyWith(color: AppColorScheme.dark.onSurface),
      bodyMedium: AppTypography.bodyMedium.copyWith(color: AppColorScheme.dark.onSurface),
      bodySmall: AppTypography.bodySmall.copyWith(color: AppColorScheme.dark.onSurfaceVariant),
      labelLarge: AppTypography.labelLarge.copyWith(color: AppColorScheme.dark.onSurface),
      labelMedium: AppTypography.labelMedium.copyWith(color: AppColorScheme.dark.onSurfaceVariant),
    ),

    // Chip theme
    chipTheme: ChipThemeData(
      backgroundColor: AppColorScheme.dark.surfaceContainerHighest,
      selectedColor: AppColorScheme.dark.primaryContainer,
      labelStyle: AppTypography.labelMedium.copyWith(color: AppColorScheme.dark.onSurface),
      shape: RoundedRectangleBorder(borderRadius: AppRadius.full),
      padding: EdgeInsets.symmetric(horizontal: AppTokens.space3, vertical: AppTokens.space1),
    ),

    // Switch theme
    switchTheme: SwitchThemeData(
      thumbColor: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) {
          return AppColorScheme.dark.primary;
        }
        return AppColorScheme.dark.onSurfaceVariant;
      }),
      trackColor: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) {
          return AppColorScheme.dark.primaryContainer;
        }
        return AppColorScheme.dark.surfaceContainerHighest;
      }),
    ),

    // Divider theme
    dividerTheme: DividerThemeData(
      color: AppColorScheme.dark.outlineVariant,
      thickness: 1,
      space: 1,
    ),
  );
}
