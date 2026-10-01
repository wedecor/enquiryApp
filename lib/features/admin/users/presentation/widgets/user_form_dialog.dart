import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/providers/role_provider.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/theme/tokens.dart';
import '../../../../../shared/models/user_model.dart';
import '../../../../../ui/components/glass_dialog.dart';
import '../../domain/user_model.dart' as domain;
import '../users_providers.dart';

class UserFormDialog extends ConsumerStatefulWidget {
  final domain.UserModel? user; // null for create, non-null for edit

  const UserFormDialog({super.key, this.user});

  @override
  ConsumerState<UserFormDialog> createState() => _UserFormDialogState();
}

class _UserFormDialogState extends ConsumerState<UserFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  String _selectedRole = 'staff';
  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    if (widget.user != null) {
      _nameController.text = widget.user!.name;
      _emailController.text = widget.user!.email;
      _phoneController.text = widget.user!.phone ?? '';
      _selectedRole = widget.user!.role;
      _isActive = widget.user!.isActive;
    }
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
    final isEdit = widget.user != null;
    final roleAsync = ref.watch(roleProvider);

    return GlassDialog(
      eyebrow: 'Team',
      title: isEdit ? 'Edit User' : 'Add User',
      icon: isEdit ? Icons.manage_accounts_outlined : Icons.person_add_alt_1_rounded,
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
              decoration: InputDecoration(
                labelText: 'Email',
                prefixIcon: const Icon(Icons.alternate_email_rounded),
                enabled: !isEdit, // Email is read-only for edits
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter an email';
                }
                if (!value.contains('@')) {
                  return 'Please enter a valid email';
                }
                return null;
              },
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
              decoration: const InputDecoration(
                labelText: 'Role',
                prefixIcon: Icon(Icons.shield_outlined),
              ),
              items: const [
                DropdownMenuItem(value: 'staff', child: Text('Staff')),
                DropdownMenuItem(value: 'admin', child: Text('Admin')),
              ],
              onChanged: (value) {
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
                    onChanged: (value) {
                      setState(() {
                        _isActive = value ?? true;
                      });
                    },
                  ),
                  const Text('Active'),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        roleAsync.when(
          data: (role) {
            if (role != UserRole.admin) {
              return const SizedBox.shrink();
            }
            return FilledButton(onPressed: _submit, child: Text(isEdit ? 'Update' : 'Create'));
          },
          loading: () => const SizedBox.shrink(),
          error: (_, _) => const SizedBox.shrink(),
        ),
      ],
    );
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final user = domain.UserModel(
      uid: widget.user?.uid ?? '', // Will be set by Firestore
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
      role: _selectedRole,
      isActive: _isActive,
      // fcmToken removed for security - stored in private subcollection
      createdAt: widget.user?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final formController = ref.read(userFormControllerProvider.notifier);

    if (widget.user != null) {
      await formController.updateUser(user.uid, user.toJson());
    } else {
      await formController.createUser(user);
    }

    if (mounted) {
      Navigator.of(context).pop();

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.user != null ? 'User updated successfully' : 'User created successfully',
          ),
          backgroundColor: AppColorScheme.snackSuccess,
        ),
      );
    }
  }
}
