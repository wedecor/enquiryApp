import 'package:flutter/material.dart';

import 'tokens.dart';

const Color _weDecorPrimary = Color(0xFF00B4D8);
const Color _weDecorPrimaryDark = Color(0xFF0077B6);
const Color _weDecorSecondary = Color(0xFF90E0EF);
const Color _weDecorBackgroundLight = Color(0xFFF8FAFC);
const Color _weDecorBackgroundDark = Color(0xFF0F172A);
const Color _weDecorSurfaceDark = Color(0xFF1E293B);

/// Light and dark color schemes following Material 3 design
class AppColorScheme {
  AppColorScheme._();

  /// Light color scheme
  static const ColorScheme light = ColorScheme(
    brightness: Brightness.light,
    primary: _weDecorPrimary,
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFBFEFFF),
    onPrimaryContainer: Color(0xFF003547),
    secondary: _weDecorSecondary,
    onSecondary: Color(0xFF002B3D),
    secondaryContainer: Color(0xFFDFF6FB),
    onSecondaryContainer: Color(0xFF003547),
    tertiary: Color(0xFF0077B6),
    onTertiary: Color(0xFFFFFFFF),
    tertiaryContainer: Color(0xFFE0F4FF),
    onTertiaryContainer: Color(0xFF002D44),
    error: Color(0xFFDC2626),
    onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFFFEE2E2),
    onErrorContainer: Color(0xFF991B1B),
    surface: Color(0xFFFFFFFF),
    onSurface: Color(0xFF0F172A),
    surfaceContainerHighest: Color(0xFFF1F5F9),
    onSurfaceVariant: Color(0xFF475569),
    outline: Color(0xFFCBD5E1),
    outlineVariant: Color(0xFFE2E8F0),
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
    inverseSurface: Color(0xFF0F172A),
    onInverseSurface: Color(0xFFF8FAFC),
    inversePrimary: _weDecorPrimaryDark,
    surfaceTint: _weDecorPrimary,
  );

  /// Dark color scheme
  static const ColorScheme dark = ColorScheme(
    brightness: Brightness.dark,
    primary: _weDecorPrimaryDark,
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFF004A73),
    onPrimaryContainer: Color(0xFFBFEFFF),
    secondary: _weDecorSecondary,
    onSecondary: Color(0xFF0F172A),
    secondaryContainer: Color(0xFF1A5D76),
    onSecondaryContainer: Color(0xFFE2F6FF),
    tertiary: _weDecorPrimary,
    onTertiary: Color(0xFF002D44),
    tertiaryContainer: Color(0xFF134A62),
    onTertiaryContainer: Color(0xFFE0F4FF),
    error: Color(0xFFF87171),
    onError: Color(0xFF290000),
    errorContainer: Color(0xFFB91C1C),
    onErrorContainer: Color(0xFFFEE2E2),
    surface: _weDecorSurfaceDark,
    onSurface: Color(0xFFE2E8F0),
    surfaceContainerHighest: Color(0xFF243047),
    onSurfaceVariant: Color(0xFFA0AEC0),
    outline: Color(0xFF4B5563),
    outlineVariant: Color(0xFF374151),
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
    inverseSurface: Color(0xFFE2E8F0),
    onInverseSurface: Color(0xFF0F172A),
    inversePrimary: _weDecorPrimary,
    surfaceTint: _weDecorPrimaryDark,
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
    scaffoldBackgroundColor: _weDecorBackgroundLight,

    // App bar theme
    appBarTheme: AppBarTheme(
      backgroundColor: AppColorScheme.light.primary,
      foregroundColor: AppColorScheme.light.onPrimary,
      elevation: AppTokens.elevation1,
      centerTitle: false,
      titleTextStyle: AppTypography.headlineMedium.copyWith(color: AppColorScheme.light.onPrimary),
    ),

    // Card theme
    cardTheme: CardThemeData(
      elevation: AppTokens.elevation2,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.medium),
      color: AppColorScheme.light.surface,
      surfaceTintColor: Colors.transparent,
    ),

    // Elevated button theme
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColorScheme.light.primary,
        foregroundColor: AppColorScheme.light.onPrimary,
        elevation: AppTokens.elevation2,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.medium),
        padding: const EdgeInsets.symmetric(horizontal: AppTokens.space6, vertical: AppTokens.space3),
        textStyle: AppTypography.labelLarge,
      ),
    ),

    // Text button theme
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColorScheme.light.primary,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.medium),
        padding: const EdgeInsets.symmetric(horizontal: AppTokens.space4, vertical: AppTokens.space2),
        textStyle: AppTypography.labelLarge,
      ),
    ),

    // Outlined button theme
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColorScheme.light.primary,
        side: BorderSide(color: AppColorScheme.light.primary.withValues(alpha: 0.4)),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.medium),
        padding: const EdgeInsets.symmetric(horizontal: AppTokens.space6, vertical: AppTokens.space3),
        textStyle: AppTypography.labelLarge,
      ),
    ),

    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: AppColorScheme.light.primary,
      foregroundColor: AppColorScheme.light.onPrimary,
      elevation: AppTokens.elevation2,
    ),

    tabBarTheme: TabBarThemeData(
      labelColor: AppColorScheme.light.primary,
      unselectedLabelColor: AppColorScheme.light.onSurfaceVariant,
      indicatorColor: AppColorScheme.light.primary,
      indicatorSize: TabBarIndicatorSize.label,
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
      contentPadding: const EdgeInsets.symmetric(
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
      padding: const EdgeInsets.symmetric(horizontal: AppTokens.space3, vertical: AppTokens.space1),
    ),

    // Switch theme
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return AppColorScheme.light.primary;
        }
        return AppColorScheme.light.onSurfaceVariant;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
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
    scaffoldBackgroundColor: _weDecorBackgroundDark,

    // App bar theme
    appBarTheme: AppBarTheme(
      backgroundColor: AppColorScheme.dark.primary,
      foregroundColor: AppColorScheme.dark.onPrimary,
      elevation: AppTokens.elevation1,
      centerTitle: false,
      titleTextStyle: AppTypography.headlineMedium.copyWith(color: AppColorScheme.dark.onPrimary),
    ),

    // Card theme
    cardTheme: CardThemeData(
      elevation: AppTokens.elevation2,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.medium),
      color: AppColorScheme.dark.surface,
      surfaceTintColor: Colors.transparent,
    ),

    // Elevated button theme
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColorScheme.dark.primary,
        foregroundColor: AppColorScheme.dark.onPrimary,
        elevation: AppTokens.elevation2,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.medium),
        padding: const EdgeInsets.symmetric(horizontal: AppTokens.space6, vertical: AppTokens.space3),
        textStyle: AppTypography.labelLarge,
      ),
    ),

    // Text button theme
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColorScheme.dark.primary,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.medium),
        padding: const EdgeInsets.symmetric(horizontal: AppTokens.space4, vertical: AppTokens.space2),
        textStyle: AppTypography.labelLarge,
      ),
    ),

    // Outlined button theme
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColorScheme.dark.primary,
        side: BorderSide(color: AppColorScheme.dark.primary.withValues(alpha: 0.4)),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.medium),
        padding: const EdgeInsets.symmetric(horizontal: AppTokens.space6, vertical: AppTokens.space3),
        textStyle: AppTypography.labelLarge,
      ),
    ),

    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: AppColorScheme.dark.primary,
      foregroundColor: AppColorScheme.dark.onPrimary,
      elevation: AppTokens.elevation2,
    ),

    tabBarTheme: TabBarThemeData(
      labelColor: AppColorScheme.dark.secondary,
      unselectedLabelColor: AppColorScheme.dark.onSurfaceVariant,
      indicatorColor: AppColorScheme.dark.secondary,
      indicatorSize: TabBarIndicatorSize.label,
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
      contentPadding: const EdgeInsets.symmetric(
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
      padding: const EdgeInsets.symmetric(horizontal: AppTokens.space3, vertical: AppTokens.space1),
    ),

    // Switch theme
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return AppColorScheme.dark.primary;
        }
        return AppColorScheme.dark.onSurfaceVariant;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
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
