import 'package:flutter/material.dart';

import '../../../../../ui/components/gradient_pill_button.dart';

/// Admin-only primary action. New people are added through the `inviteUser`
/// Cloud Function, which creates their login and emails a set-password link.
/// (A Firestore-only "Add User" form created profiles with no login and no
/// document id, so it was removed.)
class UsersAdminActions extends StatelessWidget {
  const UsersAdminActions({super.key, required this.onInvite});

  final VoidCallback onInvite;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: GradientPillButton(
        label: 'Add / Invite User',
        icon: Icons.person_add_alt_1_rounded,
        accent: true,
        onPressed: onInvite,
      ),
    );
  }
}
