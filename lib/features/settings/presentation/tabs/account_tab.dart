import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../../core/logging/safe_log.dart';
import '../../../../core/providers/role_provider.dart';
import '../../../../core/services/firebase_auth_service.dart' show firebaseAuthServiceProvider;
import '../../../../core/services/update_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../shared/models/user_model.dart';
import '../../../../ui/components/glass_dialog.dart';
import '../../../admin/users/presentation/user_management_screen.dart';
import '../widgets/settings_layout.dart';
import '../widgets/settings_tiles.dart';
import 'widgets/account_sections.dart';
import 'widgets/change_password_dialog.dart';

class AccountTab extends ConsumerWidget {
  const AccountTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUserAsync = ref.watch(currentUserWithFirestoreProvider);
    final currentUserRole = ref.watch(roleProvider);

    return SettingsScrollBody(
      children: [
        SettingsGroup(
          eyebrow: 'You',
          title: 'Profile Information',
          separated: false,
          children: [
            currentUserAsync.when(
              data: (user) => user == null
                  ? const SettingsTile(title: 'No user data available')
                  : AccountProfileRows(user: user),
              loading: () => const SettingsLoadingBlock(),
              error: (error, stack) => SettingsTile(
                icon: Icons.error_outline_rounded,
                iconColor: Theme.of(context).colorScheme.error,
                title: 'Error loading profile: $error',
              ),
            ),
          ],
        ),
        SettingsGroup(
          eyebrow: 'Access',
          title: 'Role Information',
          children: [
            currentUserRole.when(
              data: (role) => AccountRoleRow(role: role == UserRole.admin ? 'admin' : 'staff'),
              loading: () => const SettingsLoadingBlock(),
              error: (error, stack) => const AccountRoleRow(role: 'staff'),
            ),
          ],
        ),
        if (currentUserRole.valueOrNull == UserRole.admin)
          SettingsGroup(
            eyebrow: 'Team',
            title: 'Manage Users',
            children: [
              SettingsTile(
                icon: Icons.group_outlined,
                title: 'Team members',
                subtitle: 'Edit name, phone, role or deactivate anyone',
                trailing: const SettingsChevron(),
                onTap: () => Navigator.of(
                  context,
                ).push(MaterialPageRoute<void>(builder: (_) => const UserManagementScreen())),
              ),
            ],
          ),
        SettingsGroup(
          eyebrow: 'Security',
          title: 'Account Actions',
          children: [
            SettingsTile(
              icon: Icons.lock_reset_rounded,
              title: 'Change Password',
              subtitle: 'Enter your current password and pick a new one',
              trailing: const SettingsChevron(),
              onTap: () => _changePassword(context),
            ),
            SettingsTile(
              icon: Icons.system_update_rounded,
              title: 'Check for Updates',
              subtitle: 'Check if a newer version is available',
              trailing: const SettingsChevron(),
              onTap: () => _checkForUpdates(context),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(top: AppTokens.space8),
          child: AccountSignOutButton(onTap: () => _signOut(context, ref)),
        ),
      ],
    );
  }

  Future<void> _changePassword(BuildContext context) async {
    final changed = await showDialog<bool>(
      context: context,
      builder: (_) => ChangePasswordDialog(onForgotPassword: () => _sendPasswordReset(context)),
    );
    if (changed == true && context.mounted) {
      safeLog('password_changed', {'method': 'settings_account_tab'});
      _showSnackBar(context, 'Password updated');
    }
  }

  Future<void> _sendPasswordReset(BuildContext context) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user?.email == null) {
        _showSnackBar(context, 'No email found for current user', isError: true);
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
        _showSnackBar(context, 'Failed to send password reset email', isError: true);
      }
    }
  }

  Future<void> _checkForUpdates(BuildContext context) async {
    if (!UpdateService.isSupportedPlatform) {
      _showSnackBar(context, 'In-app updates are available only in the Android app.');
      return;
    }
    try {
      // Show loading indicator
      unawaited(
        showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (context) => const GlassDialog(
            content: Row(
              children: [
                SizedBox.square(dimension: 24, child: CircularProgressIndicator(strokeWidth: 2)),
                SizedBox(width: AppTokens.space4),
                Expanded(child: Text('Checking for updates...')),
              ],
            ),
          ),
        ),
      );

      // Force check by bypassing rate limiting
      final updateInfo = await UpdateService.checkForUpdate(forceCheck: true);

      // Close loading dialog
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      if (updateInfo != null) {
        // Update available - show update dialog
        if (context.mounted) {
          await UpdateService.showUpdateDialog(context, updateInfo, bypassCooldown: true);
        }
      } else {
        // No updates available - show current version info
        final packageInfo = await PackageInfo.fromPlatform();
        if (context.mounted) {
          unawaited(
            showDialog<void>(
              context: context,
              builder: (context) => GlassDialog(
                icon: Icons.check_circle_outline_rounded,
                iconColor: AppColorScheme.snackSuccess,
                title: 'Up to Date',
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('You\'re running the latest version!'),
                    const SizedBox(height: AppTokens.space2),
                    Text(
                      'Current Version: ${packageInfo.version}+${packageInfo.buildNumber}',
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(fontFamily: 'monospace'),
                    ),
                  ],
                ),
                actions: [
                  TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('OK')),
                ],
              ),
            ),
          );
        }
      }

      safeLog('manual_update_check', {
        'has_update': updateInfo != null,
        'current_version':
            '${(await PackageInfo.fromPlatform()).version}+${(await PackageInfo.fromPlatform()).buildNumber}',
      });
    } catch (e) {
      // Close loading dialog if still open
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      safeLog('manual_update_check_error', {
        'error': e.toString(),
        'errorType': e.runtimeType.toString(),
      });

      if (context.mounted) {
        _showSnackBar(context, 'Failed to check for updates. Please try again.', isError: true);
      }
    }
  }

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    try {
      // Goes through FirebaseAuthService so the FCM token is removed and the
      // next person on this device doesn't receive this user's pushes.
      await ref.read(firebaseAuthServiceProvider).signOut();
      safeLog('user_signed_out', {'method': 'settings_account_tab'});

      // AuthGate shows the login screen; drop any pushed routes above it.
      if (context.mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      safeLog('sign_out_error', {'error': e.toString(), 'errorType': e.runtimeType.toString()});

      if (context.mounted) {
        _showSnackBar(context, 'Failed to sign out', isError: true);
      }
    }
  }

  void _showSnackBar(BuildContext context, String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColorScheme.snackError : AppColorScheme.snackSuccess,
        action: SnackBarAction(
          label: 'OK',
          textColor: Theme.of(context).colorScheme.onPrimary,
          onPressed: () {},
        ),
      ),
    );
  }
}
