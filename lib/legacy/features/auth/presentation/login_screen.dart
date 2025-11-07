import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';
import '../../../theme/tokens.dart';
import '../data/auth_service.dart';

/// Firebase console checklist for web login:
///  * Enable Email/Password provider (Authentication → Sign-in method)
///  * Add `localhost` and `127.0.0.1` to Authorized domains
///  * Ensure the web config includes `authDomain`
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Enter an email address';
    }
    final emailRegex = RegExp(r'^.+@.+\..+$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Enter a valid email';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  Future<void> _handle(Future<void> Function() action) async {
    if (_loading) return;
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await action();
    } on FirebaseAuthException catch (e) {
      _showError(AuthService.messageForException(e));
    } catch (e) {
      _showError('Authentication failed: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _signIn() async {
    await _handle(
      () => AuthService.instance.signIn(
        _emailController.text.trim(),
        _passwordController.text,
      ),
    );
  }

  Future<void> _signUp() async {
    await _handle(
      () => AuthService.instance.signUp(
        _emailController.text.trim(),
        _passwordController.text,
      ),
    );
  }

  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      _showError('Enter your email to reset password');
      return;
    }
    setState(() => _loading = true);
    try {
      await AuthService.instance.reset(email);
      _showMessage('Password reset email sent to $email');
    } on FirebaseAuthException catch (e) {
      _showError(AuthService.messageForException(e));
    } catch (e) {
      _showError('Failed to send reset email: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final extras = theme.extension<AppThemeExtras>();

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: extras?.primaryGradient),
        padding: EdgeInsets.symmetric(horizontal: Spacing.xxxl),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Card(
              color: theme.colorScheme.surface,
              shape: RoundedRectangleBorder(borderRadius: Radii.card),
              child: Padding(
                padding: EdgeInsets.all(Spacing.xxxl),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome back',
                        style: theme.textTheme.headlineMedium,
                      ),
                      SizedBox(height: Spacing.sm),
                      Text(
                        'Sign in with your email and password.',
                        style: theme.textTheme.bodyMedium,
                      ),
                      SizedBox(height: Spacing.xxxl),
                      TextFormField(
                        controller: _emailController,
                        enabled: !_loading,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        validator: _validateEmail,
                      ),
                      SizedBox(height: Spacing.lg),
                      TextFormField(
                        controller: _passwordController,
                        enabled: !_loading,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            tooltip: _obscurePassword
                                ? 'Show password'
                                : 'Hide password',
                            onPressed: _loading
                                ? null
                                : () => setState(
                                    () => _obscurePassword = !_obscurePassword,
                                  ),
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                          ),
                        ),
                        obscureText: _obscurePassword,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _signIn(),
                        validator: _validatePassword,
                      ),
                      SizedBox(height: Spacing.xxl),
                      _PrimaryButton(
                        label: 'Sign in',
                        onPressed: _loading ? null : _signIn,
                      ),
                      SizedBox(height: Spacing.lg),
                      _SecondaryButton(
                        label: 'Create account',
                        onPressed: _loading ? null : _signUp,
                      ),
                      SizedBox(height: Spacing.sm),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _loading ? null : _resetPassword,
                          child: const Text('Forgot password?'),
                        ),
                      ),
                      if (_loading) ...[
                        SizedBox(height: Spacing.xl),
                        const Center(child: CircularProgressIndicator()),
                      ],
                      if (kDebugMode) ...[
                        SizedBox(height: Spacing.xxl),
                        Text(
                          'Firebase Auth (Email/Password) must be enabled and localhost listed under authorized domains for web testing.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          minimumSize: const Size.fromHeight(Spacing.minTouchTarget),
        ),
        child: Text(label),
      ),
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  const _SecondaryButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(Spacing.minTouchTarget),
        ),
        child: Text(label),
      ),
    );
  }
}
