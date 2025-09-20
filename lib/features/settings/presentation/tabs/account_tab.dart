import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/auth/current_user_role_provider.dart' as auth_provider;
import '../../../../core/logging/safe_log.dart';
import '../../../../shared/models/user_model.dart';

class AccountTab extends ConsumerWidget {
  const AccountTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUserAsync = ref.watch(auth_provider.currentUserAsyncProvider);
    final currentUserRole = ref.watch(auth_provider.currentUserRoleProvider);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Profile Information',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),

          currentUserAsync.when(
            data: (user) => _buildProfileSection(context, user),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Text('Error loading profile: $error'),
          ),

          const SizedBox(height: 32),

          Text(
            'Role Information',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),

          _buildRoleSection(context, currentUserRole ?? 'staff'),

          const SizedBox(height: 32),

          Text(
            'Account Actions',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),

          _buildActionsSection(context),

          const Spacer(),

          _buildSignOutSection(context),
        ],
      ),
    );
  }

  Widget _buildProfileSection(BuildContext context, UserModel? user) {
    if (user == null) {
      return const Text('No user data available');
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildReadOnlyField('Email', user.email),
            const SizedBox(height: 16),
            _buildReadOnlyField('Name', user.name),
            const SizedBox(height: 16),
            _buildReadOnlyField('Phone', user.phone ?? 'Not provided'),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleSection(BuildContext context, String role) {
    final roleIcon = role == 'admin'
        ? Icons.admin_panel_settings
        : Icons.person;
    final roleColor = role == 'admin' ? Colors.purple : Colors.blue;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(roleIcon, color: roleColor, size: 32),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  role.toUpperCase(),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: roleColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  role == 'admin'
                      ? 'Full system access and user management'
                      : 'Access to assigned enquiries and personal settings',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionsSection(BuildContext context) {
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.lock_reset),
            title: const Text('Change Password'),
            subtitle: const Text('Send password reset email'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () => _sendPasswordReset(context),
          ),
        ],
      ),
    );
  }

  Widget _buildSignOutSection(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => _signOut(context),
        icon: const Icon(Icons.logout),
        label: const Text('Sign Out'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  Widget _buildReadOnlyField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
            color: Colors.grey.shade50,
          ),
          child: Text(value, style: const TextStyle(fontSize: 16)),
        ),
      ],
    );
  }

  Future<void> _sendPasswordReset(BuildContext context) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user?.email == null) {
        _showSnackBar(
          context,
          'No email found for current user',
          isError: true,
        );
        return;
      }

      await FirebaseAuth.instance.sendPasswordResetEmail(email: user!.email!);

      safeLog('password_reset_sent', {
        'userHasEmail': user.email != null,
        'emailVerified': user.emailVerified,
      });

      if (context.mounted) {
        _showSnackBar(context, 'Password reset email sent to ${user.email}');
      }
    } catch (e) {
      safeLog('password_reset_error', {
        'error': e.toString(),
        'errorType': e.runtimeType.toString(),
      });

      if (context.mounted) {
        _showSnackBar(
          context,
          'Failed to send password reset email',
          isError: true,
        );
      }
    }
  }

  Future<void> _signOut(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      safeLog('user_signed_out', {'method': 'settings_account_tab'});

      if (context.mounted) {
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil('/login', (route) => false);
      }
    } catch (e) {
      safeLog('sign_out_error', {
        'error': e.toString(),
        'errorType': e.runtimeType.toString(),
      });

      if (context.mounted) {
        _showSnackBar(context, 'Failed to sign out', isError: true);
      }
    }
  }

  void _showSnackBar(
    BuildContext context,
    String message, {
    bool isError = false,
  }) {
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
