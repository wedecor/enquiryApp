import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/current_user_role_provider.dart';
import '../../../utils/logger.dart';
import '../data/app_config_service.dart';
import '../data/user_settings_service.dart';
import '../domain/app_config.dart';
import '../domain/user_settings.dart';

// Services
final userSettingsServiceProvider = Provider<UserSettingsService>((ref) {
  return UserSettingsService();
});

final appConfigServiceProvider = Provider<AppConfigService>((ref) {
  return AppConfigService();
});

// User Settings Providers
final userSettingsProvider = StreamProvider.family<UserSettings, String>((ref, uid) {
  final service = ref.watch(userSettingsServiceProvider);
  return service.observe(uid);
});

final currentUserSettingsProvider = StreamProvider<UserSettings>((ref) {
  final uid = ref.watch(currentUserUidProvider);
  if (uid == null) {
    return Stream.value(const UserSettings());
  }

  final service = ref.watch(userSettingsServiceProvider);
  return service.observe(uid);
});

// App Config Providers
final appGeneralConfigProvider = StreamProvider<AppGeneralConfig>((ref) {
  final service = ref.watch(appConfigServiceProvider);
  return service.observeGeneral();
});

final appNotificationConfigProvider = StreamProvider<AppNotificationConfig>((ref) {
  final service = ref.watch(appConfigServiceProvider);
  return service.observeNotifications();
});

final appSecurityConfigProvider = StreamProvider<AppSecurityConfig>((ref) {
  final service = ref.watch(appConfigServiceProvider);
  return service.observeSecurity();
});

// Update Providers
final updateUserSettingsProvider = Provider<Future<void> Function(UserSettings)>((ref) {
  return (UserSettings settings) async {
    final uid = ref.read(currentUserUidProvider);
    if (uid == null) {
      throw Exception('User not authenticated - cannot save preferences');
    }

    Log.d(
      'Saving user preferences',
      data: {'uid': uid, 'theme': settings.theme, 'language': settings.language},
    );

    final service = ref.read(userSettingsServiceProvider);
    try {
      await service.update(uid, settings);
      Log.d('Preferences saved successfully', data: {'uid': uid});
    } catch (e) {
      Log.e('Error saving preferences', error: e);
      throw Exception('Failed to save preferences: $e');
    }
  };
});

final updateAppGeneralConfigProvider = Provider<Future<void> Function(AppGeneralConfig)>((ref) {
  return (AppGeneralConfig config) async {
    final service = ref.read(appConfigServiceProvider);
    await service.updateGeneral(config);
  };
});

final updateAppNotificationConfigProvider = Provider<Future<void> Function(AppNotificationConfig)>((
  ref,
) {
  return (AppNotificationConfig config) async {
    final service = ref.read(appConfigServiceProvider);
    await service.updateNotifications(config);
  };
});

final updateAppSecurityConfigProvider = Provider<Future<void> Function(AppSecurityConfig)>((ref) {
  return (AppSecurityConfig config) async {
    final service = ref.read(appConfigServiceProvider);
    await service.updateSecurity(config);
  };
});
