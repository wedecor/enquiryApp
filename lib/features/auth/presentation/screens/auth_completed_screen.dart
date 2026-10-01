import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../ui/components/gradient_pill_button.dart';
import '../widgets/auth_status_view.dart';

/// Screen shown after password reset completion
class AuthCompletedScreen extends StatelessWidget {
  const AuthCompletedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AuthStatusView(
      icon: Icons.check_circle_outline_rounded,
      tone: AppColorScheme.snackSuccess,
      eyebrow: 'All set',
      title: 'Password Reset Complete',
      message:
          'Your password has been successfully updated.\nYou can now sign in with your new password.',
      actions: [
        GradientPillButton(
          label: 'Go to Sign In',
          icon: Icons.arrow_forward_rounded,
          onPressed: () {
            Navigator.of(context).pushReplacementNamed('/login');
          },
        ),
      ],
    );
  }
}
