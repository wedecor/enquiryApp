import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import '../../../../core/auth/current_user_role_provider.dart';
import '../domain/user_model.dart';
import 'users_providers.dart';
import 'widgets/user_form_dialog.dart';
import 'widgets/confirm_dialog.dart';
import 'invite_user_dialog.dart';
import 'role_checker_panel.dart';

class UserManagementScreen extends ConsumerStatefulWidget {
  const UserManagementScreen({super.key});

  @override
  ConsumerState<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends ConsumerState<UserManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onSearchChanged() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      ref.read(usersFilterProvider.notifier).updateSearch(_searchController.text);
    });
  }

  @override
  Widget build(BuildContext context) {
    final filter = ref.watch(usersFilterProvider);
    final usersAsync = ref.watch(usersStreamProvider(filter));
    final isAdmin = ref.watch(isAdminProvider);
    final role = ref.watch(currentUserRoleProvider);
    final authUser = ref.watch(firebaseAuthUserProvider).value;
    final paginationState = ref.watch(paginationStateProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('User Management'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          if (isAdmin) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: FilledButton.icon(
                onPressed: () => _showInviteUserDialog(context),
                icon: const Icon(Icons.email),
                label: const Text('Invite'),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: FilledButton.icon(
                onPressed: () => _showAddUserDialog(context),
                icon: const Icon(Icons.person_add),
                label: const Text('Add User'),
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                ),
              ),
            ),
          ],
        ],
      ),
      body: Column(
        children: [
          // Role Checker Panel
          RoleCheckerPanel(
            email: authUser?.email,
            uid: authUser?.uid,
            isAdmin: isAdmin,
            role: role,
            onRefresh: () => ref.invalidate(currentUserDocProvider),
            onSignOut: () async {
              await fb.FirebaseAuth.instance.signOut();
            },
          ),
          // Header with search and filters
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 3,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                // Search row
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: const InputDecoration(
                          hintText: 'Search by name or email...',
                          prefixIcon: Icon(Icons.search),
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Filters row
                Row(
                  children: [
                    // Role filter
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: filter['role'] as String,
                        decoration: const InputDecoration(
                          labelText: 'Role',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'All', child: Text('All Roles')),
                          DropdownMenuItem(value: 'admin', child: Text('Admin')),
                          DropdownMenuItem(value: 'staff', child: Text('Staff')),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            ref.read(usersFilterProvider.notifier).updateRole(value);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Status filter
                    Expanded(
                      child: DropdownButtonFormField<bool?>(
                        value: filter['active'] as bool?,
                        decoration: const InputDecoration(
                          labelText: 'Status',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        items: const [
                          DropdownMenuItem<bool?>(value: null, child: Text('All Status')),
                          DropdownMenuItem<bool?>(value: true, child: Text('Active')),
                          DropdownMenuItem<bool?>(value: false, child: Text('Inactive')),
                        ],
                        onChanged: (value) {
                          ref.read(usersFilterProvider.notifier).updateActive(value);
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Users list
          Expanded(
            child: _buildUsersListArea(
              usersAsync,
              isAdmin,
              role != null,
              paginationState,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsersListArea(
    AsyncValue<List<UserModel>> usersAsync,
    bool isAdmin,
    bool roleKnown,
    PaginationState paginationState,
  ) {
    return usersAsync.when(
      data: (users) => _buildUsersList(users, isAdmin, roleKnown, paginationState),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => _buildErrorState(error),
    );
  }

  Widget _buildUsersList(List<UserModel> users, bool isAdmin, bool roleKnown, PaginationState paginationState) {
    if (!roleKnown) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Resolving your role...'),
          ],
        ),
      );
    }

    if (users.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              isAdmin
                  ? 'No users found. Use "Add User" to create one.'
                  : 'No users to show or you lack permissions to modify.',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isAdmin
                  ? 'Start by adding your first user to the system.'
                  : 'Contact an admin to get access or check your role in Firestore.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        // Use table layout for wider screens, card layout for narrow screens
        if (constraints.maxWidth > 768) {
          return _buildTableLayout(users, isAdmin, paginationState);
        } else {
          return _buildCardLayout(users, isAdmin, paginationState);
        }
      },
    );
  }

  Widget _buildTableLayout(List<UserModel> users, bool isAdmin, PaginationState paginationState) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: DataTable(
              columns: const [
                DataColumn(label: Text('Name')),
                DataColumn(label: Text('Email')),
                DataColumn(label: Text('Phone')),
                DataColumn(label: Text('Role')),
                DataColumn(label: Text('Status')),
                DataColumn(label: Text('Created')),
                DataColumn(label: Text('Updated')),
                DataColumn(label: Text('Actions')),
              ],
              rows: users.map((user) => DataRow(
                cells: [
                  DataCell(Text(user.name)),
                  DataCell(Text(
                    user.email,
                    style: const TextStyle(fontFamily: 'monospace'),
                  )),
                  DataCell(Text(user.phone ?? '')),
                  DataCell(_buildRoleChip(user.role)),
                  DataCell(_buildStatusChip(user.active)),
                  DataCell(Text(_formatDate(user.createdAt))),
                  DataCell(Text(_formatDate(user.updatedAt))),
                  DataCell(_buildActionButtons(user, isAdmin)),
                ],
              )).toList(),
            ),
          ),
        ),
        if (paginationState.hasMore)
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: paginationState.isLoading ? null : () => _loadMore(users),
              child: paginationState.isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Load More...'),
            ),
          ),
      ],
    );
  }

  Widget _buildCardLayout(List<UserModel> users, bool isAdmin, PaginationState paginationState) {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  title: Text(user.name),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.email,
                        style: const TextStyle(fontFamily: 'monospace'),
                      ),
                      if (user.phone != null) Text(user.phone!),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          _buildRoleChip(user.role),
                          const SizedBox(width: 8),
                          _buildStatusChip(user.active),
                        ],
                      ),
                    ],
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: isAdmin ? (action) => _handleUserAction(action, user) : null,
                    enabled: isAdmin,
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            const Icon(Icons.edit),
                            const SizedBox(width: 8),
                            Text(isAdmin ? 'Edit' : 'Edit (admin only)'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: user.active ? 'deactivate' : 'activate',
                        enabled: isAdmin,
                        child: Row(
                          children: [
                            Icon(user.active ? Icons.block : Icons.check_circle),
                            const SizedBox(width: 8),
                            Text(isAdmin 
                                ? (user.active ? 'Deactivate' : 'Activate')
                                : 'Admin only'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        if (paginationState.hasMore)
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: paginationState.isLoading ? null : () => _loadMore(users),
              child: paginationState.isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Load More...'),
            ),
          ),
      ],
    );
  }

  Widget _buildRoleChip(String role) {
    final color = role == 'admin' ? Colors.purple : Colors.blue;
    return Chip(
      label: Text(
        role.toUpperCase(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: color,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  Widget _buildStatusChip(bool active) {
    return Chip(
      label: Text(
        active ? 'ACTIVE' : 'INACTIVE',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: active ? Colors.green : Colors.red,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  Widget _buildActionButtons(UserModel user, bool isAdmin) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.edit),
          onPressed: isAdmin ? () => _showEditUserDialog(context, user) : null,
          tooltip: isAdmin ? 'Edit' : 'Edit (admin only)',
        ),
        IconButton(
          icon: Icon(user.active ? Icons.block : Icons.check_circle),
          onPressed: isAdmin ? () => _toggleUserStatus(user) : null,
          tooltip: isAdmin 
              ? (user.active ? 'Deactivate' : 'Activate')
              : 'Admin only',
        ),
      ],
    );
  }


  Widget _buildErrorState(Object error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red,
          ),
          const SizedBox(height: 16),
          Text(
            'Error loading users',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            error.toString(),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              ref.invalidate(usersStreamProvider);
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day} ${_getMonthName(date.month)} ${date.year}, ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _getMonthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                   'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }

  void _loadMore(List<UserModel> users) {
    if (users.isNotEmpty) {
      ref.read(paginationStateProvider.notifier).setLoading(true);
      ref.read(usersFilterProvider.notifier).loadMore(users.last.email);
    }
  }

  void _showAddUserDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const UserFormDialog(),
    );
  }

  void _showInviteUserDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const InviteUserDialog(),
    );
  }

  void _showEditUserDialog(BuildContext context, UserModel user) {
    showDialog(
      context: context,
      builder: (context) => UserFormDialog(user: user),
    );
  }

  void _handleUserAction(String action, UserModel user) {
    switch (action) {
      case 'edit':
        _showEditUserDialog(context, user);
        break;
      case 'activate':
      case 'deactivate':
        _toggleUserStatus(user);
        break;
    }
  }

  void _toggleUserStatus(UserModel user) {
    final action = user.active ? 'deactivate' : 'activate';
    showDialog(
      context: context,
      builder: (context) => ConfirmDialog(
        title: '${action.capitalize()} User',
        content: 'Are you sure you want to $action ${user.name}?',
        onConfirm: () {
          Navigator.of(context).pop();
          ref.read(userFormControllerProvider.notifier).toggleActive(
            user.uid,
            !user.active,
          ).then((_) {
            _showSnackBar(
              'User ${action}d successfully',
              isError: false,
            );
          }).catchError((error) {
            _showSnackBar(
              'Failed to $action user: $error',
              isError: true,
            );
          });
        },
      ),
    );
  }

  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {},
        ),
      ),
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}
