import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/logging/safe_log.dart';
import '../../../../../core/services/firestore_service.dart';
import '../../../../../ui/primitives/primitives.dart';
import '../../../domain/app_config.dart';
import '../../../providers/settings_providers.dart';
import '../../../../../ui/components/glass_dialog.dart';
import '../../../../../ui/components/glass_state_message.dart';
import '../../widgets/settings_layout.dart';
import '../../widgets/settings_tiles.dart';

class NotificationConfigTab extends ConsumerWidget {
  const NotificationConfigTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final configAsync = ref.watch(appNotificationConfigProvider);

    return configAsync.when(
      data: (config) => _buildNotificationConfig(context, ref, config),
      loading: () => const GlassLoadingState(),
      error: (error, stack) => GlassStateMessage(
        icon: Icons.error_outline_rounded,
        title: 'Notification settings unavailable',
        message: 'Error loading notification config: $error',
        color: Theme.of(context).colorScheme.error,
      ),
    );
  }

  Widget _buildNotificationConfig(
    BuildContext context,
    WidgetRef ref,
    AppNotificationConfig config,
  ) {
    final followUpsEnabled = ref.watch(followUpsEnabledProvider).valueOrNull ?? true;
    return SettingsScrollBody(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 20, 0, 0),
          child: SplitHeading(
            light: 'Notification',
            bold: 'Settings',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
        ),
        SettingsGroup(
          eyebrow: 'Email',
          title: 'Email Configuration',
          children: [
            SettingsSwitchTile(
              icon: Icons.forward_to_inbox_rounded,
              title: 'Email Invites',
              subtitle: config.emailInvitesEnabled ? 'Enabled' : 'Disabled',
              value: config.emailInvitesEnabled,
              onChanged: (value) async {
                try {
                  final updateConfig = ref.read(updateAppNotificationConfigProvider);
                  await updateConfig(config.copyWith(emailInvitesEnabled: value));
                } catch (e) {
                  safeLog('notification_config_update_error', {
                    'field': 'emailInvitesEnabled',
                    'error': e.toString(),
                  });
                }
              },
            ),
            SettingsTile(
              icon: Icons.reply_rounded,
              title: 'Reply-To Email',
              subtitle: config.replyToEmail,
              trailing: const Icon(Icons.info_outline_rounded),
              onTap: () {
                _showInfoDialog(
                  context,
                  'Reply-To Email',
                  'This email address will be used as the reply-to address for system emails. '
                      'Configure this in your Cloud Functions environment.',
                );
              },
            ),
            SettingsSwitchTile(
              icon: Icons.event_repeat_rounded,
              title: 'Automatic follow-ups',
              subtitle: followUpsEnabled
                  ? 'Open enquiries get follow-up reminders (in-app + push)'
                  : 'Off — no follow-ups are scheduled or reminded',
              value: followUpsEnabled,
              onChanged: (value) async {
                try {
                  await ref.read(appConfigServiceProvider).setFollowUpsEnabled(value);
                } catch (e) {
                  safeLog('notification_config_update_error', {
                    'field': 'followUpsEnabled',
                    'error': e.toString(),
                  });
                }
              },
            ),
            _WebsiteAssigneeTile(),
            SettingsTile(
              icon: Icons.alarm_rounded,
              title: 'Follow-up every',
              subtitle:
                  'First reminder: next morning at 10:00 IST. After each completed '
                  'follow-up: every ${config.reminderDaysDefault} days. Overdue after 24 h',
              trailing: const Icon(Icons.edit_outlined),
              onTap: () => _showReminderDaysDialog(context, ref, config),
            ),
          ],
        ),
        const SettingsNote(
          title: 'SMTP Status',
          body:
              'SMTP is configured in Cloud Functions via Secret Manager '
              '(SMTP_PASS) and environment variables (SMTP_USER, SMTP_HOST). '
              'Invite emails send only when those values are set on deploy.',
        ),
      ],
    );
  }

  void _showInfoDialog(BuildContext context, String title, String message) {
    showDialog<void>(
      context: context,
      builder: (context) => GlassDialog(
        icon: Icons.info_outline_rounded,
        title: title,
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('OK')),
        ],
      ),
    );
  }

  void _showReminderDaysDialog(BuildContext context, WidgetRef ref, AppNotificationConfig config) {
    final controller = TextEditingController(text: config.reminderDaysDefault.toString());

    showDialog<void>(
      context: context,
      builder: (context) => GlassDialog(
        icon: Icons.alarm_rounded,
        title: 'Days between follow-ups (after one is done)',
        content: TextFormField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Days'),
          validator: (value) {
            final days = int.tryParse(value ?? '');
            if (days == null || days < 1 || days > 30) {
              return 'Must be between 1 and 30 days';
            }
            return null;
          },
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              final days = int.tryParse(controller.text);
              if (days != null && days >= 1 && days <= 30) {
                final navigator = Navigator.of(context);
                try {
                  final updateConfig = ref.read(updateAppNotificationConfigProvider);
                  await updateConfig(config.copyWith(reminderDaysDefault: days));
                  navigator.pop();
                } catch (e) {
                  safeLog('reminder_days_update_error', {'error': e.toString()});
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

/// "Website enquiries go to" — `app_config/notifications.websiteAssigneeUid`, read by
/// the websiteLead function. "No one" leaves website enquiries unassigned (admins
/// are still notified); an inactive pick is treated the same way by the server.
class _WebsiteAssigneeTile extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = ref.watch(websiteAssigneeUidProvider).valueOrNull;
    final users = ref.watch(activeUsersProvider).valueOrNull;
    String? nameOf(String id) {
      for (final doc in users?.docs ?? const <QueryDocumentSnapshot>[]) {
        if (doc.id == id) return (doc.data() as Map<String, dynamic>)['name'] as String?;
      }
      return null;
    }

    final subtitle = uid == null
        ? 'No one — website enquiries stay unassigned; admins are notified'
        : (nameOf(uid) ?? 'A user who is no longer active — enquiries stay unassigned');
    return SettingsTile(
      icon: Icons.language_rounded,
      title: 'Website enquiries go to',
      subtitle: subtitle,
      trailing: const Icon(Icons.edit_outlined),
      onTap: users == null ? null : () => _pick(context, ref, users, uid),
    );
  }

  Future<void> _pick(
    BuildContext context,
    WidgetRef ref,
    QuerySnapshot users,
    String? current,
  ) async {
    // Sentinel for "No one" (a null pop means the dialog was dismissed).
    const none = '';
    final picked = await showDialog<String>(
      context: context,
      builder: (context) => GlassDialog(
        icon: Icons.language_rounded,
        title: 'Website enquiries go to',
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: [
              ListTile(
                onTap: () => Navigator.of(context).pop(none),
                title: const Text('No one (admins only)'),
                trailing: current == null ? const Icon(Icons.check_rounded) : null,
              ),
              for (final doc in users.docs)
                ListTile(
                  onTap: () => Navigator.of(context).pop(doc.id),
                  title: Text(
                    ((doc.data() as Map<String, dynamic>)['name'] as String?) ?? 'Unnamed',
                  ),
                  subtitle: Text(((doc.data() as Map<String, dynamic>)['role'] as String?) ?? ''),
                  trailing: current == doc.id ? const Icon(Icons.check_rounded) : null,
                ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        ],
      ),
    );
    if (picked == null) return;
    try {
      await ref
          .read(appConfigServiceProvider)
          .setWebsiteAssigneeUid(picked == none ? null : picked);
    } catch (e) {
      safeLog('notification_config_update_error', {
        'field': 'websiteAssigneeUid',
        'error': e.toString(),
      });
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not save the website assignee. Please try again.')),
        );
      }
    }
  }
}
