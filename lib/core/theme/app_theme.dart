import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/status_vocabulary.dart';
import 'tokens.dart';

// We Decor brand palette (from the brand toolkit: logo recolour, cards, letterhead).
// Neutral-led: charcoal ink + cream ground, slate for secondary text, and ONE
// restrained gold accent for emphasis/links/selection — never for large fills.
const Color _brandCharcoal = Color(0xFF23262B);
const Color _brandCream = Color(0xFFEFE9DB);
const Color _brandSlate = Color(0xFF6E7377);
const Color _brandGold = Color(0xFFC6A15B);

// Light-mode gold darkened for text/icon contrast on white (6.2:1).
const Color _brandGoldInk = Color(0xFF7A5C22);

const Color _weDecorBackgroundLight = Color(0xFFF7F4EC); // warm off-white ground
const Color _weDecorBackgroundDark = Color(0xFF17191C); // deep charcoal base
const Color _weDecorSurfaceDark = Color(0xFF1E2125); // elevated surface
const Color _weDecorSurfaceCardDark = Color(0xFF26292E); // cards / list rows

/// Light and dark color schemes following Material 3 design
class AppColorScheme {
  AppColorScheme._();

  /// The single brand accent. Change this one value to re-tint emphasis app-wide.
  static const Color accent = _brandGold;

  /// Brand neutrals, exposed for logo/brand-mark rendering only.
  static const Color brandCharcoal = _brandCharcoal;
  static const Color brandCream = _brandCream;
  static const Color brandSlate = _brandSlate;

