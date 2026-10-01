import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/status_vocabulary.dart';
import 'surfaces.dart';
import 'tokens.dart';

export 'surfaces.dart';

// We Decor brand: charcoal ink, cream ground, one gold accent. Light mode is a
// warm porcelain; dark mode is a rich charcoal/deep slate, never pure black.
const Color _brandCharcoal = Color(0xFF1C1E22);
const Color _brandCream = Color(0xFFF1EADB);
const Color _brandSlate = Color(0xFF5C6166);
const Color _brandGold = Color(0xFFC49A4E);

const Color _groundLight = Color(0xFFF4F0E8);
const Color _groundDark = Color(0xFF0F1114);

/// Light and dark color schemes following Material 3 design
class AppColorScheme {
  AppColorScheme._();

  /// The single brand accent. Change this one value to re-tint emphasis app-wide.
  static const Color accent = _brandGold;

  /// Brand neutrals, exposed for logo/brand-mark rendering only.
  static const Color brandCharcoal = _brandCharcoal;
  static const Color brandCream = _brandCream;
  static const Color brandSlate = _brandSlate;

  static const ColorScheme light = ColorScheme(
    brightness: Brightness.light,
    primary: _brandCharcoal,
    onPrimary: Color(0xFFFBF8F2),
    primaryContainer: Color(0xFFECE6DA),
    onPrimaryContainer: _brandCharcoal,
    secondary: _brandSlate,
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFFEDE7DB),
    onSecondaryContainer: Color(0xFF2B2E33),
    tertiary: Color(0xFF8A6420),
    onTertiary: Color(0xFFFFFFFF),
    tertiaryContainer: Color(0xFFF4E8CF),
    onTertiaryContainer: Color(0xFF3A2A0B),
    error: Color(0xFFB3261E),
    onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFFF9DEDC),
    onErrorContainer: Color(0xFF410E0B),
    surface: Color(0xFFFFFFFF),
    onSurface: Color(0xFF16171A),
    surfaceContainerLowest: Color(0xFFFFFFFF),
    surfaceContainerLow: Color(0xFFFBF9F5),
    surfaceContainer: Color(0xFFF5F1EA),
    surfaceContainerHigh: Color(0xFFEFEAE0),
    surfaceContainerHighest: Color(0xFFE8E1D3),
    onSurfaceVariant: Color(0xFF5E6268),
    outline: Color(0xFFCFC8BA),
    outlineVariant: Color(0xFFE6E0D4),
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
    inverseSurface: _brandCharcoal,
    onInverseSurface: _brandCream,
    inversePrimary: _brandCream,
    surfaceTint: Color(0x00000000),
  );

  static const ColorScheme dark = ColorScheme(
    brightness: Brightness.dark,
    primary: _brandCream,
    onPrimary: Color(0xFF15171A),
    primaryContainer: Color(0xFF2B2E33),
    onPrimaryContainer: _brandCream,
    secondary: Color(0xFFAEB3B8),
    onSecondary: Color(0xFF15171A),
    secondaryContainer: Color(0xFF262A30),
    onSecondaryContainer: Color(0xFFE2E3E4),
    tertiary: Color(0xFFD8B26A),
    onTertiary: Color(0xFF2A1F08),
    tertiaryContainer: Color(0xFF3D3220),
    onTertiaryContainer: Color(0xFFF5E3BC),
    error: Color(0xFFF2B8B5),
    onError: Color(0xFF601410),
    errorContainer: Color(0xFF8C1D18),
    onErrorContainer: Color(0xFFF9DEDC),
    surface: Color(0xFF15181C),
    onSurface: Color(0xFFEDE9E1),
    surfaceContainerLowest: Color(0xFF0E1013),
    surfaceContainerLow: Color(0xFF13161A),
    surfaceContainer: Color(0xFF191C20),
    surfaceContainerHigh: Color(0xFF1F2227),
    surfaceContainerHighest: Color(0xFF262A30),
    onSurfaceVariant: Color(0xFFA3A8AE),
    outline: Color(0xFF4F545B),
    outlineVariant: Color(0xFF2C3036),
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
    inverseSurface: Color(0xFFEDE9E1),
    onInverseSurface: _brandCharcoal,
    inversePrimary: _brandCharcoal,
    surfaceTint: Color(0x00000000),
  );

  /// Additional semantic colors
  static const Color success = Color(0xFF2E9B6F);
  static const Color warning = Color(0xFFD99A2B);
  static const Color info = Color(0xFF4F7FE8);

  static const Color successLight = Color(0xFF2E9B6F);
  static const Color onSuccessLight = Color(0xFFFFFFFF);
  static const Color successContainerLight = Color(0xFFDDF1E7);
  static const Color onSuccessContainerLight = Color(0xFF0F3F2B);

  static const Color successDark = Color(0xFF5CC79A);
  static const Color onSuccessDark = Color(0xFF0F3F2B);
  static const Color successContainerDark = Color(0xFF1F5A41);
  static const Color onSuccessContainerDark = Color(0xFFDDF1E7);

  static const Color warningLight = Color(0xFFD99A2B);
  static const Color onWarningLight = Color(0xFFFFFFFF);
  static const Color warningContainerLight = Color(0xFFFBEBCB);
  static const Color onWarningContainerLight = Color(0xFF6B4708);

  static const Color warningDark = Color(0xFFF0C062);
  static const Color onWarningDark = Color(0xFF6B4708);
  static const Color warningContainerDark = Color(0xFF6B4A12);
  static const Color onWarningContainerDark = Color(0xFFFBEBCB);

  // Contact actions keep their recognisable service colours.
  static const Color whatsApp = Color(0xFF25D366);
  static const Color phoneCall = Color(0xFF4F7FE8);

  // Data visualisation: a harmonised set that sits on cream and charcoal.
  static const Color chartBlue = Color(0xFF5B7FD6);
  static const Color chartGreen = Color(0xFF4FA27C);
  static const Color chartAmber = Color(0xFFE0A33A);
  static const Color chartRed = Color(0xFFD0605A);
  static const Color chartPurple = Color(0xFF8C6CC8);
  static const Color chartCyan = Color(0xFF3E9CA8);
  static const Color chartOrange = Color(0xFFD07A55);
  static const Color chartEmerald = Color(0xFF3FAE84);
  static const Color chartIndigo = Color(0xFF7A8FE0);
  static const Color eventHaldi = Color(0xFFE6B53C);
  static const Color eventEngagement = Color(0xFFD46A7E);
  static const Color eventWedding = Color(0xFF8C6CC8);
  static const Color eventBirthday = Color(0xFF3E9CA8);
  static const Color neutralGrey = Color(0xFF8E8A84);

  /// Enquiry pipeline status colors.
  static const Color statusNew = Color(0xFF4F7FE8);
  static const Color statusInTalks = Color(0xFFD99A2B);
  static const Color statusQuoteSent = Color(0xFF8C6CC8);
  static const Color statusConfirmed = Color(0xFF2E9B6F);
  static const Color statusCompleted = Color(0xFF6F8FA6);

  /// Losing a lead is routine, so it reads as warm grey, never alarm red.
  static const Color statusLost = Color(0xFF9C9086);

  static const Color snackSuccess = success;
  static const Color snackError = Color(0xFFC8433B);
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
        return statusLost;
      default:
        return neutralGrey;
    }
  }

  static const List<Color> chartPalette = [
    _brandGold,
    chartBlue,
    chartGreen,
    chartOrange,
    chartPurple,
    chartCyan,
    chartAmber,
    eventEngagement,
  ];
}

