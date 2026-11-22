import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/contacts/whatsapp_contacts.dart';
import '../../../../../core/providers/role_provider.dart';
import '../../../../../core/services/firestore_service.dart';
import '../../../../../core/theme/tokens.dart';
import '../../../../../shared/widgets/confirmation_dialog.dart';
import '../../widgets/settings_layout.dart';
import '../../widgets/settings_tiles.dart';

/// Device-local switch + bulk sync for saving customers as contacts.
class SaveCustomersToContactsSetting extends ConsumerStatefulWidget {
  const SaveCustomersToContactsSetting({super.key});

  @override
  ConsumerState<SaveCustomersToContactsSetting> createState() =>
      _SaveCustomersToContactsSettingState();
}

class _SaveCustomersToContactsSettingState extends ConsumerState<SaveCustomersToContactsSetting> {
  bool? _enabled;
  bool _busy = false;
  bool _syncing = false;

  bool get _isAndroid => !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final on = await WhatsAppContacts.isFeatureEnabled();
    if (!mounted) return;
    setState(() => _enabled = on);
  }

  Future<void> _onChanged(bool value) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _enabled = value;
    });
    await WhatsAppContacts.setFeatureEnabled(value);
    if (value && mounted) {
      await WhatsAppContacts.ensurePermission(context);
    }
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _syncAll() async {
    if (!_isAndroid || _syncing) return;

    setState(() => _syncing = true);
    try {
      final isAdmin = ref.read(isAdminProvider);
      final uid = ref.read(currentUserWithFirestoreProvider).valueOrNull?.uid;
      if (!isAdmin && (uid == null || uid.isEmpty)) {
        _snack('Sign in to sync contacts');
        return;
      }

      final firestore = ref.read(firestoreServiceProvider);
      final drafts = <CustomerContactDraft>[];
      await for (final page in firestore.fetchEnquiriesForRole(
        isAdmin: isAdmin,
        assignedToUid: isAdmin ? null : uid,
      )) {
        for (final row in page) {
          final draft = CustomerContactDraft.fromEnquiry(row);
          if (draft != null) drafts.add(draft);
        }
      }

      final unique = WhatsAppContacts.dedupeCustomers(drafts);
      if (!mounted) return;

      if (unique.isEmpty) {
        _snack('No customer numbers to sync');
        return;
      }

      final proceed = await ConfirmationDialog.show(
        context: context,
        title: 'Sync contacts?',
        message:
            'Save ${unique.length} customer number${unique.length == 1 ? '' : 's'} '
            'to this phone\'s contacts? Numbers already saved are skipped. '
            'They stay on this phone only.',
        confirmText: 'Sync',
        cancelText: 'Cancel',
        icon: Icons.sync_rounded,
      );
      if (!proceed || !mounted) return;

      final canUse = await WhatsAppContacts.ensurePermission(context, explicit: true);
      if (!canUse || !mounted) {
        _snack('Contacts permission needed to sync');
        return;
      }

      final progress = ValueNotifier<(int, int)>((0, unique.length));
      unawaited(
        showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) {
            return PopScope(
              canPop: false,
              child: AlertDialog(
                title: const Text('Syncing contacts'),
                content: ValueListenableBuilder<(int, int)>(
                  valueListenable: progress,
                  builder: (context, value, _) {
                    final done = value.$1;
                    final total = value.$2;
                    final fraction = total == 0 ? 0.0 : done / total;
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        LinearProgressIndicator(value: fraction),
                        const SizedBox(height: AppTokens.space3),
                        Text('$done of $total'),
                      ],
                    );
                  },
                ),
              ),
            );
          },
        ),
      );

      final result = await WhatsAppContacts.syncCustomersToDevice(
        context: context,
        customers: unique,
        assumePermission: true,
        onProgress: (done, total) {
          progress.value = (done, total);
        },
      );

      if (mounted && Navigator.of(context, rootNavigator: true).canPop()) {
        Navigator.of(context, rootNavigator: true).pop();
      }
      progress.dispose();
      if (!mounted) return;
      _snack(result.summaryMessage);
    } catch (e) {
      if (mounted && Navigator.of(context, rootNavigator: true).canPop()) {
        Navigator.of(context, rootNavigator: true).pop();
      }
      if (mounted) _snack('Could not sync contacts');
    } finally {
      if (mounted) setState(() => _syncing = false);
    }
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final value = _enabled;
    if (value == null) {
      return const SizedBox.shrink();
    }

    return SettingsGroup(
      eyebrow: 'WhatsApp',
      title: 'Customer contacts',
      subtitle: 'Saved into your phone Contacts (Google or Phone/Device)',
      separated: false,
      padding: const EdgeInsets.all(AppTokens.space4),
      children: [
        SettingsSwitchTile(
          title: 'Save customers to contacts',
          subtitle:
              'When you save an enquiry, add their number to this phone '
              '(name – We Decor · event date).',
          icon: Icons.contact_page_outlined,
          value: value,
          onChanged: _busy || _syncing ? null : _onChanged,
        ),
        if (_isAndroid)
          SettingsTile(
            title: 'Sync all customers to this phone',
            subtitle: _syncing ? 'Syncing…' : 'Pull every enquiry number you can see into Contacts',
            icon: Icons.sync_rounded,
            enabled: !_syncing && !_busy,
            onTap: _syncing || _busy ? null : _syncAll,
            trailing: _syncing
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const SettingsChevron(),
          ),
      ],
    );
  }
}
