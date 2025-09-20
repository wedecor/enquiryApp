import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/logging/safe_log.dart';
import '../../domain/user_settings.dart';
import '../../providers/settings_providers.dart';

class NotificationsTab extends ConsumerStatefulWidget {
  const NotificationsTab({super.key});

  @override
  ConsumerState<NotificationsTab> createState() => _NotificationsTabState();
}

class _NotificationsTabState extends ConsumerState<NotificationsTab> {
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

        return _buildNotificationsContent(context, settings);
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) =>
          Center(child: Text('Error loading notification settings: $error')),
    );
  }

  Widget _buildNotificationsContent(
    BuildContext context,
    UserSettings settings,
  ) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildMasterToggles(context),
                const SizedBox(height: 24),
                _buildChannelSettings(context),
                const SizedBox(height: 24),
                _buildInfoSection(context),
              ],
            ),
          ),
        ),
        if (_hasChanges) _buildSaveSection(context),
      ],
    );
  }

  Widget _buildMasterToggles(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Master Controls',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Enable or disable notification types',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Push Notifications'),
              subtitle: const Text('Receive notifications in the app'),
              value: _currentSettings?.notifications.pushEnabled ?? true,
              onChanged: (value) {
                final newNotifications = _currentSettings!.notifications
                    .copyWith(pushEnabled: value);
                _updateSettings(
                  _currentSettings!.copyWith(notifications: newNotifications),
                );
              },
            ),
            SwitchListTile(
              title: const Text('Email Notifications'),
              subtitle: const Text('Receive notifications via email'),
              value: _currentSettings?.notifications.emailEnabled ?? false,
              onChanged: (value) {
                final newNotifications = _currentSettings!.notifications
                    .copyWith(emailEnabled: value);
                _updateSettings(
                  _currentSettings!.copyWith(notifications: newNotifications),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChannelSettings(BuildContext context) {
    final channels =
        _currentSettings?.notifications.channels ??
        const NotificationChannels();
    final pushEnabled = _currentSettings?.notifications.pushEnabled ?? true;
    final emailEnabled = _currentSettings?.notifications.emailEnabled ?? false;
    final anyEnabled = pushEnabled || emailEnabled;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Notification Channels',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              anyEnabled
                  ? 'Choose which events trigger notifications'
                  : 'Enable push or email notifications above to configure channels',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            _buildChannelToggle(
              'Assignment Notifications',
              'When enquiries are assigned to you',
              Icons.assignment_ind,
              channels.assignment,
              enabled: anyEnabled,
              onChanged: (value) {
                final newChannels = channels.copyWith(assignment: value);
                final newNotifications = _currentSettings!.notifications
                    .copyWith(channels: newChannels);
                _updateSettings(
                  _currentSettings!.copyWith(notifications: newNotifications),
                );
              },
            ),
            _buildChannelToggle(
              'Status Changes',
              'When enquiry status is updated',
              Icons.update,
              channels.statusChange,
              enabled: anyEnabled,
              onChanged: (value) {
                final newChannels = channels.copyWith(statusChange: value);
                final newNotifications = _currentSettings!.notifications
                    .copyWith(channels: newChannels);
                _updateSettings(
                  _currentSettings!.copyWith(notifications: newNotifications),
                );
              },
            ),
            _buildChannelToggle(
              'Payment Updates',
              'When payment status changes',
              Icons.payment,
              channels.payment,
              enabled: anyEnabled,
              onChanged: (value) {
                final newChannels = channels.copyWith(payment: value);
                final newNotifications = _currentSettings!.notifications
                    .copyWith(channels: newChannels);
                _updateSettings(
                  _currentSettings!.copyWith(notifications: newNotifications),
                );
              },
            ),
            _buildChannelToggle(
              'Reminders',
              'Follow-up and deadline reminders',
              Icons.alarm,
              channels.reminders,
              enabled: anyEnabled,
              onChanged: (value) {
                final newChannels = channels.copyWith(reminders: value);
                final newNotifications = _currentSettings!.notifications
                    .copyWith(channels: newChannels);
                _updateSettings(
                  _currentSettings!.copyWith(notifications: newNotifications),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChannelToggle(
    String title,
    String subtitle,
    IconData icon,
    bool value, {
    required bool enabled,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      title: Text(title),
      subtitle: Text(subtitle),
      secondary: Icon(icon, color: enabled ? null : Colors.grey),
      value: value,
      onChanged: enabled ? onChanged : null,
    );
  }

  Widget _buildInfoSection(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue.shade600),
                const SizedBox(width: 8),
                Text(
                  'Important Notes',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.blue.shade600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildInfoItem(
              'Push notifications require browser permission. You may need to allow notifications in your browser settings.',
            ),
            const SizedBox(height: 8),
            _buildInfoItem(
              'Email notifications depend on admin settings and may not be available for all events.',
            ),
            const SizedBox(height: 8),
            _buildInfoItem(
              'Changes take effect immediately but may take a few minutes to apply to all services.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 6),
          width: 4,
          height: 4,
          decoration: const BoxDecoration(
            color: Colors.grey,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
      ],
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
          TextButton(
            onPressed: _isSaving ? null : _discardChanges,
            child: const Text('Discard'),
          ),
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
      final updateSettings = ref.read(updateUserSettingsProvider);
      await updateSettings(_currentSettings!);

      setState(() {
        _originalSettings = _currentSettings;
        _hasChanges = false;
        _isSaving = false;
      });

      safeLog('notification_settings_saved', {
        'pushEnabled': _currentSettings!.notifications.pushEnabled,
        'emailEnabled': _currentSettings!.notifications.emailEnabled,
        'channelsEnabled': {
          'assignment': _currentSettings!.notifications.channels.assignment,
          'statusChange': _currentSettings!.notifications.channels.statusChange,
          'payment': _currentSettings!.notifications.channels.payment,
          'reminders': _currentSettings!.notifications.channels.reminders,
        },
      });

      if (mounted) {
        _showSnackBar('Notification settings saved successfully');
      }
    } catch (e) {
      setState(() {
        _isSaving = false;
      });

      safeLog('notification_settings_save_error', {
        'error': e.toString(),
        'errorType': e.runtimeType.toString(),
      });

      if (mounted) {
        _showSnackBar('Failed to save notification settings', isError: true);
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
        backgroundColor: isError ? Colors.red : Colors.green,
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {},
        ),
      ),
    );
  }
}
