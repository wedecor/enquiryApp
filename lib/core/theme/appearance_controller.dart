import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_theme.dart';

/// Appearance mode options
enum AppearanceMode {
  system('system'),
  light('light'),
  dark('dark');

  const AppearanceMode(this.value);
  final String value;

  static AppearanceMode fromString(String value) {
    return AppearanceMode.values.firstWhere(
      (mode) => mode.value == value,
      orElse: () => AppearanceMode.system,
    );
  }

  /// Get the actual brightness based on system preference
  Brightness getBrightness(BuildContext context) {
    switch (this) {
      case AppearanceMode.light:
        return Brightness.light;
      case AppearanceMode.dark:
        return Brightness.dark;
      case AppearanceMode.system:
        return MediaQuery.of(context).platformBrightness;
    }
  }
}

/// Riverpod provider for appearance mode state
final appearanceModeProvider = StateNotifierProvider<AppearanceController, AppearanceMode>((ref) {
  return AppearanceController();
});

/// Controller for managing app appearance (light/dark/system)
class AppearanceController extends StateNotifier<AppearanceMode> {
  AppearanceController() : super(AppearanceMode.system) {
    _loadSavedMode();
  }

  static const String _prefsKey = 'appearance_mode';

  /// Load saved appearance mode from SharedPreferences
  Future<void> _loadSavedMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedMode = prefs.getString(_prefsKey);
      if (savedMode != null) {
        state = AppearanceMode.fromString(savedMode);
      }
    } catch (e) {
      // Default to system mode if loading fails
      state = AppearanceMode.system;
    }
  }

  /// Set appearance mode and persist to SharedPreferences
  Future<void> setMode(AppearanceMode mode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, mode.value);
      state = mode;
    } catch (e) {
      // If saving fails, still update the state
      state = mode;
    }
  }

  /// Get the current appearance mode
  AppearanceMode get currentMode => state;

  /// Check if current mode is system
  bool get isSystemMode => state == AppearanceMode.system;

  /// Check if current mode is light
  bool get isLightMode => state == AppearanceMode.light;

  /// Check if current mode is dark
  bool get isDarkMode => state == AppearanceMode.dark;
}

/// Provider for the current theme based on appearance mode
final currentThemeProvider = Provider<ThemeData>((ref) {
  final appearanceMode = ref.watch(appearanceModeProvider);
  final context = ref.watch(materialAppContextProvider);

  if (context != null) {
    final brightness = appearanceMode.getBrightness(context);
    return brightness == Brightness.dark ? AppTheme.darkTheme : AppTheme.lightTheme;
  }

  // Fallback to light theme if context is not available
  return AppTheme.lightTheme;
});

/// Provider for current color scheme based on theme
final currentColorSchemeProvider = Provider<ColorScheme>((ref) {
  final theme = ref.watch(currentThemeProvider);
  return theme.colorScheme;
});

/// Provider for current brightness
final currentBrightnessProvider = Provider<Brightness>((ref) {
  final appearanceMode = ref.watch(appearanceModeProvider);
  final context = ref.watch(materialAppContextProvider);

  if (context != null) {
    return appearanceMode.getBrightness(context);
  }

  return Brightness.light;
});

/// Provider to access MaterialApp context
final materialAppContextProvider = StateProvider<BuildContext?>((ref) {
  // This will be set by the MaterialApp widget
  return null;
});

/// Extension to easily access appearance controller
extension AppearanceControllerExtension on WidgetRef {
  AppearanceController get appearanceController => read(appearanceModeProvider.notifier);
  AppearanceMode get currentAppearanceMode => read(appearanceModeProvider);
}

/// Widget to set the MaterialApp context for theme providers
class ThemeContextProvider extends ConsumerWidget {
  final Widget child;

  const ThemeContextProvider({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Store the context for theme providers
    ref.read(materialAppContextProvider.notifier).state = context;
    return child;
  }
}

/// Helper class for theme-related utilities
class ThemeUtils {
  ThemeUtils._();

  /// Get semantic color based on current theme
  static Color getSemanticColor(BuildContext context, SemanticColorType type) {
    final colorScheme = Theme.of(context).colorScheme;

    switch (type) {
      case SemanticColorType.success:
        return AppColorScheme.success;
      case SemanticColorType.warning:
        return AppColorScheme.warning;
      case SemanticColorType.info:
        return AppColorScheme.info;
      case SemanticColorType.error:
        return colorScheme.error;
    }
  }

  /// Get semantic container color based on current theme
  static Color getSemanticContainerColor(BuildContext context, SemanticColorType type) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = colorScheme.brightness == Brightness.dark;

    switch (type) {
      case SemanticColorType.success:
        return isDark ? AppColorScheme.successContainerDark : AppColorScheme.successContainerLight;
      case SemanticColorType.warning:
        return isDark ? AppColorScheme.warningContainerDark : AppColorScheme.warningContainerLight;
      case SemanticColorType.info:
        return colorScheme.primaryContainer;
      case SemanticColorType.error:
        return colorScheme.errorContainer;
    }
  }

  /// Get semantic on-color based on current theme
  static Color getSemanticOnColor(BuildContext context, SemanticColorType type) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = colorScheme.brightness == Brightness.dark;

    switch (type) {
      case SemanticColorType.success:
        return isDark ? AppColorScheme.onSuccessDark : AppColorScheme.onSuccessLight;
      case SemanticColorType.warning:
        return isDark ? AppColorScheme.onWarningDark : AppColorScheme.onWarningLight;
      case SemanticColorType.info:
        return colorScheme.onPrimary;
      case SemanticColorType.error:
        return colorScheme.onError;
    }
  }
}

/// Enum for semantic color types
enum SemanticColorType { success, warning, info, error }
