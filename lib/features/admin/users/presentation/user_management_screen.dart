import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/auth/role_guards.dart';
import '../../../../core/providers/role_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../shared/models/user_model.dart' show UserRole;
import '../../../../ui/primitives/primitives.dart';
import '../../../../ui/components/glass_page_scaffold.dart';
import '../../../../ui/components/glass_state_message.dart';
import '../domain/user_model.dart' as domain;
import 'invite_user_dialog.dart';
import 'role_checker_panel.dart';
import 'users_providers.dart';
import 'widgets/confirm_dialog.dart';
import 'widgets/user_form_dialog.dart';
import 'widgets/user_member_tile.dart';
import 'widgets/users_admin_actions.dart';
import 'widgets/users_filter_panel.dart';

class UserManagementScreen extends ConsumerStatefulWidget {
  const UserManagementScreen({super.key});

  @override
  ConsumerState<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends ConsumerState<UserManagementScreen> {
  static const double _maxContentWidth = 1100;

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
    final roleAsync = ref.watch(roleProvider);
    final currentUser = ref.watch(currentUserWithFirestoreProvider);
    final paginationState = ref.watch(paginationStateProvider);

    return GlassPageScaffold(
      eyebrow: 'Admin',
      title: 'User Management',
      body: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth > 768;
          final gutter = constraints.maxWidth > _maxContentWidth + AppTokens.space8
              ? (constraints.maxWidth - _maxContentWidth) / 2
              : AppTokens.space4;
          final hPad = EdgeInsets.symmetric(horizontal: gutter);

          return CustomScrollView(
            slivers: [
              SliverPadding(
                padding: hPad.copyWith(top: AppTokens.space2),
                sliver: SliverToBoxAdapter(
                  child: roleAsync.when(
                    data: (role) => StaggerIn(
                      index: 0,
                      child: RoleCheckerPanel(
                        email: currentUser.valueOrNull?.email,
                        uid: currentUser.valueOrNull?.uid,
                        isAdmin: role == UserRole.admin,
                        role: role == UserRole.admin ? 'admin' : 'staff',
                        onRefresh: () => ref.invalidate(roleProvider),
                        onSignOut: () async {
                          await fb.FirebaseAuth.instance.signOut();
                        },
                      ),
                    ),
                    loading: () => const SizedBox.shrink(),
                    error: (_, _) => const SizedBox.shrink(),
                  ),
                ),
              ),
              if (roleAsync.valueOrNull == UserRole.admin)
                SliverPadding(
                  padding: hPad.copyWith(top: AppTokens.space4),
                  sliver: SliverToBoxAdapter(
                    child: StaggerIn(
                      index: 1,
                      child: UsersAdminActions(
                        onInvite: () => _showInviteUserDialog(context),
                        onAddUser: () => _showAddUserDialog(context),
                      ),
                    ),
                  ),
                ),
              SliverPadding(
                padding: hPad.copyWith(top: AppTokens.space4, bottom: AppTokens.space4),
                sliver: SliverToBoxAdapter(
                  child: StaggerIn(
                    index: 2,
                    child: UsersFilterPanel(
                      searchController: _searchController,
                      role: filter['role'] as String,
                      isActive: filter['isActive'] as bool?,
                      onRoleChanged: (value) {
                        ref.read(usersFilterProvider.notifier).updateRole(value);
                      },
                      onActiveChanged: (value) {
                        ref.read(usersFilterProvider.notifier).updateActive(value);
                      },
                    ),
                  ),
                ),
              ),
              ...roleAsync.when(
                data: (role) {
                  if (role != UserRole.admin) {
                    return [
                      const SliverFillRemaining(
                        hasScrollBody: false,
                        child: GlassStateMessage(
                          icon: Icons.lock_outline_rounded,
                          title: 'Access Denied',
                          message: 'Only administrators can access user management.',
                        ),
                      ),
                    ];
                  }
                  return [
                    Consumer(
                      builder: (context, ref, child) {
                        final usersAsync = ref.watch(usersStreamProvider(filter));
                        return _buildUsersListArea(
                          usersAsync,
                          true,
                          true,
                          paginationState,
                          wide: wide,
                          padding: hPad,
                        );
                      },
                    ),
                  ];
                },
                loading: () => const [
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: GlassLoadingState(message: 'Checking permissions...'),
                  ),
                ],
                error: (error, stack) => [
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: GlassStateMessage(
                      icon: Icons.error_outline_rounded,
                      title: 'Error checking permissions: $error',
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
              ),
              SliverToBoxAdapter(
                child: SizedBox(height: AppTokens.space8 + MediaQuery.paddingOf(context).bottom),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildUsersListArea(
    AsyncValue<List<domain.UserModel>> usersAsync,
    bool isAdmin,
    bool roleKnown,
    PaginationState paginationState, {
    required bool wide,
    required EdgeInsets padding,
  }) {
    return usersAsync.when(
      data: (users) =>
          _buildUsersList(users, isAdmin, roleKnown, paginationState, wide: wide, padding: padding),
      loading: () => const SliverFillRemaining(
        hasScrollBody: false,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => SliverFillRemaining(
        hasScrollBody: false,
        child: GlassStateMessage(
          icon: Icons.error_outline_rounded,
          title: 'Error loading users',
          message: error.toString(),
          color: Theme.of(context).colorScheme.error,
          action: FilledButton(
            onPressed: () {
              ref.invalidate(usersStreamProvider);
            },
            child: const Text('Retry'),
          ),
        ),
      ),
    );
  }

  Widget _buildUsersList(
    List<domain.UserModel> users,
    bool isAdmin,
    bool roleKnown,
    PaginationState paginationState, {
    required bool wide,
    required EdgeInsets padding,
  }) {
    if (!roleKnown) {
      return const SliverFillRemaining(
        hasScrollBody: false,
        child: GlassLoadingState(message: 'Resolving your role...'),
      );
    }

    if (users.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: GlassStateMessage(
          icon: Icons.people_outline_rounded,
          title: isAdmin
              ? 'No users found. Use "Add User" to create one.'
              : 'No users to show or you lack permissions to modify.',
          message: isAdmin
              ? 'Start by adding your first user to the system.'
              : 'Contact an admin to get access or check your role in Firestore.',
        ),
      );
    }

    return SliverPadding(
      padding: padding,
      sliver: SliverList.builder(
        itemCount: users.length + 2,
        itemBuilder: (context, index) {
          if (index == 0) {
            return SectionHeader(
              eyebrow: 'Team',
              title: '${users.length} ${users.length == 1 ? 'member' : 'members'}',
              padding: const EdgeInsets.only(bottom: AppTokens.space3),
            );
          }
          if (index == users.length + 1) {
            return paginationState.hasMore
                ? UsersLoadMoreButton(
                    loading: paginationState.isLoading,
                    onPressed: () => _loadMore(users),
                  )
                : const SizedBox.shrink();
          }
          final user = users[index - 1];
          return StaggerIn(
            index: index,
            child: UserMemberTile(
              key: ValueKey(user.uid),
              user: user,
              isAdmin: isAdmin,
              wide: wide,
              onAction: isAdmin ? (action) => _handleUserAction(action, user) : (_) {},
            ),
          );
        },
      ),
    );
  }

  void _loadMore(List<domain.UserModel> users) {
    if (users.isNotEmpty) {
      ref.read(paginationStateProvider.notifier).setLoading(true);
      ref.read(usersFilterProvider.notifier).loadMore(users.last.email);
    }
  }

  void _showAddUserDialog(BuildContext context) {
    showDialog<void>(context: context, builder: (context) => const UserFormDialog());
  }

  void _showInviteUserDialog(BuildContext context) {
    try {
      requireAdmin(ref);
      logAdminAction(ref, 'invite_user_dialog_opened', {
        'screen': 'user_management',
        'action_type': 'ui_access',
      });
      showDialog<void>(context: context, builder: (context) => const InviteUserDialog());
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Access denied: ${e.toString()}')));
    }
  }

  void _showEditUserDialog(BuildContext context, domain.UserModel user) {
    showDialog<void>(
      context: context,
      builder: (context) => UserFormDialog(user: user),
    );
  }

  void _handleUserAction(String action, domain.UserModel user) {
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

  void _toggleUserStatus(domain.UserModel user) {
    try {
      requireAdmin(ref);
      final action = user.isActive ? 'deactivate' : 'activate';

      logAdminAction(ref, 'user_status_toggle_initiated', {
        'targetUserId': user.uid,
        'targetUserEmail': user.email,
        'action': action,
        'currentActive': user.isActive,
      });

      showDialog<void>(
        context: context,
        builder: (context) => ConfirmDialog(
          title: '${action.capitalize()} User',
          content: 'Are you sure you want to $action ${user.name}?',
          isDestructive: user.isActive,
          onConfirm: () {
            logAdminAction(ref, 'user_status_toggle_confirmed', {
              'targetUserId': user.uid,
              'action': action,
            });
            ref
                .read(userFormControllerProvider.notifier)
                .toggleActive(user.uid, !user.isActive)
                .then((_) {
                  _showSnackBar('User ${action}d successfully', isError: false);
                })
                .catchError((Object error) {
                  _showSnackBar('Failed to $action user: $error', isError: true);
                });
          },
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Access denied: ${e.toString()}')));
    }
  }

  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColorScheme.snackError : AppColorScheme.snackSuccess,
        action: SnackBarAction(label: 'OK', textColor: Colors.white, onPressed: () {}),
      ),
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}
