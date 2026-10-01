import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/logging/safe_log.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/user_settings.dart';
import '../../providers/settings_providers.dart';
import '../../../../ui/components/glass_state_message.dart';
import '../widgets/settings_layout.dart';
import '../widgets/settings_tiles.dart';

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
      loading: () => const GlassLoadingState(),
      error: (error, stack) => GlassStateMessage(
        icon: Icons.error_outline_rounded,
        title: 'Notifications unavailable',
        message: 'Error loading notification settings: $error',
        color: Theme.of(context).colorScheme.error,
      ),
    );
  }

  Widget _buildNotificationsContent(BuildContext context, UserSettings settings) {
    return SettingsEditableBody(
      hasChanges: _hasChanges,
      isSaving: _isSaving,
      onSave: _saveChanges,
      onDiscard: _discardChanges,
      child: SettingsScrollBody(
        children: [
          _buildMasterToggles(context),
          _buildChannelSettings(context),
          _buildInfoSection(context),
        ],
      ),
    );
  }

  Widget _buildMasterToggles(BuildContext context) {
    return SettingsGroup(
      eyebrow: 'Delivery',
      title: 'Master Controls',
      subtitle: 'Enable or disable notification types',
      children: [
        SettingsSwitchTile(
          icon: Icons.notifications_active_outlined,
          title: 'Push Notifications',
          subtitle: 'Receive notifications in the app',
          value: _currentSettings?.notifications.pushEnabled ?? true,
          onChanged: (value) {
            final newNotifications = _currentSettings!.notifications.copyWith(pushEnabled: value);
            _updateSettings(_currentSettings!.copyWith(notifications: newNotifications));
          },
        ),
        SettingsSwitchTile(
          icon: Icons.mail_outline_rounded,
          title: 'Email Notifications',
          subtitle: 'Receive notifications via email',
          value: _currentSettings?.notifications.emailEnabled ?? false,
          onChanged: (value) {
            final newNotifications = _currentSettings!.notifications.copyWith(emailEnabled: value);
            _updateSettings(_currentSettings!.copyWith(notifications: newNotifications));
          },
        ),
      ],
    );
  }

  Widget _buildChannelSettings(BuildContext context) {
    final channels = _currentSettings?.notifications.channels ?? const NotificationChannels();
    final pushEnabled = _currentSettings?.notifications.pushEnabled ?? true;
    final emailEnabled = _currentSettings?.notifications.emailEnabled ?? false;
    final anyEnabled = pushEnabled || emailEnabled;

    void updateChannels(NotificationChannels newChannels) {
      final newNotifications = _currentSettings!.notifications.copyWith(channels: newChannels);
      _updateSettings(_currentSettings!.copyWith(notifications: newNotifications));
    }

    return SettingsGroup(
      eyebrow: 'Events',
      title: 'Notification Channels',
      subtitle: anyEnabled
          ? 'Choose which events trigger notifications'
          : 'Enable push or email notifications above to configure channels',
      children: [
        _buildChannelToggle(
          'Assignment Notifications',
          'When enquiries are assigned to you',
          Icons.assignment_ind_outlined,
          AppColorScheme.statusNew,
          channels.assignment,
          enabled: anyEnabled,
          onChanged: (value) => updateChannels(channels.copyWith(assignment: value)),
        ),
        _buildChannelToggle(
          'Status Changes',
          'When enquiry status is updated',
          Icons.update_rounded,
          AppColorScheme.statusInTalks,
          channels.statusChange,
          enabled: anyEnabled,
          onChanged: (value) => updateChannels(channels.copyWith(statusChange: value)),
        ),
        _buildChannelToggle(
          'Payment Updates',
          'When payment status changes',
          Icons.payments_outlined,
          AppColorScheme.statusConfirmed,
          channels.payment,
          enabled: anyEnabled,
          onChanged: (value) => updateChannels(channels.copyWith(payment: value)),
        ),
        _buildChannelToggle(
          'Reminders',
          'Follow-up and deadline reminders',
          Icons.alarm_rounded,
          AppColorScheme.statusQuoteSent,
          channels.reminders,
          enabled: anyEnabled,
          onChanged: (value) => updateChannels(channels.copyWith(reminders: value)),
        ),
      ],
    );
  }

  Widget _buildChannelToggle(
    String title,
    String subtitle,
    IconData icon,
    Color tint,
    bool value, {
    required bool enabled,
    required ValueChanged<bool> onChanged,
  }) {
    return SettingsSwitchTile(
      icon: icon,
      iconColor: tint,
      title: title,
      subtitle: subtitle,
      value: value,
      onChanged: enabled ? onChanged : null,
    );
  }

  Widget _buildInfoSection(BuildContext context) {
    return const SettingsNote(
      title: 'Important Notes',
      items: [
        'Push notifications require browser permission. You may need to allow notifications in your browser settings.',
        'Email notifications depend on admin settings and may not be available for all events.',
        'Changes take effect immediately but may take a few minutes to apply to all services.',
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
        backgroundColor: isError ? AppColorScheme.snackError : AppColorScheme.snackSuccess,
        action: SnackBarAction(label: 'OK', textColor: Colors.white, onPressed: () {}),
      ),
    );
  }
}
