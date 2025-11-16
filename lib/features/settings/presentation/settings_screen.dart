import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/role_provider.dart';
import '../../../shared/models/user_model.dart';
import 'tabs/account_tab.dart';
import 'tabs/admin_tab.dart';
import 'tabs/dashboard_defaults_tab.dart';
import 'tabs/notifications_tab.dart';
import 'tabs/preferences_tab.dart';
import 'tabs/privacy_tab.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    // Initialize with max possible tabs (including admin)
    _tabController = TabController(length: 6, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final roleAsync = ref.watch(roleProvider);

    return roleAsync.when(
      data: (role) {
        final isAdmin = role == UserRole.admin;
        return _buildSettingsScreen(context, isAdmin);
      },
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Settings'), centerTitle: true),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        appBar: AppBar(title: const Text('Settings'), centerTitle: true),
        body: Center(child: Text('Error: $error')),
      ),
    );
  }

  Widget _buildSettingsScreen(BuildContext context, bool isAdmin) {
    final baseTabs = [
      const Tab(icon: Icon(Icons.person), text: 'Account'),
      const Tab(icon: Icon(Icons.tune), text: 'Preferences'),
      const Tab(icon: Icon(Icons.notifications), text: 'Notifications'),
      const Tab(icon: Icon(Icons.dashboard), text: 'Dashboard'),
      const Tab(icon: Icon(Icons.privacy_tip), text: 'Privacy'),
    ];

    final baseTabViews = [
      const AccountTab(),
      const PreferencesTab(),
      const NotificationsTab(),
      const DashboardDefaultsTab(),
      const PrivacyTab(),
    ];

    final tabs = isAdmin
        ? [...baseTabs, const Tab(icon: Icon(Icons.admin_panel_settings), text: 'Admin')]
        : baseTabs;

    final tabViews = isAdmin ? [...baseTabViews, const AdminTab()] : baseTabViews;

    // Update tab controller length if needed
    if (_tabController.length != tabs.length) {
      _tabController.dispose();
      _tabController = TabController(length: tabs.length, vsync: this);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: true,
        bottom: TabBar(controller: _tabController, tabs: tabs, isScrollable: true),
      ),
      body: TabBarView(controller: _tabController, children: tabViews),
    );
  }
}