  /// Light color scheme — charcoal ink on warm off-white, gold accent.
  static const ColorScheme light = ColorScheme(
    brightness: Brightness.light,
    primary: _brandCharcoal,
    onPrimary: Color(0xFFFBF8F1),
    primaryContainer: Color(0xFFE7E2D7),
    onPrimaryContainer: _brandCharcoal,
    secondary: Color(0xFF5E6367), // slate, deepened for AA text contrast
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFFECE6D8),
    onSecondaryContainer: Color(0xFF2E3236),
    tertiary: _brandGoldInk,
    onTertiary: Color(0xFFFFFFFF),
    tertiaryContainer: Color(0xFFF3E7CC),
    onTertiaryContainer: Color(0xFF3A2A0B),
    error: Color(0xFFB3261E),
    onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFFF9DEDC),
    onErrorContainer: Color(0xFF410E0B),
    surface: Color(0xFFFFFFFF),
    onSurface: Color(0xFF1F2124),
    surfaceContainerLowest: Color(0xFFFFFFFF),
    surfaceContainerLow: Color(0xFFFBF9F4),
    surfaceContainer: Color(0xFFF5F2EA),
    surfaceContainerHigh: Color(0xFFF2EEE4),
    surfaceContainerHighest: _brandCream,
    onSurfaceVariant: Color(0xFF5F6368),
    outline: Color(0xFFC9C3B6),
    outlineVariant: Color(0xFFE4DFD3),
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
    inverseSurface: _brandCharcoal,
    onInverseSurface: _brandCream,
    inversePrimary: _brandCream,
    surfaceTint: Color(0x00000000),
  );

  /// Dark color scheme — charcoal base, cream ink, gold accent.
  static const ColorScheme dark = ColorScheme(
    brightness: Brightness.dark,
    primary: _brandCream,
    onPrimary: _brandCharcoal,
    primaryContainer: Color(0xFF3A3D42),
    onPrimaryContainer: _brandCream,
    secondary: Color(0xFFB4B9BD),
    onSecondary: _brandCharcoal,
    secondaryContainer: Color(0xFF34373C),
    onSecondaryContainer: Color(0xFFE2E3E4),
    tertiary: _brandGold,
    onTertiary: Color(0xFF2A1F08),
    tertiaryContainer: Color(0xFF4A3B1C),
    onTertiaryContainer: Color(0xFFF3E3BF),
    error: Color(0xFFF2B8B5),
    onError: Color(0xFF601410),
    errorContainer: Color(0xFF8C1D18),
    onErrorContainer: Color(0xFFF9DEDC),
    surface: _weDecorSurfaceDark,
    onSurface: Color(0xFFECE8DF),
    surfaceContainerLowest: Color(0xFF141619),
    surfaceContainerLow: Color(0xFF1B1E21),
    surfaceContainer: Color(0xFF212428),
    surfaceContainerHigh: _weDecorSurfaceCardDark,
    surfaceContainerHighest: Color(0xFF2E3136),
    onSurfaceVariant: Color(0xFFA9ADB1),
    outline: Color(0xFF5A5E63),
    outlineVariant: Color(0xFF383B40),
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
    inverseSurface: Color(0xFFECE8DF),
    onInverseSurface: _brandCharcoal,
    inversePrimary: _brandCharcoal,
    surfaceTint: Color(0x00000000),
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

  /// Enquiry pipeline status colors (calendar, chips — distinct from brand neutrals and gold accent)
  static const Color statusNew = Color(0xFF2563EB);
  static const Color statusInTalks = Color(0xFFD97706);
  static const Color statusQuoteSent = Color(0xFF7C3AED);
  static const Color statusConfirmed = Color(0xFF059669);
  static const Color statusCompleted = Color(0xFF0891B2);

  /// SnackBar / inline feedback (semantic — distinct from brand neutrals and gold accent)
  static const Color snackSuccess = success;
  static const Color snackError = Color(0xFFDC2626);
  static const Color snackWarning = warning;

  static Color statusColorFor(String? status) {
    final canonical =
        EnquiryStatus.fromValue(status)?.value ?? (status ?? '').toLowerCase().replaceAll(' ', '_');
    switch (canonical) {
      case 'new':
        return statusNew;
      case 'in_talks':
        return statusInTalks;
      case 'approved':
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

  static TextTheme _brandTextTheme(TextTheme base, ColorScheme scheme) {
    final dmSans = GoogleFonts.dmSansTextTheme(base);
    TextStyle outfit(TextStyle? style, {FontWeight? weight}) => GoogleFonts.outfit(
      textStyle: style,
      fontWeight: weight ?? style?.fontWeight,
      color: style?.color ?? scheme.onSurface,
    );

    return dmSans.copyWith(
      displayLarge: outfit(base.displayLarge, weight: FontWeight.w600),
      headlineMedium: outfit(base.headlineMedium, weight: FontWeight.w600),
      titleLarge: outfit(base.titleLarge, weight: FontWeight.w600),
      titleMedium: outfit(base.titleMedium, weight: FontWeight.w600),
      titleSmall: outfit(base.titleSmall, weight: FontWeight.w600),
      bodyLarge: dmSans.bodyLarge?.copyWith(color: scheme.onSurface),
      bodyMedium: dmSans.bodyMedium?.copyWith(color: scheme.onSurface),
      bodySmall: dmSans.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
      labelLarge: dmSans.labelLarge?.copyWith(color: scheme.onSurface),
      labelMedium: dmSans.labelMedium?.copyWith(color: scheme.onSurfaceVariant),
    );
  }

  /// Light theme configuration
  static ThemeData get lightTheme => _build(
    AppColorScheme.light,
    scaffold: _weDecorBackgroundLight,
    card: AppColorScheme.light.surface,
    navSurface: AppColorScheme.light.surface,
  );

  /// Dark theme configuration
  static ThemeData get darkTheme => _build(
    AppColorScheme.dark,
    scaffold: _weDecorBackgroundDark,
    card: _weDecorSurfaceCardDark,
    navSurface: _weDecorSurfaceDark,
  );

  /// Single builder so light and dark can never drift apart. Every component
  /// colour is derived from [cs]; separation is by 1px hairlines, not shadows.
  static ThemeData _build(
    ColorScheme cs, {
    required Color scaffold,
    required Color card,
    required Color navSurface,
  }) {
    final hairline = BorderSide(color: cs.outlineVariant);
    final buttonShape = RoundedRectangleBorder(borderRadius: AppRadius.medium);
    const buttonPadding = EdgeInsets.symmetric(
      horizontal: AppTokens.space6,
      vertical: AppTokens.space3,
    );

    WidgetStateProperty<Color> selectedOr(Color selected, Color other) =>
        WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? selected : other,
        );

    OutlineInputBorder inputBorder(Color color, [double width = 1]) => OutlineInputBorder(
      borderRadius: AppRadius.medium,
      borderSide: BorderSide(color: color, width: width),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: cs,
      brightness: cs.brightness,
      scaffoldBackgroundColor: scaffold,
      canvasColor: scaffold,

      appBarTheme: AppBarTheme(
        backgroundColor: navSurface,
        foregroundColor: cs.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        shape: Border(bottom: hairline),
        centerTitle: false,
        titleTextStyle: AppTypography.headlineMedium.copyWith(
          color: cs.onSurface,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: IconThemeData(color: cs.onSurface),
        actionsIconTheme: IconThemeData(color: cs.onSurface),
      ),

      cardTheme: CardThemeData(
        elevation: AppTokens.elevation0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.medium, side: hairline),
        color: card,
        surfaceTintColor: Colors.transparent,
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: cs.primary,
          foregroundColor: cs.onPrimary,
          elevation: AppTokens.elevation0,
          shape: buttonShape,
          padding: buttonPadding,
          textStyle: AppTypography.labelLarge,
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: cs.primary,
          foregroundColor: cs.onPrimary,
          shape: buttonShape,
          padding: buttonPadding,
          textStyle: AppTypography.labelLarge,
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: cs.tertiary,
          shape: buttonShape,
          padding: const EdgeInsets.symmetric(
            horizontal: AppTokens.space4,
            vertical: AppTokens.space2,
          ),
          textStyle: AppTypography.labelLarge,
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: cs.onSurface,
          side: BorderSide(color: cs.outline),
          shape: buttonShape,
          padding: buttonPadding,
          textStyle: AppTypography.labelLarge,
        ),
      ),

      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
        elevation: AppTokens.elevation1,
        highlightElevation: AppTokens.elevation2,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.large),
      ),

      tabBarTheme: TabBarThemeData(
        labelColor: cs.onSurface,
        unselectedLabelColor: cs.onSurfaceVariant,
        indicatorColor: cs.tertiary,
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: cs.outlineVariant,
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: navSurface,
        indicatorColor: cs.tertiaryContainer,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        height: 64,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return AppTypography.labelMedium.copyWith(
            color: selected ? cs.onSurface : cs.onSurfaceVariant,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(color: selected ? cs.onTertiaryContainer : cs.onSurfaceVariant);
        }),
      ),

      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: navSurface,
        indicatorColor: cs.tertiaryContainer,
        selectedIconTheme: IconThemeData(color: cs.onTertiaryContainer),
        unselectedIconTheme: IconThemeData(color: cs.onSurfaceVariant),
        selectedLabelTextStyle: AppTypography.labelLarge.copyWith(
          color: cs.onSurface,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelTextStyle: AppTypography.labelLarge.copyWith(color: cs.onSurfaceVariant),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cs.surface,
        border: inputBorder(cs.outline),
        enabledBorder: inputBorder(cs.outline),
        focusedBorder: inputBorder(cs.primary, 2),
        errorBorder: inputBorder(cs.error),
        focusedErrorBorder: inputBorder(cs.error, 2),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppTokens.space4,
          vertical: AppTokens.space3,
        ),
      ),

      textTheme: _brandTextTheme(
        TextTheme(
          displayLarge: AppTypography.displayLarge.copyWith(color: cs.onSurface),
          headlineMedium: AppTypography.headlineMedium.copyWith(color: cs.onSurface),
          titleLarge: AppTypography.titleLarge.copyWith(color: cs.onSurface),
          titleMedium: AppTypography.titleLarge.copyWith(
            fontSize: AppTokens.fontSizeBodyLarge,
            color: cs.onSurface,
          ),
          bodyLarge: AppTypography.bodyLarge.copyWith(color: cs.onSurface),
          bodyMedium: AppTypography.bodyMedium.copyWith(color: cs.onSurface),
          bodySmall: AppTypography.bodySmall.copyWith(color: cs.onSurfaceVariant),
          labelLarge: AppTypography.labelLarge.copyWith(color: cs.onSurface),
          labelMedium: AppTypography.labelMedium.copyWith(color: cs.onSurfaceVariant),
        ),
        cs,
      ),

      chipTheme: ChipThemeData(
        backgroundColor: cs.surface,
        selectedColor: cs.tertiaryContainer,
        side: hairline,
        labelStyle: AppTypography.labelMedium.copyWith(color: cs.onSurface),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.small),
        padding: const EdgeInsets.symmetric(
          horizontal: AppTokens.space2,
          vertical: AppTokens.space1,
        ),
      ),

      switchTheme: SwitchThemeData(
        thumbColor: selectedOr(cs.onPrimary, cs.onSurfaceVariant),
        trackColor: selectedOr(cs.primary, cs.surfaceContainerHighest),
        trackOutlineColor: selectedOr(cs.primary, cs.outline),
      ),

      checkboxTheme: CheckboxThemeData(
        fillColor: selectedOr(cs.primary, Colors.transparent),
        checkColor: WidgetStatePropertyAll(cs.onPrimary),
      ),

      progressIndicatorTheme: ProgressIndicatorThemeData(color: cs.tertiary),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: cs.inverseSurface,
        contentTextStyle: AppTypography.bodyMedium.copyWith(color: cs.onInverseSurface),
        actionTextColor: AppColorScheme.accent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.medium),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: card,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.medium),
      ),

      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: card,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.only(
            topLeft: AppTokens.radiusMedium,
            topRight: AppTokens.radiusMedium,
          ),
        ),
      ),

      dividerTheme: DividerThemeData(color: cs.outlineVariant, thickness: 1, space: 1),
    );
  }
}
