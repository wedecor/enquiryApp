import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../../../core/theme/tokens.dart';
import '../../../../../ui/components/glass_dialog.dart';

/// Shortest password Firebase Auth accepts.
const int kMinPasswordLength = 6;

/// User-facing message for a [FirebaseAuthException] code raised while changing the password.
String changePasswordErrorMessage(String code) {
  switch (code) {
    case 'wrong-password':
    case 'invalid-credential':
      return 'Current password is incorrect.';
    case 'weak-password':
      return 'Choose a stronger password (at least $kMinPasswordLength characters).';
    case 'too-many-requests':
      return 'Too many attempts. Wait a few minutes and try again.';
    case 'network-request-failed':
      return 'No connection. Check your internet and try again.';
    case 'requires-recent-login':
      return 'Please sign out, sign in again, then retry.';
    default:
      return 'Could not change the password. Please try again.';
  }
}

/// Changes the signed-in user's password after re-checking the current one; no email involved.
/// Pops `true` when the password was changed.
class ChangePasswordDialog extends StatefulWidget {
  const ChangePasswordDialog({super.key, required this.onForgotPassword});

  /// Fallback when the current password is unknown: email a reset link.
  final VoidCallback onForgotPassword;

  @override
  State<ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<ChangePasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscure = true;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_saving || !_formKey.currentState!.validate()) return;

    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email;
    if (user == null || email == null) {
      setState(() => _error = 'You are not signed in.');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final credential = EmailAuthProvider.credential(
        email: email,
        password: _currentController.text,
      );
      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(_newController.text);
      if (mounted) Navigator.of(context).pop(true);
    } on FirebaseAuthException catch (e) {
      _fail(e.code);
    } catch (_) {
      _fail('');
    }
  }

  void _fail(String code) {
    if (!mounted) return;
    setState(() {
      _saving = false;
      _error = changePasswordErrorMessage(code);
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return GlassDialog(
      eyebrow: 'Security',
      title: 'Change Password',
      icon: Icons.lock_reset_rounded,
      content: Form(
        key: _formKey,
        child: AutofillGroup(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _currentController,
                obscureText: _obscure,
                enabled: !_saving,
                autofillHints: const [AutofillHints.password],
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Current password',
                  prefixIcon: Icon(Icons.lock_outline_rounded),
                ),
                validator: (value) =>
                    (value == null || value.isEmpty) ? 'Enter your current password' : null,
              ),
              const SizedBox(height: AppTokens.space3),
              TextFormField(
                controller: _newController,
                obscureText: _obscure,
                enabled: !_saving,
                autofillHints: const [AutofillHints.newPassword],
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: 'New password',
                  helperText: 'At least $kMinPasswordLength characters',
                  prefixIcon: const Icon(Icons.password_rounded),
                  // Keeps the keyboard's Next action moving to the confirm field.
                  suffixIcon: ExcludeFocus(
                    child: IconButton(
                      tooltip: _obscure ? 'Show passwords' : 'Hide passwords',
                      icon: Icon(
                        _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                      ),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.length < kMinPasswordLength) {
                    return 'Use at least $kMinPasswordLength characters';
                  }
                  if (value == _currentController.text) {
                    return 'Must differ from your current password';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppTokens.space3),
              TextFormField(
                controller: _confirmController,
                obscureText: _obscure,
                enabled: !_saving,
                autofillHints: const [AutofillHints.newPassword],
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _submit(),
                decoration: const InputDecoration(
                  labelText: 'Confirm new password',
                  prefixIcon: Icon(Icons.check_circle_outline_rounded),
                ),
                validator: (value) =>
                    value != _newController.text ? 'Passwords do not match' : null,
              ),
              if (_error != null) ...[
                const SizedBox(height: AppTokens.space3),
                Text(
                  _error!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: cs.error),
                ),
              ],
              const SizedBox(height: AppTokens.space2),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: _saving
                      ? null
                      : () {
                          Navigator.of(context).pop();
                          widget.onForgotPassword();
                        },
                  child: const Text('Forgot current password? Email me a reset link'),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _saving ? null : _submit,
          child: _saving
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Update'),
        ),
      ],
    );
  }
}
