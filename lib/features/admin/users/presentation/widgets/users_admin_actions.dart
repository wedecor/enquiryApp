import 'package:flutter/material.dart';

import '../../../../../core/theme/tokens.dart';
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

/// Centered pagination button; disabled with a spinner while [loading].
class UsersLoadMoreButton extends StatelessWidget {
  const UsersLoadMoreButton({super.key, required this.loading, required this.onPressed});

  final bool loading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppTokens.space3),
      child: Center(
        child: OutlinedButton(
          onPressed: loading ? null : onPressed,
          child: loading
              ? const SizedBox.square(
                  dimension: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Load More...'),
        ),
      ),
    );
  }
}
