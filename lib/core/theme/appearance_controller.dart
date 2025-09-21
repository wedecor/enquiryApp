import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppearanceMode { system, light, dark }

extension AppearanceModeExtension on AppearanceMode {
  ThemeMode get asThemeMode => switch (this) {
    AppearanceMode.system => ThemeMode.system,
    AppearanceMode.light => ThemeMode.light,
    AppearanceMode.dark => ThemeMode.dark,
  };
}

const _kAppearanceKey = 'appearance.mode.v2';

class AppearanceController extends Notifier<AppearanceMode> {
  @override
  AppearanceMode build() {
    // lazy init from prefs (non-blocking) with fallback to system
    _load();
    return AppearanceMode.system;
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_kAppearanceKey);
      final parsed = AppearanceMode.values.firstWhere(
        (e) => e.name == raw,
        orElse: () => AppearanceMode.system,
      );
      if (state != parsed) state = parsed;
    } catch (_) {
      /* ignore, keep default */
    }
  }

  Future<void> set(AppearanceMode mode) async {
    state = mode; // immediate rebuild for MaterialApp
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kAppearanceKey, mode.name);
    } catch (_) {
      /* ignore persist errors */
    }
  }
}

final appearanceControllerProvider = NotifierProvider<AppearanceController, AppearanceMode>(
  AppearanceController.new,
);

/// Provider for the current ThemeMode to be used by MaterialApp
final themeModeProvider = Provider<ThemeMode>((ref) {
  final appearanceMode = ref.watch(appearanceControllerProvider);
  return appearanceMode.asThemeMode;
});

/// Legacy provider for backward compatibility
/// @deprecated Use appearanceControllerProvider instead
final appearanceModeProvider = StateNotifierProvider<_LegacyAppearanceController, AppearanceMode>((
  ref,
) {
  return _LegacyAppearanceController(ref);
});

/// Legacy controller that delegates to the new Notifier-based controller
class _LegacyAppearanceController extends StateNotifier<AppearanceMode> {
  _LegacyAppearanceController(this.ref) : super(AppearanceMode.system) {
    // Sync with new controller
    ref.listen(appearanceControllerProvider, (previous, next) {
      state = next;
    });
  }

  final Ref ref;

  Future<void> setMode(AppearanceMode mode) async {
    await ref.read(appearanceControllerProvider.notifier).set(mode);
  }

  AppearanceMode get currentMode => state;
  bool get isSystemMode => state == AppearanceMode.system;
  bool get isLightMode => state == AppearanceMode.light;
  bool get isDarkMode => state == AppearanceMode.dark;
}
