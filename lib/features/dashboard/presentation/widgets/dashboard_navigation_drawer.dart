import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/role_provider.dart';
import '../../../../core/services/firebase_auth_service.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../shared/models/user_model.dart';
import '../../../admin/analytics/presentation/analytics_screen.dart';
import '../../../admin/dropdowns/presentation/dropdown_management_screen.dart';
import '../../../admin/users/presentation/user_management_screen.dart';
import '../../../enquiries/presentation/screens/enquiries_list_screen.dart';
import '../../../enquiries/presentation/screens/enquiry_form_screen.dart';
import '../../../settings/presentation/settings_screen.dart';
import '../screens/calendar_view_screen.dart';

/// Legacy swipe-in drawer for standalone [DashboardScreen] navigation (non-shell).
class DashboardNavigationDrawer extends ConsumerWidget {
  const DashboardNavigationDrawer({super.key, required this.isAdmin});

  final bool isAdmin;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserWithFirestoreProvider);

    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _DrawerHeader(currentUser: currentUser, isAdmin: isAdmin),
            const SizedBox(height: AppTokens.space2),
            Expanded(
              child: ListView(
                padding: AppSpacing.horizontal(AppTokens.space3),
                children: [
                  const _DrawerSectionLabel(label: 'Overview'),
                  _DrawerTile(
                    icon: Icons.dashboard_outlined,
                    label: 'Dashboard',
                    onTap: () => Navigator.pop(context),
                  ),
                  _DrawerTile(
                    icon: Icons.list_alt_outlined,
                    label: 'All Enquiries',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.of(context).push<void>(
                        MaterialPageRoute<void>(builder: (context) => const EnquiriesListScreen()),
                      );
                    },
                  ),
                  _DrawerTile(
                    icon: Icons.calendar_today,
                    label: 'Calendar View',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.of(context).push<void>(
                        MaterialPageRoute<void>(builder: (context) => const CalendarViewScreen()),
                      );
                    },
                  ),
                  _DrawerTile(
                    icon: Icons.add_circle_outline,
                    label: 'Add Enquiry',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.of(context).push<void>(
                        MaterialPageRoute<void>(builder: (context) => const EnquiryFormScreen()),
                      );
                    },
                  ),
                  if (isAdmin) ...[
                    const SizedBox(height: AppTokens.space4),
                    const _DrawerSectionLabel(label: 'Admin Tools'),
                    _DrawerTile(
                      icon: Icons.people_outline,
                      label: 'User Management',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.of(context).push<void>(
                          MaterialPageRoute<void>(
                            builder: (context) => const UserManagementScreen(),
                          ),
                        );
                      },
                    ),
                    _DrawerTile(
                      icon: Icons.bar_chart_outlined,
                      label: 'Analytics',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.of(context).push<void>(
                          MaterialPageRoute<void>(builder: (context) => const AnalyticsScreen()),
                        );
                      },
                    ),
                    _DrawerTile(
                      icon: Icons.tune,
                      label: 'Dropdowns',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.of(context).push<void>(
                          MaterialPageRoute<void>(
                            builder: (context) => const DropdownManagementScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                  const SizedBox(height: AppTokens.space4),
                  const _DrawerSectionLabel(label: 'Preferences'),
                  _DrawerTile(
                    icon: Icons.settings_outlined,
                    label: 'Settings',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.of(context).push<void>(
                        MaterialPageRoute<void>(builder: (context) => const SettingsScreen()),
                      );
                    },
                  ),
                ],
              ),
            ),
            const Divider(height: 0),
            _DrawerTile(
              icon: Icons.logout,
              label: 'Sign out',
              danger: true,
              onTap: () async {
                Navigator.pop(context);
                await ref.read(firebaseAuthServiceProvider).signOut();
              },
            ),
            const SizedBox(height: AppTokens.space3),
          ],
        ),
      ),
    );
  }
}

class _DrawerHeader extends StatelessWidget {
  const _DrawerHeader({required this.currentUser, required this.isAdmin});

  final AsyncValue<UserModel?> currentUser;
  final bool isAdmin;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: AppSpacing.space5,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [theme.colorScheme.primary, theme.colorScheme.primary.withValues(alpha: 0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: currentUser.when(
        data: (user) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: theme.colorScheme.onPrimary.withValues(alpha: 0.2),
              child: Text(
                (user?.name.isNotEmpty == true ? user!.name[0] : 'U').toUpperCase(),
                style: TextStyle(
                  color: theme.colorScheme.onPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
            const SizedBox(height: AppTokens.space3),
            Text(
              user?.name ?? 'User',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppTokens.space1),
            Text(
              isAdmin ? 'Administrator' : 'Team Member',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onPrimary.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
        loading: () => SizedBox(
          height: 40,
          child: Center(child: CircularProgressIndicator(color: theme.colorScheme.onPrimary)),
        ),
        error: (_, __) =>
            Text('Error loading user', style: TextStyle(color: theme.colorScheme.onPrimary)),
      ),
    );
  }
}

class _DrawerSectionLabel extends StatelessWidget {
  const _DrawerSectionLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: AppSpacing.vertical2,
      child: Text(
        label.toUpperCase(),
        style: theme.textTheme.labelSmall?.copyWith(
          letterSpacing: 1.1,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
        ),
      ),
    );
  }
}

class _DrawerTile extends StatelessWidget {
  const _DrawerTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.danger = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = danger
        ? theme.colorScheme.error
        : theme.colorScheme.onSurface.withValues(alpha: 0.85);
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(label, style: theme.textTheme.bodyMedium?.copyWith(color: color)),
      onTap: onTap,
    );
  }
}