/// Theme configuration for the app
class AppTheme {
  AppTheme._();

  static TextTheme _brandTextTheme(ColorScheme cs) {
    final base = GoogleFonts.dmSansTextTheme();
    TextStyle display(TextStyle style, Color color) =>
        GoogleFonts.outfit(textStyle: style.copyWith(color: color));
    TextStyle body(TextStyle style, Color color) =>
        GoogleFonts.dmSans(textStyle: style.copyWith(color: color));

    return base.copyWith(
      displayLarge: display(AppTypography.displayLarge, cs.onSurface),
      displayMedium: display(AppTypography.displayMedium, cs.onSurface),
      displaySmall: display(AppTypography.displaySmall, cs.onSurface),
      headlineLarge: display(AppTypography.displayMedium.copyWith(fontSize: 30), cs.onSurface),
      headlineMedium: display(AppTypography.headlineMedium, cs.onSurface),
      headlineSmall: display(AppTypography.headlineSmall, cs.onSurface),
      titleLarge: display(AppTypography.titleLarge, cs.onSurface),
      titleMedium: display(
        AppTypography.titleLarge.copyWith(fontSize: 16, fontWeight: FontWeight.w600),
        cs.onSurface,
      ),
      titleSmall: display(
        AppTypography.titleLarge.copyWith(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 0,
        ),
        cs.onSurface,
      ),
      bodyLarge: body(AppTypography.bodyLarge, cs.onSurface),
      bodyMedium: body(AppTypography.bodyMedium, cs.onSurface),
      bodySmall: body(AppTypography.bodySmall, cs.onSurfaceVariant),
      labelLarge: body(
        AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w600, letterSpacing: 0.1),
        cs.onSurface,
      ),
      labelMedium: body(AppTypography.labelMedium, cs.onSurfaceVariant),
      labelSmall: body(AppTypography.labelSmall, cs.onSurfaceVariant),
    );
  }

  static ThemeData get lightTheme =>
      _build(AppColorScheme.light, surfaces: AppSurfaces.light, ground: _groundLight);

  static ThemeData get darkTheme =>
      _build(AppColorScheme.dark, surfaces: AppSurfaces.dark, ground: _groundDark);

  /// Single builder so light and dark can never drift apart.
  static ThemeData _build(ColorScheme cs, {required AppSurfaces surfaces, required Color ground}) {
    final micro = BorderSide(color: surfaces.microBorder);
    final buttonShape = RoundedRectangleBorder(borderRadius: AppRadius.medium);
    const buttonPadding = EdgeInsets.symmetric(horizontal: AppTokens.space6, vertical: 14);
    const buttonMinSize = Size(64, AppTokens.minTapTarget);
    final textTheme = _brandTextTheme(cs);
    final buttonLabel = textTheme.labelLarge!.copyWith(
      fontWeight: FontWeight.w700,
      letterSpacing: 0.2,
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
      scaffoldBackgroundColor: ground,
      canvasColor: ground,
      textTheme: textTheme,
      extensions: [surfaces],
      splashFactory: InkSparkle.splashFactory,
      visualDensity: VisualDensity.standard,

      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.linux: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.windows: FadeForwardsPageTransitionsBuilder(),
        },
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: cs.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        titleSpacing: AppTokens.space5,
        titleTextStyle: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
        iconTheme: IconThemeData(color: cs.onSurface),
        actionsIconTheme: IconThemeData(color: cs.onSurface),
      ),

      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.large, side: micro),
        color: surfaces.glassFillStrong,
        surfaceTintColor: Colors.transparent,
        clipBehavior: Clip.antiAlias,
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: cs.primary,
          foregroundColor: cs.onPrimary,
          elevation: 0,
          shape: buttonShape,
          padding: buttonPadding,
          minimumSize: buttonMinSize,
          textStyle: buttonLabel,
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: cs.primary,
          foregroundColor: cs.onPrimary,
          shape: buttonShape,
          padding: buttonPadding,
          minimumSize: buttonMinSize,
          textStyle: buttonLabel,
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: surfaces.accentInk,
          shape: buttonShape,
          padding: const EdgeInsets.symmetric(
            horizontal: AppTokens.space4,
            vertical: AppTokens.space3,
          ),
          textStyle: buttonLabel,
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: cs.onSurface,
          backgroundColor: surfaces.glassFill,
          side: BorderSide(color: surfaces.microBorderStrong),
          shape: buttonShape,
          padding: buttonPadding,
          minimumSize: buttonMinSize,
          textStyle: buttonLabel,
        ),
      ),

      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: cs.onSurface,
          shape: const CircleBorder(),
          minimumSize: const Size.square(AppTokens.minTapTarget),
        ),
      ),

      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
        elevation: 0,
        focusElevation: 0,
        hoverElevation: 0,
        highlightElevation: 0,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.large),
        extendedTextStyle: buttonLabel,
      ),

      tabBarTheme: TabBarThemeData(
        labelColor: cs.onSurface,
        unselectedLabelColor: cs.onSurfaceVariant,
        labelStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
        unselectedLabelStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w500),
        indicator: BoxDecoration(
          color: surfaces.glassFillStrong,
          borderRadius: AppRadius.full,
          border: Border.fromBorderSide(BorderSide(color: surfaces.microBorderStrong)),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        splashBorderRadius: AppRadius.full,
        overlayColor: WidgetStatePropertyAll(cs.onSurface.withValues(alpha: 0.04)),
      ),

      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          backgroundColor: surfaces.glassFill,
          selectedBackgroundColor: cs.primary,
          selectedForegroundColor: cs.onPrimary,
          foregroundColor: cs.onSurfaceVariant,
          side: BorderSide(color: surfaces.microBorderStrong),
          shape: const StadiumBorder(),
          textStyle: textTheme.labelLarge,
        ),
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surfaces.glassFillStrong,
        indicatorColor: cs.tertiaryContainer,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        height: 64,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return textTheme.labelMedium?.copyWith(
            color: selected ? cs.onSurface : cs.onSurfaceVariant,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          );
        }),
      ),

      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: Colors.transparent,
        indicatorColor: cs.tertiaryContainer,
        selectedIconTheme: IconThemeData(color: cs.onTertiaryContainer),
        unselectedIconTheme: IconThemeData(color: cs.onSurfaceVariant),
        selectedLabelTextStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
        unselectedLabelTextStyle: textTheme.labelLarge?.copyWith(color: cs.onSurfaceVariant),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaces.glassFillStrong,
        border: inputBorder(surfaces.microBorderStrong),
        enabledBorder: inputBorder(surfaces.microBorderStrong),
        focusedBorder: inputBorder(surfaces.accent, 1.6),
        errorBorder: inputBorder(cs.error),
        focusedErrorBorder: inputBorder(cs.error, 1.6),
        disabledBorder: inputBorder(surfaces.microBorder),
        labelStyle: textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
        floatingLabelStyle: textTheme.labelLarge?.copyWith(color: surfaces.accentInk),
        hintStyle: textTheme.bodyMedium?.copyWith(
          color: cs.onSurfaceVariant.withValues(alpha: 0.7),
          fontWeight: FontWeight.w300,
        ),
        prefixIconColor: cs.onSurfaceVariant,
        suffixIconColor: cs.onSurfaceVariant,
        contentPadding: const EdgeInsets.symmetric(horizontal: AppTokens.space4, vertical: 14),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: surfaces.glassFill,
        selectedColor: cs.tertiaryContainer,
        side: micro,
        labelStyle: textTheme.labelMedium?.copyWith(
          color: cs.onSurface,
          fontWeight: FontWeight.w600,
        ),
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(
          horizontal: AppTokens.space2,
          vertical: AppTokens.space1,
        ),
        showCheckmark: false,
      ),

      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(borderRadius: AppRadius.medium),
        contentPadding: const EdgeInsets.symmetric(horizontal: AppTokens.space4),
        iconColor: cs.onSurfaceVariant,
        titleTextStyle: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
        subtitleTextStyle: textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w300),
      ),

      popupMenuTheme: PopupMenuThemeData(
        color: surfaces.glassFillStrong,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.large, side: micro),
        textStyle: textTheme.bodyMedium,
      ),

      menuTheme: MenuThemeData(
        style: MenuStyle(
          backgroundColor: WidgetStatePropertyAll(surfaces.glassFillStrong),
          surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
          elevation: const WidgetStatePropertyAll(0),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: AppRadius.large, side: micro),
          ),
        ),
      ),

      switchTheme: SwitchThemeData(
        thumbColor: selectedOr(cs.onPrimary, cs.onSurfaceVariant),
        trackColor: selectedOr(cs.primary, cs.surfaceContainerHighest),
        trackOutlineColor: selectedOr(cs.primary, surfaces.microBorderStrong),
      ),

      checkboxTheme: CheckboxThemeData(
        fillColor: selectedOr(cs.primary, Colors.transparent),
        checkColor: WidgetStatePropertyAll(cs.onPrimary),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.small),
      ),

      radioTheme: RadioThemeData(fillColor: selectedOr(cs.primary, cs.onSurfaceVariant)),

      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: surfaces.accent,
        linearTrackColor: surfaces.microBorder,
        circularTrackColor: Colors.transparent,
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: cs.inverseSurface,
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: cs.onInverseSurface),
        actionTextColor: surfaces.accent,
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        insetPadding: const EdgeInsets.fromLTRB(
          AppTokens.space4,
          0,
          AppTokens.space4,
          AppTokens.space4,
        ),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.medium),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: cs.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.xLarge, side: micro),
        titleTextStyle: textTheme.headlineSmall,
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
      ),

      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: cs.surface,
        modalBackgroundColor: cs.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        modalElevation: 0,
        showDragHandle: true,
        dragHandleColor: cs.onSurfaceVariant.withValues(alpha: 0.35),
        dragHandleSize: const Size(36, 4),
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.only(
            topLeft: AppTokens.radiusXXLarge,
            topRight: AppTokens.radiusXXLarge,
          ),
        ),
      ),

      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(color: cs.inverseSurface, borderRadius: AppRadius.small),
        textStyle: textTheme.labelMedium?.copyWith(color: cs.onInverseSurface),
      ),

      badgeTheme: BadgeThemeData(
        backgroundColor: surfaces.accent,
        textColor: const Color(0xFF1C1E22),
        textStyle: textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w800),
      ),

      dividerTheme: DividerThemeData(color: surfaces.microBorder, thickness: 1, space: 1),
    );
  }
}
