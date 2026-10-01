import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/theme/tokens.dart';
import '../../../../../ui/primitives/primitives.dart';
import '../../../../admin/analytics/presentation/analytics_screen.dart';
import '../../../../admin/dropdowns/presentation/dropdown_management_screen.dart';
import '../../../../admin/users/presentation/user_management_screen.dart';
import '../../widgets/settings_layout.dart';
import '../../widgets/settings_tiles.dart';

class DataIntegrationsTab extends ConsumerWidget {
  const DataIntegrationsTab({super.key});

  static const _vapidKey =
      'BKmvRVlG_poi0It85Ooupfs2e8ylBJ4me4TLUhqiIVC7OSnxXK1ctR1gGP1emUgaJJ8z7MzHgZFCe5MsMWnIY7E';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context).textTheme;
    return SettingsScrollBody(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(AppTokens.space1, AppTokens.space5, 0, 0),
          child: SplitHeading(light: 'Data &', bold: 'Integrations', style: t.headlineMedium),
        ),
        SettingsGroup(
          eyebrow: 'Tools',
          title: 'Data Management',
          children: [
            SettingsTile(
              icon: Icons.list_alt_rounded,
              iconColor: AppColorScheme.chartPurple,
              title: 'Dropdown Manager',
              subtitle: 'Manage event types, sources, and other dropdowns',
              trailing: const SettingsChevron(),
              onTap: () {
                Navigator.of(
                  context,
                ).push(MaterialPageRoute<void>(builder: (_) => const DropdownManagementScreen()));
              },
            ),
            SettingsTile(
              icon: Icons.group_outlined,
              iconColor: AppColorScheme.chartBlue,
              title: 'User Management',
              subtitle: 'Manage users, roles, and permissions',
              trailing: const SettingsChevron(),
              onTap: () {
                Navigator.of(
                  context,
                ).push(MaterialPageRoute<void>(builder: (_) => const UserManagementScreen()));
              },
            ),
            SettingsTile(
              icon: Icons.insights_rounded,
              iconColor: AppColorScheme.chartGreen,
              title: 'Analytics',
              subtitle: 'View detailed analytics and reports',
              trailing: const SettingsChevron(),
              onTap: () {
                Navigator.of(
                  context,
                ).push(MaterialPageRoute<void>(builder: (_) => const AnalyticsScreen()));
              },
            ),
          ],
        ),
        SettingsGroup(
          eyebrow: 'Messaging',
          title: 'Push Notifications',
          children: [
            SettingsTile(
              icon: Icons.key_rounded,
              title: 'VAPID Public Key',
              subtitle: _vapidKey,
              subtitleMaxLines: 2,
              subtitleStyle: t.bodySmall?.copyWith(fontFamily: 'monospace', height: 1.35),
              trailing: IconButton(
                icon: const Icon(Icons.copy_rounded),
                tooltip: 'Copy',
                onPressed: () {
                  Clipboard.setData(const ClipboardData(text: _vapidKey));
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('VAPID key copied to clipboard')));
                },
              ),
            ),
            const SettingsTile(
              icon: Icons.location_on_outlined,
              title: 'Region',
              subtitle: 'asia-south1',
            ),
          ],
        ),
        const SettingsGroup(
          eyebrow: 'Housekeeping',
          title: 'Maintenance',
          separated: false,
          children: [
            SettingsTile(
              icon: Icons.auto_fix_high_rounded,
              title: 'Auto-close',
              subtitle: 'Past enquiries are closed automatically each night',
            ),
          ],
        ),
        const SettingsNote(
          title: 'Integration Status',
          child: Column(
            children: [
              _StatusItem(
                title: 'SMTP Email',
                status: 'Active (Gmail)',
                icon: Icons.email_outlined,
              ),
              _StatusItem(
                title: 'Push Notifications',
                status: 'Active (FCM)',
                icon: Icons.notifications_none_rounded,
              ),
              _StatusItem(title: 'Cloud Functions', status: 'Deployed', icon: Icons.cloud_outlined),
              _StatusItem(title: 'Firestore', status: 'Connected', icon: Icons.storage_rounded),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatusItem extends StatelessWidget {
  const _StatusItem({required this.title, required this.status, required this.icon});

  final String title;
  final String status;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    const color = AppColorScheme.chartGreen;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: cs.onSurfaceVariant),
          const SizedBox(width: AppTokens.space2),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: t.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          const StatusDot(color: color, size: 7),
          const SizedBox(width: AppTokens.space2),
          Text(
            status,
            style: t.labelMedium?.copyWith(color: color, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
