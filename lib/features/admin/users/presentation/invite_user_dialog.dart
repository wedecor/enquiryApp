import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/logging/logger.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../ui/primitives/primitives.dart';
import '../../../../ui/components/glass_dialog.dart';

// Removed shared user model import - using string-based roles instead

/// Dialog for inviting new users via Cloud Function
class InviteUserDialog extends ConsumerStatefulWidget {
  const InviteUserDialog({super.key});

  @override
  ConsumerState<InviteUserDialog> createState() => _InviteUserDialogState();
}

class _InviteUserDialogState extends ConsumerState<InviteUserDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  String _selectedRole = 'staff';
  bool _isLoading = false;
  String? _resetLink;
  bool _emailSent = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final s = AppSurfaces.of(context);
    const success = AppColorScheme.snackSuccess;
    final invited = _resetLink != null;
    final showLink = !_emailSent && (_resetLink?.isNotEmpty ?? false);

    return GlassDialog(
      eyebrow: invited ? 'Invitation sent' : 'Team',
      title: 'Invite User',
      icon: invited ? Icons.check_circle_outline_rounded : Icons.mail_outline_rounded,
      iconColor: invited ? success : null,
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!invited) ...[
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: Icon(Icons.person_outline_rounded),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Name is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppTokens.space4),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email Address',
                  prefixIcon: Icon(Icons.alternate_email_rounded),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Email is required';
                  }
                  if (!RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(value)) {
                    return 'Enter a valid email address';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppTokens.space4),
              DropdownButtonFormField<String>(
                initialValue: _selectedRole,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Role',
                  prefixIcon: Icon(Icons.shield_outlined),
                ),
                items: const [
                  DropdownMenuItem(value: 'staff', child: Text('Staff Member')),
                  DropdownMenuItem(value: 'admin', child: Text('Administrator')),
                ],
                onChanged: (role) {
                  if (role != null) {
                    setState(() {
                      _selectedRole = role;
                    });
                  }
                },
              ),
            ] else ...[
              Text(
                'User invited successfully!',
                style: t.titleLarge?.copyWith(color: success, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: AppTokens.space4),
              if (_emailSent) ...[
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: success.withValues(alpha: 0.10),
                    borderRadius: AppRadius.medium,
                    border: Border.all(color: success.withValues(alpha: 0.28)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(AppTokens.space3),
                    child: Row(
                      children: [
                        const StatusDot(color: success),
                        const SizedBox(width: AppTokens.space3),
                        Expanded(
                          child: Text(
                            'Invitation email sent to ${_emailController.text.trim()}',
                            style: t.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppTokens.space4),
              ],
              // The function only returns a link when the email failed.
              if (!_emailSent && !showLink)
                Text(
                  'The invitation email could not be sent. Ask the user to use '
                  '"Forgot password" on the login screen with this email.',
                  style: t.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                ),
            ],
            if (invited && showLink) ...[
              Text(
                'Email could not be sent. Share this password reset link with the user:',
                style: t.labelLarge?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: AppTokens.space2),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: s.glassFillStrong,
                  borderRadius: AppRadius.medium,
                  border: Border.all(color: s.microBorder),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppTokens.space3),
                  child: SelectableText(
                    _resetLink!,
                    style: t.bodySmall?.copyWith(fontFamily: 'monospace'),
                  ),
                ),
              ),
              const SizedBox(height: AppTokens.space3),
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  onPressed: _copyResetLink,
                  icon: const Icon(Icons.copy_rounded, size: 18),
                  label: const Text('Copy Link'),
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        if (!invited) ...[
          TextButton(
            onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: _isLoading ? null : _inviteUser,
            child: _isLoading
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Send Invite'),
          ),
        ] else ...[
          FilledButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Done')),
        ],
      ],
    );
  }

  // Removed _getRoleDisplayName method - using inline role names in dropdown

  Future<void> _inviteUser() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Use production functions in asia-south1 region
      final functions = FirebaseFunctions.instanceFor(region: 'asia-south1');
      final callable = functions.httpsCallable('inviteUser');

      // Debug configuration
      Log.d(
        'InviteUser callable configuration',
        data: {'region': 'asia-south1', 'function': 'inviteUser'},
      );

      final result = await callable.call<dynamic>({
        'email': _emailController.text.trim(),
        'name': _nameController.text.trim(),
        'role': _selectedRole,
      });

      final data = Map<String, dynamic>.from(result.data as Map);
      final resetLink = data['resetLink'] as String? ?? '';
      final emailSent = data['emailSent'] as bool? ?? false;

      if (!mounted) return;
      setState(() {
        _resetLink = resetLink;
        _emailSent = emailSent;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_inviteErrorMessage(e)),
          backgroundColor: AppColorScheme.snackError,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  /// Maps an invite failure to a user-facing message.
  String _inviteErrorMessage(Object e) {
    if (e is FirebaseFunctionsException) {
      switch (e.code) {
        case 'already-exists':
          return e.message ?? 'A user with this email already exists.';
        case 'permission-denied':
          return 'You don\'t have permission to invite users.';
        case 'invalid-argument':
          return e.message ?? 'Please check the email and role are valid.';
        case 'unauthenticated':
          return 'Please sign in again and try.';
        case 'deadline-exceeded':
          return 'Request timed out. Please check your connection and try again.';
        case 'resource-exhausted':
          return 'Server is busy. Please try again in a moment.';
      }
      final message = e.message;
      if (message != null && message.isNotEmpty) {
        return 'Failed to invite user: $message';
      }
    }

    final text = e.toString();
    if (text.contains('already-exists')) {
      return 'A user with this email already exists.';
    }
    if (text.contains('timeout')) {
      return 'Request timed out. Please check your connection and try again.';
    }
    return 'Failed to invite user: $text';
  }

  void _copyResetLink() {
    if (_resetLink != null) {
      Clipboard.setData(ClipboardData(text: _resetLink!));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Reset link copied to clipboard'),
          backgroundColor: AppColorScheme.snackSuccess,
        ),
      );
    }
  }
}
