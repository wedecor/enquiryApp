import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/providers/role_provider.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/theme/tokens.dart';
import '../../../../../shared/models/user_model.dart';
import '../../../../../ui/components/glass_dialog.dart';
import '../../domain/user_model.dart' as domain;
import '../users_providers.dart';

/// Edit dialog for an existing team member. New people are added through
/// the invite flow, so this dialog is edit-only. Saving calls the
/// `adminUpdateUser` callable with only the fields that changed.
class UserFormDialog extends ConsumerStatefulWidget {
  final domain.UserModel user;

  const UserFormDialog({super.key, required this.user});

  @override
  ConsumerState<UserFormDialog> createState() => _UserFormDialogState();
}

class _UserFormDialogState extends ConsumerState<UserFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  late final String _originalRole;
  late String _selectedRole;
  bool _isActive = true;
  bool _saving = false;

  /// True when the dialog is editing the signed-in user's own row. Own role
  /// and status can't be changed (the server rejects it too).
  bool get _isSelf => widget.user.uid == fb.FirebaseAuth.instance.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    final user = widget.user;
    _nameController.text = user.name;
    _emailController.text = user.email;
    _phoneController.text = user.phone ?? '';
    _originalRole = user.role.toLowerCase() == 'admin' ? 'admin' : 'staff';
    _selectedRole = _originalRole;
    _isActive = user.isActive;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final roleAsync = ref.watch(roleProvider);
    final isSelf = _isSelf;
    final t = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return GlassDialog(
      eyebrow: 'Team',
      title: 'Edit User',
      icon: Icons.manage_accounts_outlined,
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                prefixIcon: Icon(Icons.person_outline_rounded),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a name';
                }
                return null;
              },
            ),
            const SizedBox(height: AppTokens.space4),
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.alternate_email_rounded),
                enabled: false, // Email is read-only
              ),
            ),
            const SizedBox(height: AppTokens.space4),
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Phone (optional)',
                prefixIcon: Icon(Icons.phone_outlined),
              ),
            ),
            const SizedBox(height: AppTokens.space4),
            DropdownButtonFormField<String>(
              initialValue: _selectedRole,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: 'Role',
                prefixIcon: const Icon(Icons.shield_outlined),
                helperText: isSelf ? "You can't change your own role or status" : null,
              ),
              items: const [
                DropdownMenuItem(value: 'staff', child: Text('Staff')),
                DropdownMenuItem(value: 'admin', child: Text('Admin')),
              ],
              onChanged: isSelf || _saving
                  ? null
                  : (value) {
                      setState(() {
                        _selectedRole = value ?? 'staff';
                      });
                    },
            ),
            const SizedBox(height: AppTokens.space2),
            MergeSemantics(
              child: Row(
                children: [
                  Checkbox(
                    value: _isActive,
                    onChanged: isSelf || _saving
                        ? null
                        : (value) {
                            setState(() {
                              _isActive = value ?? true;
                            });
                          },
                  ),
                  Text(
                    'Active',
                    style: isSelf ? t.bodyMedium?.copyWith(color: cs.onSurfaceVariant) : null,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        roleAsync.when(
          data: (role) {
            if (role != UserRole.admin) {
              return const SizedBox.shrink();
            }
            return FilledButton(
              onPressed: _saving ? null : _submit,
              child: _saving
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Update'),
            );
          },
          loading: () => const SizedBox.shrink(),
          error: (_, _) => const SizedBox.shrink(),
        ),
      ],
    );
  }

  /// Fields that differ from the original user, limited to what
  /// `adminUpdateUser` accepts. Own role/status are never sent.
  Map<String, dynamic> _changedFields() {
    final original = widget.user;
    final changes = <String, dynamic>{};

    final name = _nameController.text.trim();
    if (name != original.name) changes['name'] = name;

    final phoneText = _phoneController.text.trim();
    final phone = phoneText.isEmpty ? null : phoneText;
    final originalPhone = (original.phone?.trim().isEmpty ?? true) ? null : original.phone!.trim();
    if (phone != originalPhone) changes['phone'] = phone;

    if (!_isSelf) {
      if (_selectedRole != _originalRole) changes['role'] = _selectedRole;
      if (_isActive != original.isActive) changes['isActive'] = _isActive;
    }
    return changes;
  }

  Future<void> _submit() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;

    final changes = _changedFields();
    if (changes.isEmpty) {
      Navigator.of(context).pop();
      return;
    }

    setState(() => _saving = true);
    try {
      await ref.read(userFormControllerProvider.notifier).updateUser(widget.user.uid, changes);
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update user: ${userAdminErrorMessage(error)}'),
          backgroundColor: AppColorScheme.snackError,
        ),
      );
      return;
    }

    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pop();
    messenger.showSnackBar(
      const SnackBar(
        content: Text('User updated successfully'),
        backgroundColor: AppColorScheme.snackSuccess,
      ),
    );
  }
}
