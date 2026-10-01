import 'package:flutter/material.dart';

import '../../../../../core/theme/tokens.dart';
import '../../../../../ui/components/gradient_pill_button.dart';

/// Admin-only primary actions: gold "Invite" and ink "Add User" pills.
class UsersAdminActions extends StatelessWidget {
  const UsersAdminActions({super.key, required this.onInvite, required this.onAddUser});

  final VoidCallback onInvite;
  final VoidCallback onAddUser;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: GradientPillButton(
            label: 'Invite',
            icon: Icons.mail_outline_rounded,
            accent: true,
            onPressed: onInvite,
          ),
        ),
        const SizedBox(width: AppTokens.space3),
        Expanded(
          child: GradientPillButton(
            label: 'Add User',
            icon: Icons.person_add_alt_1_rounded,
            onPressed: onAddUser,
          ),
        ),
      ],
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
