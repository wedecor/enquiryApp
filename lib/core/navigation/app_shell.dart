import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/admin/analytics/presentation/analytics_screen.dart';
import '../../features/dashboard/presentation/screens/calendar_view_screen.dart';
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../../features/enquiries/presentation/screens/enquiries_list_screen.dart';
import '../../features/enquiries/presentation/screens/enquiry_form_screen.dart';
import '../../features/notifications/presentation/notifications_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../shared/models/user_model.dart';
import '../../ui/primitives/primitives.dart';
import '../providers/notification_provider.dart';
import '../providers/role_provider.dart';
import '../services/firebase_auth_service.dart';
import '../theme/tokens.dart';
import 'shell_widgets.dart';

/// Responsive navigation shell — the app's only primary navigation.
///
/// * width < [AppTokens.breakpointTablet]: floating glass nav pill (bottom).
/// * width >= [AppTokens.breakpointTablet]: glass side rail (icons).
/// * width >= [AppTokens.breakpointDesktop]: extended rail (icons + labels).
///
/// Destinations are role-gated: Analytics is admin-only; admin tools (Users,
/// Dropdowns) live under Settings → Admin.
class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  int _selectedIndex = 0;

  // Calendar is always index 1 — used by DashboardScreen to navigate to it.
  static const int _calendarTabIndex = 1;

  void _select(int index) => setState(() => _selectedIndex = index);

  void _navigateToAnalytics(bool isAdmin) {
    final idx = _destinations(isAdmin).indexWhere((d) => d.label == 'Analytics');
    if (idx >= 0) _select(idx);
  }

  List<ShellDestination> _destinations(bool isAdmin) {
    return [
      ShellDestination(
        label: 'Dashboard',
        eyebrow: 'Today',
        icon: Icons.space_dashboard_outlined,
        selectedIcon: Icons.space_dashboard_rounded,
        body: DashboardScreen(
          embeddedInShell: true,
          onNavigateToCalendar: () => _select(_calendarTabIndex),
          onNavigateToAnalytics: () => _navigateToAnalytics(isAdmin),
        ),
      ),
      const ShellDestination(
        label: 'Calendar',
        eyebrow: 'Schedule',
        icon: Icons.calendar_month_outlined,
        selectedIcon: Icons.calendar_month_rounded,
        body: CalendarViewScreen(embeddedInShell: true),
      ),
      const ShellDestination(
        label: 'Enquiries',
        eyebrow: 'Pipeline',
        icon: Icons.view_agenda_outlined,
        selectedIcon: Icons.view_agenda_rounded,
        body: EnquiriesListScreen(embeddedInShell: true),
      ),
      if (isAdmin)
        const ShellDestination(
          label: 'Analytics',
          eyebrow: 'Insights',
          icon: Icons.insights_outlined,
          selectedIcon: Icons.insights_rounded,
          body: AnalyticsScreen(embeddedInShell: true),
        ),
      const ShellDestination(
        label: 'Settings',
        eyebrow: 'Workspace',
        icon: Icons.tune_outlined,
        selectedIcon: Icons.tune_rounded,
        body: SettingsScreen(embeddedInShell: true),
      ),
    ];
  }

  bool _showFab(List<ShellDestination> destinations, int index) {
    final label = destinations[index].label;
    return label == 'Dashboard' || label == 'Enquiries';
  }

  Future<void> _signOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text('You will need to sign in again to access the app.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Sign out')),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(firebaseAuthServiceProvider).signOut();
    } catch (_) {}
  }

  void _openNewEnquiry() {
    Navigator.of(
      context,
    ).push<void>(MaterialPageRoute<void>(builder: (context) => const EnquiryFormScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final roleAsync = ref.watch(roleProvider);
    final isAdmin = roleAsync.valueOrNull == UserRole.admin;
    final permissions = ref.watch(userPermissionsProvider);
    final destinations = _destinations(isAdmin);

    if (_selectedIndex >= destinations.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _selectedIndex = 0);
      });
    }

    final width = MediaQuery.sizeOf(context).width;
    final useBottomNav = width < AppTokens.breakpointTablet;
    final railExtended = width >= AppTokens.breakpointDesktop;
    final safeIndex = _selectedIndex.clamp(0, destinations.length - 1);
    final current = destinations[safeIndex];
    final showFab = _showFab(destinations, safeIndex) && permissions.canCreateEnquiries;

    final actions = [
      _NotificationBell(isAdmin: isAdmin),
      const SizedBox(width: AppTokens.space2),
      ShellIconButton(icon: Icons.logout_rounded, tooltip: 'Sign Out', onTap: _signOut),
    ];

    final pages = IndexedStack(index: safeIndex, children: [for (final d in destinations) d.body]);

    return AmbientBackdrop(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        resizeToAvoidBottomInset: true,
        appBar: ShellTopBar(
          eyebrow: current.eyebrow,
          title: current.label,
          showBrand: useBottomNav || !railExtended,
          actions: actions,
        ),
        body: useBottomNav
            ? pages
            : Row(
                children: [
                  ShellRail(
                    destinations: destinations,
                    selectedIndex: safeIndex,
                    extended: railExtended,
                    onSelected: _select,
                  ),
                  Expanded(child: pages),
                ],
              ),
        bottomNavigationBar: useBottomNav
            ? ShellNavPill(
                destinations: destinations,
                selectedIndex: safeIndex,
                onSelected: _select,
              )
            : null,
        floatingActionButton: showFab
            ? AccentFab(
                onTap: _openNewEnquiry,
                tooltip: 'Add New Enquiry',
                label: railExtended ? 'New enquiry' : null,
              )
            : null,
      ),
    );
  }
}

class _NotificationBell extends ConsumerWidget {
  const _NotificationBell({required this.isAdmin});

  final bool isAdmin;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserWithFirestoreProvider);
    final userId = userAsync.valueOrNull?.uid;
    if (userId == null) return const SizedBox.shrink();

    final countAsync = ref.watch(unreadNotificationCountProvider(userId));
    final count = countAsync.valueOrNull ?? 0;

    return ShellIconButton(
      icon: Icons.notifications_none_rounded,
      tooltip: 'Notifications',
      badgeCount: count,
      onTap: () => Navigator.of(
        context,
      ).push<void>(MaterialPageRoute<void>(builder: (_) => const NotificationsScreen())),
    );
  }
}
