import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../../core/services/firestore_service.dart';
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
              subtitle:
                  'Past approved bookings are marked Completed; open enquiries '
                  'are kept and flagged for follow-up',
            ),
          ],
        ),
        const _RecentlyDeletedGroup(),
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

class _RecentlyDeletedGroup extends ConsumerWidget {
  const _RecentlyDeletedGroup();

  static final _dateFmt = DateFormat('d MMM yyyy');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final service = ref.watch(firestoreServiceProvider);
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: service.watchRecentlyDeletedEnquiries(),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? const [];
        if (docs.isEmpty) {
          return const SettingsGroup(
            eyebrow: 'Trash',
            title: 'Recently deleted',
            separated: false,
            children: [
              SettingsTile(
                icon: Icons.delete_outline_rounded,
                title: 'No deleted enquiries',
                subtitle: 'Deleted enquiries appear here and can be restored.',
              ),
            ],
          );
        }
        return SettingsGroup(
          eyebrow: 'Trash',
          title: 'Recently deleted',
          children: [
            for (final doc in docs) _DeletedEnquiryTile(doc: doc, dateFmt: _dateFmt),
          ],
        );
      },
    );
  }
}

class _DeletedEnquiryTile extends ConsumerStatefulWidget {
  const _DeletedEnquiryTile({required this.doc, required this.dateFmt});

  final QueryDocumentSnapshot<Map<String, dynamic>> doc;
  final DateFormat dateFmt;

  @override
  ConsumerState<_DeletedEnquiryTile> createState() => _DeletedEnquiryTileState();
}

class _DeletedEnquiryTileState extends ConsumerState<_DeletedEnquiryTile> {
  bool _restoring = false;

  Future<void> _restore() async {
    if (_restoring) return;
    setState(() => _restoring = true);
    try {
      await ref.read(firestoreServiceProvider).restoreEnquiry(widget.doc.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Enquiry restored')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to restore enquiry: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _restoring = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.doc.data();
    final enquiry = data['enquiry'] is Map ? data['enquiry'] as Map : const <String, dynamic>{};
    final customerName = (enquiry['customerName'] as String?)?.trim();
    final title = (customerName != null && customerName.isNotEmpty) ? customerName : widget.doc.id;
    final eventDateRaw = enquiry['eventDate'];
    final deletedAtRaw = data['deletedAt'];
    final eventText = eventDateRaw is Timestamp ? widget.dateFmt.format(eventDateRaw.toDate()) : 'No date';
    final deletedText =
        deletedAtRaw is Timestamp ? widget.dateFmt.format(deletedAtRaw.toDate()) : 'Just now';

    return SettingsTile(
      icon: Icons.restore_from_trash_outlined,
      title: title,
      subtitle: 'Event: $eventText · Deleted: $deletedText',
      trailing: TextButton(
        onPressed: _restoring ? null : _restore,
        child: Text(_restoring ? 'Restoring…' : 'Restore'),
      ),
    );
  }
}
