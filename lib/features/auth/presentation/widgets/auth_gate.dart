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
import '../../../../core/theme/tokens.dart';
import '../../../../ui/components/brand_mark.dart';
import '../../../../ui/components/gradient_pill_button.dart';
import '../screens/login_screen.dart';
import 'auth_backdrop.dart';
import 'auth_status_view.dart';

/// Root authentication gate that handles all session states
class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionAsync = ref.watch(sessionStateProvider);

    return sessionAsync.when(
      data: (session) => _buildForSessionState(context, ref, session),
      loading: () => _buildLoadingScreen(context, 'Initializing...'),
      error: (error, stack) => _buildErrorScreen(context, ref, 'Initialization failed: $error'),
    );
  }

  Widget _buildForSessionState(BuildContext context, WidgetRef ref, SessionState session) {
    return session.when(
      unauthenticated: () => const LoginScreen(),
      loading: (reason) => _buildLoadingScreen(context, _getLoadingMessage(reason)),
      authenticated: (user, profile) => Column(
        children: [
          if (kDebugMode) _buildDebugBanner(context, 'Authenticated: ${profile.role.name}'),
          if (kDebugMode) _buildAndroidConfigBanner(context),
          const Expanded(child: AppShell()),
        ],
      ),
      unprovisioned: (email) => _buildUnprovisionedScreen(context, ref, email),
      disabled: (email) => _buildDisabledScreen(context, ref, email),
      error: (message, cause) => _buildErrorScreen(context, ref, message, cause),
    );
  }

  Widget _buildLoadingScreen(BuildContext context, String message) {
    return AuthBackdrop(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const BrandMark(size: 48, showSubtitle: true),
              const SizedBox(height: AppTokens.space8),
              const SizedBox.square(
                dimension: 28,
                child: CircularProgressIndicator(strokeWidth: 2.4),
              ),
              const SizedBox(height: AppTokens.space4),
              Text(
                message,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w300),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUnprovisionedScreen(BuildContext context, WidgetRef ref, String email) {
    final colorScheme = Theme.of(context).colorScheme;
    final tone = AppSurfaces.of(context).accentInk;
    return AuthStatusView(
      icon: Icons.person_off_outlined,
      tone: tone,
      eyebrow: 'Almost there',
      title: 'Account Not Provisioned',
      message: 'Your account ($email) is signed in but not yet provisioned for WeDecor Events.',
      details: [
        AuthInfoBlock(
          icon: Icons.info_outline_rounded,
          title: 'Next Steps',
          tone: tone,
          body:
              '1. Contact your administrator to invite/activate your account\n'
              '2. Provide your email address for account setup\n'
              '3. Wait for invitation email with setup instructions',
        ),
      ],
      actions: [
        GradientPillButton(
          label: 'Copy Email',
          icon: Icons.copy_rounded,
          onPressed: () => _copyEmail(context, email),
        ),
        AuthOutlinedPill(
          label: 'Sign Out',
          icon: Icons.logout_rounded,
          color: colorScheme.error,
          onPressed: () => _signOut(context, ref),
        ),
      ],
    );
  }

  Widget _buildDisabledScreen(BuildContext context, WidgetRef ref, String email) {
    final colorScheme = Theme.of(context).colorScheme;
    return AuthStatusView(
      icon: Icons.block_rounded,
      tone: colorScheme.error,
      eyebrow: 'Account paused',
      title: 'Access Disabled',
      message: 'Your account ($email) access has been disabled.',
      details: [
        AuthInfoBlock(
          icon: Icons.support_agent_rounded,
          title: 'Contact Support',
          tone: colorScheme.error,
          body:
              'Please contact your administrator to reactivate your account or discuss access requirements.',
        ),
      ],
      actions: [
        AuthOutlinedPill(
          label: 'Sign Out',
          icon: Icons.logout_rounded,
          color: colorScheme.error,
          onPressed: () => _signOut(context, ref),
        ),
      ],
    );
  }

  Widget _buildErrorScreen(BuildContext context, WidgetRef ref, String message, [Object? cause]) {
    final s = AppSurfaces.of(context);
    return AuthStatusView(
      icon: Icons.error_outline_rounded,
      tone: AppColorScheme.snackWarning,
      eyebrow: 'Something went wrong',
      title: 'Authentication Error',
      message: message,
      details: [
        if (kDebugMode && cause != null)
          DecoratedBox(
            decoration: BoxDecoration(
              color: s.glassFillStrong,
              borderRadius: AppRadius.medium,
              border: Border.all(color: s.microBorder),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppTokens.space3),
              child: Text(
                'Debug: ${cause.toString()}',
                style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
              ),
            ),
          ),
      ],
      actions: [
        GradientPillButton(
          label: 'Retry',
          icon: Icons.refresh_rounded,
          onPressed: () => _retry(ref),
        ),
        AuthOutlinedPill(
          label: 'Sign Out',
          icon: Icons.logout_rounded,
          onPressed: () => _signOut(context, ref),
        ),
      ],
    );
  }

  Widget _buildDebugBanner(BuildContext context, String info) {
    const warningColor = AppColorScheme.warning;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: warningColor.withValues(alpha: 0.12),
      child: Row(
        children: [
          const Icon(Icons.bug_report, size: 16, color: warningColor),
          const SizedBox(width: 8),
          Text(
            'DEBUG: $info',
            style: const TextStyle(fontSize: 12, color: warningColor, fontWeight: FontWeight.w500),
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
        action: SnackBarAction(label: 'OK', textColor: Colors.white, onPressed: () {}),
      ),
    );
  }

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    try {
      await FcmTokenManager.removeCurrentToken(ref.read(firestoreServiceProvider));
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

  void _retry(WidgetRef ref) {
    safeLog('session_retry', {'method': 'auth_gate'});
    // Recreate the session service: it re-subscribes to auth state and
    // re-fetches the profile (sessionStateProvider rebuilds with it).
    ref.invalidate(sessionServiceProvider);
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
          color: AppColorScheme.warning.withValues(alpha: 0.12),
          child: Row(
            children: [
              const Icon(Icons.warning, size: 16, color: AppColorScheme.warning),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'DEBUG: Project ID mismatch - Expected: wedecorenquries, Got: $projectId',
                  style: const TextStyle(fontSize: 12, color: AppColorScheme.warning),
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
