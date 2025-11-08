import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:we_decor_enquiries/core/theme/appearance_controller.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  Future<void> pumpEventQueue([int iterations = 5]) async {
    for (var i = 0; i < iterations; i++) {
      await Future<void>.delayed(Duration.zero);
    }
  }

  test('AppearanceController writes selection to persistent storage', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await container.read(appearanceControllerProvider.notifier).set(AppearanceMode.dark);

    expect(container.read(themeModeProvider), ThemeMode.dark);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('appearance.mode.v2'), 'dark');
  });

  test('AppearanceController restores persisted mode on boot', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{'appearance.mode.v2': 'light'});

    final container = ProviderContainer();
    addTearDown(container.dispose);

    container.read(appearanceControllerProvider);
    await pumpEventQueue(20);

    expect(container.read(appearanceControllerProvider), AppearanceMode.light);
    expect(container.read(themeModeProvider), ThemeMode.light);
  });
}
