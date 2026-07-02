import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/auth/session_state.dart';
import '../../../../core/logging/safe_log.dart';
import '../../../../core/navigation/app_shell.dart';
import '../../../../core/notifications/fcm_token_manager.dart';
import '../../../../core/services/firestore_service.dart';
import '../../../../core/services/session_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../screens/login_screen.dart';

/// Root authentication gate that handles all session states
class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionAsync = ref.watch(sessionStateProvider);

    return sessionAsync.when(
      data: (session) => _buildForSessionState(context, ref, session),
      loading: () => _buildLoadingScreen(context, 'Initializing...'),
      error: (error, stack) =>
          _buildErrorScreen(context, ref, 'Initialization failed: $error'),
    );
  }

  Widget _buildForSessionState(
    BuildContext context,
    WidgetRef ref,
    SessionState session,
  ) {
    return session.when(
      unauthenticated: () => const LoginScreen(),
      loading: (reason) =>
          _buildLoadingScreen(context, _getLoadingMessage(reason)),
      authenticated: (user, profile) => Column(
        children: [
          if (kDebugMode)
            _buildDebugBanner(context, 'Authenticated: ${profile.role.name}'),
          if (kDebugMode) _buildAndroidConfigBanner(context),
          const Expanded(child: AppShell()),
        ],
      ),
      unprovisioned: (email) => _buildUnprovisionedScreen(context, ref, email),
      disabled: (email) => _buildDisabledScreen(context, ref, email),
      error: (message, cause) =>
          _buildErrorScreen(context, ref, message, cause),
    );
  }

  Widget _buildLoadingScreen(BuildContext context, String message) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 24),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUnprovisionedScreen(
    BuildContext context,
    WidgetRef ref,
    String email,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.person_off,
                size: 64,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 24),

              Text(
                'Account Not Provisioned',
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              Text(
                'Your account ($email) is signed in but not yet provisioned for WeDecor Events.',
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: colorScheme.primary.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: colorScheme.primary),
                        const SizedBox(width: 8),
                        const Text(
                          'Next Steps',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '1. Contact your administrator to invite/activate your account\n'
                      '2. Provide your email address for account setup\n'
                      '3. Wait for invitation email with setup instructions',
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _copyEmail(context, email),
                      icon: const Icon(Icons.copy),
                      label: const Text('Copy Email'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _signOut(context, ref),
                      icon: const Icon(Icons.logout),
                      label: const Text('Sign Out'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColorScheme.snackError,
                        foregroundColor: colorScheme.onError,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDisabledScreen(
    BuildContext context,
    WidgetRef ref,
    String email,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.block, size: 64, color: colorScheme.error),
              const SizedBox(height: 24),

              Text(
                'Access Disabled',
                style: Theme.of(
                  context,
                ).textTheme.headlineMedium?.copyWith(color: colorScheme.error),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              Text(
                'Your account ($email) access has been disabled.',
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: colorScheme.error.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(Icons.support_agent, color: colorScheme.error),
                        const SizedBox(width: 8),
                        const Text(
                          'Contact Support',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Please contact your administrator to reactivate your account or discuss access requirements.',
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _signOut(context, ref),
                  icon: const Icon(Icons.logout),
                  label: const Text('Sign Out'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColorScheme.snackError,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorScreen(
    BuildContext context,
    WidgetRef ref,
    String message, [
    Object? cause,
  ]) {
    final colorScheme = Theme.of(context).colorScheme;
    final warningColor = AppColorScheme.snackWarning;
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: warningColor),
              const SizedBox(height: 24),

              Text(
                'Authentication Error',
                style: Theme.of(
                  context,
                ).textTheme.headlineMedium?.copyWith(color: warningColor),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              Text(
                message,
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),

              if (kDebugMode && cause != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Debug: ${cause.toString()}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 32),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _retry(context),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _signOut(context, ref),
                      icon: const Icon(Icons.logout),
                      label: const Text('Sign Out'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDebugBanner(BuildContext context, String info) {
    final warningColor = AppColorScheme.warning;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: AppColorScheme.warningContainerLight,
      child: Row(
        children: [
          Icon(Icons.bug_report, size: 16, color: warningColor),
          const SizedBox(width: 8),
          Text(
            'DEBUG: $info',
            style: TextStyle(
              fontSize: 12,
              color: warningColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _getLoadingMessage(String? reason) {
    switch (reason) {
      case 'sync_profile':
        return 'Syncing your profile...';
      case 'auth_check':
        return 'Checking authentication...';
      default:
        return 'Loading...';
    }
  }

  void _copyEmail(BuildContext context, String email) {
    Clipboard.setData(ClipboardData(text: email));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Email copied: $email'),
        backgroundColor: AppColorScheme.snackSuccess,
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {},
        ),
      ),
    );
  }

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    try {
      await FcmTokenManager.removeCurrentToken(
        ref.read(firestoreServiceProvider),
      );
      await FirebaseAuth.instance.signOut();
      safeLog('user_signed_out', {'method': 'auth_gate'});
    } catch (e) {
      safeLog('sign_out_error', {'error': e.toString(), 'method': 'auth_gate'});

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sign out failed: ${e.toString()}'),
            backgroundColor: AppColorScheme.snackError,
          ),
        );
      }
    }
  }

  void _retry(BuildContext context) {
    // Trigger a refresh by signing out and back in
    // Or implement a manual session refresh if needed
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Retrying authentication...'),
        backgroundColor: AppColorScheme.info,
      ),
    );
  }

  Widget _buildAndroidConfigBanner(BuildContext context) {
    try {
      final app = Firebase.app();
      final projectId = app.options.projectId;

      // Check if project ID matches expected
      if (projectId != 'wedecorenquries') {
        safeLog('android_config_mismatch', {
          'expectedProjectId': 'wedecorenquries',
          'actualProjectId': projectId,
          'platform': 'android',
        });

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: AppColorScheme.warningContainerLight,
          child: Row(
            children: [
              Icon(Icons.warning, size: 16, color: AppColorScheme.warning),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'DEBUG: Project ID mismatch - Expected: wedecorenquries, Got: $projectId',
                  style: TextStyle(fontSize: 12, color: AppColorScheme.warning),
                ),
              ),
            ],
          ),
        );
      }

      return const SizedBox.shrink();
    } catch (e) {
      return const SizedBox.shrink();
    }
  }
}
