import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/auth/current_user_role_provider.dart';
import '../../../../core/logging/logger.dart';
import '../../../../core/logging/safe_log.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../core/theme/widgets/appearance_setting.dart';
import '../../domain/user_settings.dart';
import '../../providers/settings_providers.dart';
import '../../../../ui/components/glass_state_message.dart';
import '../widgets/settings_layout.dart';

class PreferencesTab extends ConsumerStatefulWidget {
  const PreferencesTab({super.key});

  @override
  ConsumerState<PreferencesTab> createState() => _PreferencesTabState();
}

class _PreferencesTabState extends ConsumerState<PreferencesTab> {
  UserSettings? _originalSettings;
  UserSettings? _currentSettings;
  bool _hasChanges = false;
  bool _isSaving = false;

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(currentUserSettingsProvider);

    return settingsAsync.when(
      data: (settings) {
        if (_originalSettings == null) {
          _originalSettings = settings;
          _currentSettings = settings;
        }

        return _buildPreferencesContent(context, settings);
      },
      loading: () => const GlassLoadingState(),
      error: (error, stack) => GlassStateMessage(
        icon: Icons.error_outline_rounded,
        title: 'Preferences unavailable',
        message: 'Error loading preferences: $error',
        color: Theme.of(context).colorScheme.error,
      ),
    );
  }

  Widget _buildPreferencesContent(BuildContext context, UserSettings settings) {
    return SettingsEditableBody(
      hasChanges: _hasChanges,
      isSaving: _isSaving,
      onSave: _saveChanges,
      onDiscard: _discardChanges,
      child: SettingsScrollBody(
        children: [
          const Padding(
            padding: EdgeInsets.only(top: AppTokens.space4),
            child: AppearanceSetting(),
          ),
          _buildLanguageSection(context),
          _buildTimezoneSection(context),
        ],
      ),
    );
  }

  Widget _buildLanguageSection(BuildContext context) {
    return SettingsGroup(
      eyebrow: 'Region',
      title: 'Language',
      subtitle: 'App language (more languages coming soon)',
      separated: false,
      padding: const EdgeInsets.all(AppTokens.space4),
      children: [
        DropdownButtonFormField<String>(
          // Rebuilt on discard so the field reflects the restored value.
          key: ValueKey('language-${_currentSettings?.language}'),
          initialValue: _currentSettings?.language ?? 'en',
          decoration: const InputDecoration(
            labelText: 'Language',
            prefixIcon: Icon(Icons.translate_rounded),
          ),
          items: const [DropdownMenuItem(value: 'en', child: Text('English'))],
          onChanged: (newLanguage) {
            if (newLanguage != null) {
              _updateSettings(_currentSettings!.copyWith(language: newLanguage));
            }
          },
        ),
      ],
    );
  }

  Widget _buildTimezoneSection(BuildContext context) {
    return SettingsGroup(
      eyebrow: 'Clock',
      title: 'Timezone',
      subtitle: 'Used for date and time display',
      separated: false,
      padding: const EdgeInsets.all(AppTokens.space4),
      children: [
        DropdownButtonFormField<String>(
          key: ValueKey('timezone-${_currentSettings?.timezone}'),
          initialValue: _currentSettings?.timezone ?? 'Asia/Kolkata',
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'Timezone',
            prefixIcon: Icon(Icons.schedule_rounded),
          ),
          items: const [
            DropdownMenuItem(value: 'Asia/Kolkata', child: Text('Asia/Kolkata (IST)')),
            DropdownMenuItem(value: 'UTC', child: Text('UTC')),
            DropdownMenuItem(value: 'America/New_York', child: Text('America/New_York (EST)')),
            DropdownMenuItem(value: 'Europe/London', child: Text('Europe/London (GMT)')),
          ],
          onChanged: (newTimezone) {
            if (newTimezone != null) {
              _updateSettings(_currentSettings!.copyWith(timezone: newTimezone));
            }
          },
        ),
      ],
    );
  }

  void _updateSettings(UserSettings newSettings) {
    setState(() {
      _currentSettings = newSettings;
      _hasChanges = _currentSettings != _originalSettings;
    });
  }

  Future<void> _saveChanges() async {
    if (_currentSettings == null || !_hasChanges || _isSaving) return;

    setState(() {
      _isSaving = true;
    });

    try {
      // Debug: Check authentication state
      final uid = ref.read(currentUserUidProvider);
      Log.d(
        'Preferences save request',
        data: {
          'hasUid': uid != null,
          'theme': _currentSettings!.theme,
          'language': _currentSettings!.language,
        },
      );

      if (uid == null) {
        throw Exception('User not authenticated - UID is null');
      }

      final updateSettings = ref.read(updateUserSettingsProvider);
      await updateSettings(_currentSettings!);

      setState(() {
        _originalSettings = _currentSettings;
        _hasChanges = false;
        _isSaving = false;
      });

      safeLog('preferences_saved', {
        'theme': _currentSettings!.theme,
        'language': _currentSettings!.language,
        'timezone': _currentSettings!.timezone,
        'uid': uid,
      });

      if (mounted) {
        _showSnackBar('Preferences saved successfully');
      }
    } catch (e) {
      setState(() {
        _isSaving = false;
      });

      Log.e('Preferences save failed', error: e);
      Log.d('Preferences save failure details', data: {'errorType': e.runtimeType.toString()});

      safeLog('preferences_save_error', {
        'error': e.toString(),
        'errorType': e.runtimeType.toString(),
        'uid': ref.read(currentUserUidProvider),
      });

      if (mounted) {
        _showSnackBar('Failed to save preferences: ${e.toString()}', isError: true);
      }
    }
  }

  void _discardChanges() {
    setState(() {
      _currentSettings = _originalSettings;
      _hasChanges = false;
    });
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError
            ? Theme.of(context).colorScheme.error
            : Theme.of(context).colorScheme.primary,
        action: SnackBarAction(
          label: 'OK',
          textColor: isError
              ? Theme.of(context).colorScheme.onError
              : Theme.of(context).colorScheme.onPrimary,
          onPressed: () {},
        ),
      ),
    );
  }
}
