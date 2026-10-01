import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/role_provider.dart';
import '../../../../core/services/firestore_service.dart';
import 'settings_layout.dart';
import 'settings_tiles.dart';

/// `users/{uid}/settings/preferences.weeklyDigest` — read by the `weeklyDigest`
/// Cloud Function. Missing means on.
final _weeklyDigestProvider = StreamProvider.autoDispose.family<bool, String>((ref, uid) {
  return ref
      .watch(firestoreServiceProvider)
      .firestore
      .collection('users')
      .doc(uid)
      .collection('settings')
      .doc('preferences')
      .snapshots()
      .map((doc) => doc.data()?['weeklyDigest'] != false);
});

/// Admin-only switch for the Monday analytics digest email. Saves immediately.
class WeeklyDigestSettingsGroup extends ConsumerWidget {
  const WeeklyDigestSettingsGroup({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAdmin = ref.watch(isAdminProvider);
    final uid = ref.watch(currentUserWithFirestoreProvider).valueOrNull?.uid;
    if (!isAdmin || uid == null) return const SizedBox.shrink();

    final enabled = ref.watch(_weeklyDigestProvider(uid)).valueOrNull ?? true;

    return SettingsGroup(
      eyebrow: 'Reports',
      title: 'Weekly Digest',
      subtitle: 'A Monday-morning email with last week\'s numbers',
      children: [
        SettingsSwitchTile(
          icon: Icons.insights_outlined,
          title: 'Email weekly digest',
          subtitle: 'New enquiries, response time, wins/losses, follow-ups due and upcoming balances',
          value: enabled,
          onChanged: (value) async {
            try {
              await ref
                  .read(firestoreServiceProvider)
                  .firestore
                  .collection('users')
                  .doc(uid)
                  .collection('settings')
                  .doc('preferences')
                  .set({'weeklyDigest': value}, SetOptions(merge: true));
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('Could not save: $e')));
              }
            }
          },
        ),
      ],
    );
  }
}
