import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/auth/current_user_role_provider.dart';
import '../../../../core/logging/safe_log.dart';
import '../../../../core/theme/appearance_controller.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../core/theme/widgets/appearance_setting.dart';
import '../../domain/user_settings.dart';
import '../../providers/settings_providers.dart';

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
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error loading preferences: $error')),
    );
  }

  Widget _buildPreferencesContent(BuildContext context, UserSettings settings) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AppearanceSetting(),
                const SizedBox(height: 24),
                _buildLanguageSection(context),
                const SizedBox(height: 24),
                _buildTimezoneSection(context),
              ],
            ),
          ),
        ),
        if (_hasChanges) _buildSaveSection(context),
      ],
    );
  }





  Widget _buildLanguageSection(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Language', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              'App language (more languages coming soon)',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _currentSettings?.language ?? 'en',
              decoration: const InputDecoration(
                labelText: 'Language',
                border: OutlineInputBorder(),
              ),
              items: const [DropdownMenuItem(value: 'en', child: Text('English'))],
              onChanged: (newLanguage) {
                if (newLanguage != null) {
                  _updateSettings(_currentSettings!.copyWith(language: newLanguage));
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimezoneSection(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Timezone', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text('Used for date and time display', style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _currentSettings?.timezone ?? 'Asia/Kolkata',
              decoration: const InputDecoration(
                labelText: 'Timezone',
                border: OutlineInputBorder(),
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
        ),
      ),
    );
  }

  Widget _buildSaveSection(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _isSaving ? null : _saveChanges,
              icon: _isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save),
              label: Text(_isSaving ? 'Saving...' : 'Save Changes'),
            ),
          ),
          const SizedBox(width: 16),
          TextButton(onPressed: _isSaving ? null : _discardChanges, child: const Text('Discard')),
        ],
      ),
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
      print('DEBUG PREFERENCES: Current UID: $uid');
      print('DEBUG PREFERENCES: Settings to save: ${_currentSettings!.toJson()}');

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

      print('DEBUG PREFERENCES ERROR: $e');
      print('DEBUG PREFERENCES ERROR TYPE: ${e.runtimeType}');

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
