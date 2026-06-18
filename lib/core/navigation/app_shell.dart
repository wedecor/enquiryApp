import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/admin/analytics/presentation/analytics_screen.dart';
import '../../features/dashboard/presentation/screens/calendar_view_screen.dart';
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../../features/enquiries/presentation/screens/enquiries_list_screen.dart';
import '../../features/enquiries/presentation/screens/enquiry_form_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../shared/models/user_model.dart';
import '../providers/role_provider.dart';
import '../services/firebase_auth_service.dart';
import '../theme/tokens.dart';

/// Responsive navigation shell: bottom bar (mobile), rail (tablet), expanded rail (desktop).
class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  int _selectedIndex = 0;

  List<_ShellDestination> _destinations(bool isAdmin) {
    final destinations = <_ShellDestination>[
      const _ShellDestination(
        label: 'Dashboard',
        icon: Icons.dashboard_outlined,
        selectedIcon: Icons.dashboard,
        body: DashboardScreen(embeddedInShell: true),
      ),
      const _ShellDestination(
        label: 'Calendar',
        icon: Icons.calendar_today_outlined,
        selectedIcon: Icons.calendar_today,
        body: CalendarViewScreen(embeddedInShell: true),
      ),
      const _ShellDestination(
        label: 'Enquiries',
        icon: Icons.list_alt_outlined,
        selectedIcon: Icons.list_alt,
        body: EnquiriesListScreen(embeddedInShell: true),
      ),
      if (isAdmin)
        const _ShellDestination(
          label: 'Analytics',
          icon: Icons.bar_chart_outlined,
          selectedIcon: Icons.bar_chart,
          body: AnalyticsScreen(embeddedInShell: true),
        ),
      const _ShellDestination(
        label: 'Settings',
        icon: Icons.settings_outlined,
        selectedIcon: Icons.settings,
        body: SettingsScreen(embeddedInShell: true),
      ),
    ];
    return destinations;
  }

  bool _showFab(List<_ShellDestination> destinations) {
    if (_selectedIndex >= destinations.length) return false;
    final label = destinations[_selectedIndex].label;
    return label == 'Dashboard' || label == 'Enquiries';
  }

  Future<void> _signOut() async {
    try {
      await ref.read(firebaseAuthServiceProvider).signOut();
    } catch (_) {}
  }

  void _openNewEnquiry() {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(builder: (context) => const EnquiryFormScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final roleAsync = ref.watch(roleProvider);
    final isAdmin = roleAsync.valueOrNull == UserRole.admin;
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

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Text(current.label),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sign Out',
            onPressed: _signOut,
          ),
        ],
      ),
      body: Row(
        children: [
          if (!useBottomNav) ...[
            NavigationRail(
              extended: railExtended,
              selectedIndex: safeIndex,
              onDestinationSelected: (index) => setState(() => _selectedIndex = index),
              labelType: railExtended
                  ? NavigationRailLabelType.none
                  : NavigationRailLabelType.all,
              destinations: [
                for (final d in destinations)
                  NavigationRailDestination(
                    icon: Icon(d.icon),
                    selectedIcon: Icon(d.selectedIcon),
                    label: Text(d.label),
                  ),
              ],
            ),
            const VerticalDivider(width: 1, thickness: 1),
          ],
          Expanded(
            child: IndexedStack(
              index: safeIndex,
              children: [for (final d in destinations) d.body],
            ),
          ),
        ],
      ),
      bottomNavigationBar: useBottomNav
          ? NavigationBar(
              selectedIndex: safeIndex,
              onDestinationSelected: (index) => setState(() => _selectedIndex = index),
              destinations: [
                for (final d in destinations)
                  NavigationDestination(
                    icon: Icon(d.icon),
                    selectedIcon: Icon(d.selectedIcon),
                    label: d.label,
                  ),
              ],
            )
          : null,
      floatingActionButton: _showFab(destinations)
          ? FloatingActionButton(
              onPressed: _openNewEnquiry,
              tooltip: 'Add New Enquiry',
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}

class _ShellDestination {
  const _ShellDestination({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.body,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final Widget body;
}
