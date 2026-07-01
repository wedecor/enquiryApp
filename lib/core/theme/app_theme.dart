import 'package:flutter/material.dart';

import 'tokens.dart';

// Cream & terracotta palette — event decoration / hospitality brand
const Color _weDecorPrimary = Color(0xFFD4603A); // terracotta (brightened)
const Color _weDecorSecondary = Color(0xFFB07355); // warm clay
const Color _weDecorTertiary = Color(0xFF5B7553); // muted sage
const Color _weDecorBackgroundLight = Color(0xFFFBF8F3); // cream
const Color _weDecorBackgroundDark = Color(0xFF221C16); // warm dark brown
const Color _weDecorSurfaceDark = Color(0xFF2C241D); // warm dark surface

/// Light and dark color schemes following Material 3 design
class AppColorScheme {
  AppColorScheme._();

  /// Light color scheme
  static const ColorScheme light = ColorScheme(
    brightness: Brightness.light,
    primary: _weDecorPrimary,
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFFFE0D3),
    onPrimaryContainer: Color(0xFF5C1A00),
    secondary: _weDecorSecondary,
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFFF0DDD0),
    onSecondaryContainer: Color(0xFF3D2A1F),
    tertiary: _weDecorTertiary,
    onTertiary: Color(0xFFFFFFFF),
    tertiaryContainer: Color(0xFFDCE8D6),
    onTertiaryContainer: Color(0xFF1F2E1A),
    error: Color(0xFFDC2626),
    onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFFFEE2E2),
    onErrorContainer: Color(0xFF991B1B),
    surface: Color(0xFFFFFFFF),
    onSurface: Color(0xFF2C241D),
    surfaceContainerHighest: Color(0xFFF0E6DA),
    onSurfaceVariant: Color(0xFF6B5E52),
    outline: Color(0xFFD4C4B0),
    outlineVariant: Color(0xFFE8DDD0),
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
    inverseSurface: Color(0xFF2C241D),
    onInverseSurface: Color(0xFFFBF8F3),
    inversePrimary: Color(0xFFFFB69C),
    surfaceTint: _weDecorPrimary,
  );

  /// Dark color scheme
  static const ColorScheme dark = ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFFE8835C),
    onPrimary: Color(0xFF3D1400),
    primaryContainer: Color(0xFF7A3018),
    onPrimaryContainer: Color(0xFFFFD9C7),
    secondary: Color(0xFFD9A98C),
    onSecondary: Color(0xFF3D2A1F),
    secondaryContainer: Color(0xFF5C4435),
    onSecondaryContainer: Color(0xFFF0DDD0),
    tertiary: Color(0xFF8FB07F),
    onTertiary: Color(0xFF1F2E1A),
    tertiaryContainer: Color(0xFF3A4A32),
    onTertiaryContainer: Color(0xFFDCE8D6),
    error: Color(0xFFF87171),
    onError: Color(0xFF290000),
    errorContainer: Color(0xFFB91C1C),
    onErrorContainer: Color(0xFFFEE2E2),
    surface: _weDecorSurfaceDark,
    onSurface: Color(0xFFF5EDE3),
    surfaceContainerHighest: Color(0xFF3D3530),
    onSurfaceVariant: Color(0xFFC4B5A5),
    outline: Color(0xFF6B5E52),
    outlineVariant: Color(0xFF4A4038),
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
    inverseSurface: Color(0xFFF5EDE3),
    onInverseSurface: Color(0xFF2C241D),
    inversePrimary: _weDecorPrimary,
    surfaceTint: Color(0xFFE8835C),
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

  // Contact actions and data visualization (fixed brand-adjacent hues)
  static const Color whatsApp = Color(0xFF25D366);
  static const Color phoneCall = Color(0xFF1E88E5);
  static const Color chartBlue = Color(0xFF2563EB);
  static const Color chartGreen = Color(0xFF059669);
  static const Color chartAmber = Color(0xFFF59E0B);
  static const Color chartRed = Color(0xFFDC2626);
  static const Color chartPurple = Color(0xFF7C3AED);
  static const Color chartCyan = Color(0xFF0891B2);
  static const Color chartOrange = Color(0xFFEA580C);
  static const Color chartEmerald = Color(0xFF22C55E);
  static const Color chartIndigo = Color(0xFF7AA2FF);
  static const Color eventHaldi = Color(0xFFF4B400);
  static const Color eventEngagement = Color(0xFFFF6B6B);
  static const Color eventWedding = Color(0xFF8B5CF6);
  static const Color eventBirthday = Color(0xFF06B6D4);
  static const Color neutralGrey = Color(0xFF757575);

  /// Enquiry pipeline status colors (calendar, chips — distinct from primary gold)
  static const Color statusNew = Color(0xFF2563EB);
  static const Color statusInTalks = Color(0xFFD97706);
  static const Color statusQuoteSent = Color(0xFF7C3AED);
  static const Color statusConfirmed = Color(0xFF059669);
  static const Color statusCompleted = Color(0xFF0891B2);

  /// SnackBar / inline feedback (semantic — distinct from brand gold primary)
  static const Color snackSuccess = success;
  static const Color snackError = Color(0xFFDC2626);
  static const Color snackWarning = warning;

  static Color statusColorFor(String? status) {
    switch ((status ?? '').toLowerCase().replaceAll(' ', '_')) {
      case 'new':
        return statusNew;
      case 'in_talks':
        return statusInTalks;
      case 'quote_sent':
        return statusQuoteSent;
      case 'confirmed':
      case 'approved':
      case 'scheduled':
        return statusConfirmed;
      case 'completed':
        return statusCompleted;
      case 'cancelled':
      case 'not_interested':
      case 'closed_lost':
        return chartRed;
      default:
        return neutralGrey;
    }
  }

  static const List<Color> chartPalette = [
    chartBlue,
    chartGreen,
    chartAmber,
    chartRed,
    chartPurple,
    chartCyan,
    chartOrange,
    chartEmerald,
  ];
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

    // App bar theme — white surface bar, terracotta accent via icons/FAB
    appBarTheme: AppBarTheme(
      backgroundColor: AppColorScheme.light.surface,
      foregroundColor: AppColorScheme.light.onSurface,
      elevation: 0,
      scrolledUnderElevation: 1,
      shadowColor: AppColorScheme.light.shadow.withValues(alpha: 0.08),
      surfaceTintColor: Colors.transparent,
      centerTitle: false,
      titleTextStyle: AppTypography.headlineMedium.copyWith(
        color: AppColorScheme.light.onSurface,
        fontWeight: FontWeight.w700,
      ),
      iconTheme: IconThemeData(color: AppColorScheme.light.onSurface),
      actionsIconTheme: IconThemeData(color: AppColorScheme.light.onSurface),
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
        padding: const EdgeInsets.symmetric(
          horizontal: AppTokens.space6,
          vertical: AppTokens.space3,
        ),
        textStyle: AppTypography.labelLarge,
      ),
    ),

    // Text button theme
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColorScheme.light.primary,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.medium),
        padding: const EdgeInsets.symmetric(
          horizontal: AppTokens.space4,
          vertical: AppTokens.space2,
        ),
        textStyle: AppTypography.labelLarge,
      ),
    ),

    // Outlined button theme
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColorScheme.light.primary,
        side: BorderSide(color: AppColorScheme.light.primary.withValues(alpha: 0.4)),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.medium),
        padding: const EdgeInsets.symmetric(
          horizontal: AppTokens.space6,
          vertical: AppTokens.space3,
        ),
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

    // App bar theme — surface bar matches dark background
    appBarTheme: AppBarTheme(
      backgroundColor: AppColorScheme.dark.surface,
      foregroundColor: AppColorScheme.dark.onSurface,
      elevation: 0,
      scrolledUnderElevation: 1,
      shadowColor: Colors.black.withValues(alpha: 0.3),
      surfaceTintColor: Colors.transparent,
      centerTitle: false,
      titleTextStyle: AppTypography.headlineMedium.copyWith(
        color: AppColorScheme.dark.onSurface,
        fontWeight: FontWeight.w700,
      ),
      iconTheme: IconThemeData(color: AppColorScheme.dark.onSurface),
      actionsIconTheme: IconThemeData(color: AppColorScheme.dark.onSurface),
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
        padding: const EdgeInsets.symmetric(
          horizontal: AppTokens.space6,
          vertical: AppTokens.space3,
        ),
        textStyle: AppTypography.labelLarge,
      ),
    ),

    // Text button theme
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColorScheme.dark.primary,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.medium),
        padding: const EdgeInsets.symmetric(
          horizontal: AppTokens.space4,
          vertical: AppTokens.space2,
        ),
        textStyle: AppTypography.labelLarge,
      ),
    ),

    // Outlined button theme
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColorScheme.dark.primary,
        side: BorderSide(color: AppColorScheme.dark.primary.withValues(alpha: 0.4)),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.medium),
        padding: const EdgeInsets.symmetric(
          horizontal: AppTokens.space6,
          vertical: AppTokens.space3,
        ),
        textStyle: AppTypography.labelLarge,
      ),
    ),

    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: AppColorScheme.dark.primary,
      foregroundColor: AppColorScheme.dark.onPrimary,
      elevation: AppTokens.elevation2,
    ),

    tabBarTheme: TabBarThemeData(
      labelColor: AppColorScheme.dark.primary,
      unselectedLabelColor: AppColorScheme.dark.onSurfaceVariant,
      indicatorColor: AppColorScheme.dark.primary,
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
