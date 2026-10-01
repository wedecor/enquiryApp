import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/firebase_auth_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../ui/components/brand_mark.dart';
import '../../../../ui/primitives/primitives.dart';
import '../../../../ui/components/gradient_pill_button.dart';
import '../widgets/auth_backdrop.dart';

/// Screen for user authentication
class LoginScreen extends ConsumerStatefulWidget {
  /// Creates a LoginScreen
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authService = ref.read(firebaseAuthServiceProvider);
      await authService.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
    } on AuthException catch (e) {
      setState(() {
        _errorMessage = e.message;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'An unexpected error occurred.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _forgotPassword() async {
    final email = _emailController.text.trim();

    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid email address first'),
          backgroundColor: AppColorScheme.snackWarning,
        ),
      );
      return;
    }

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password reset link sent! Check your email.'),
            backgroundColor: AppColorScheme.snackSuccess,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Reset link sent if the email exists.'),
            backgroundColor: AppColorScheme.info,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return AuthBackdrop(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: AppSpacing.space6,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const StaggerIn(
                      index: 0,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: BrandMark(size: 56, showSubtitle: true),
                      ),
                    ),
                    const SizedBox(height: AppTokens.space8),
                    StaggerIn(
                      index: 1,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SplitHeading(
                            light: 'Welcome',
                            bold: 'back',
                            stacked: true,
                            style: theme.textTheme.displaySmall?.copyWith(
                              letterSpacing: -1,
                              height: 1.05,
                            ),
                          ),
                          const SizedBox(height: AppTokens.space2),
                          Text(
                            'Sign in to your account',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: cs.onSurfaceVariant,
                              fontWeight: FontWeight.w300,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppTokens.space6),
                    StaggerIn(
                      index: 2,
                      child: GlassPanel(
                        blur: true,
                        strong: true,
                        shadow: true,
                        borderRadius: AppRadius.xLarge,
                        padding: AppSpacing.space6,
                        child: _buildForm(theme),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildForm(ThemeData theme) {
    final cs = theme.colorScheme;
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            decoration: const InputDecoration(
              labelText: 'Email',
              prefixIcon: Icon(Icons.alternate_email_rounded),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your email';
              }
              if (!value.contains('@')) {
                return 'Please enter a valid email';
              }
              return null;
            },
          ),
          const SizedBox(height: AppTokens.space4),
          TextFormField(
            controller: _passwordController,
            obscureText: true,
            autofillHints: const [AutofillHints.password],
            decoration: const InputDecoration(
              labelText: 'Password',
              prefixIcon: Icon(Icons.lock_outline_rounded),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your password';
              }
              if (value.length < 6) {
                return 'Password must be at least 6 characters';
              }
              return null;
            },
          ),
          const SizedBox(height: AppTokens.space1),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(onPressed: _forgotPassword, child: const Text('Forgot password?')),
          ),
          AnimatedSize(
            duration: AppMotion.of(context, AppMotion.standard),
            curve: AppMotion.standardCurve,
            alignment: Alignment.topCenter,
            child: _errorMessage == null
                ? const SizedBox(width: double.infinity)
                : Padding(
                    padding: const EdgeInsets.only(top: AppTokens.space2),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: cs.error.withValues(alpha: 0.10),
                        borderRadius: AppRadius.medium,
                        border: Border.all(color: cs.error.withValues(alpha: 0.3)),
                      ),
                      child: Padding(
                        padding: AppSpacing.space3,
                        child: Row(
                          children: [
                            Icon(Icons.error_outline_rounded, size: 18, color: cs.error),
                            const SizedBox(width: AppTokens.space2),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: theme.textTheme.bodyMedium?.copyWith(color: cs.error),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
          ),
          const SizedBox(height: AppTokens.space4),
          GradientPillButton(
            label: 'Sign in',
            icon: Icons.arrow_forward_rounded,
            loading: _isLoading,
            onPressed: _isLoading ? null : _signIn,
          ),
        ],
      ),
    );
  }
}
