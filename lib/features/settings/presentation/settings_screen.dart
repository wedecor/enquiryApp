import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/current_user_role_provider.dart' as auth_provider;
import 'tabs/account_tab.dart';
import 'tabs/admin_tab.dart';
import 'tabs/dashboard_defaults_tab.dart';
import 'tabs/notifications_tab.dart';
import 'tabs/preferences_tab.dart';

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
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = ref.watch(auth_provider.isAdminProvider);

    return _buildSettingsScreen(context, isAdmin);
  }

  Widget _buildSettingsScreen(BuildContext context, bool isAdmin) {
    final tabs = [
      const Tab(icon: Icon(Icons.person), text: 'Account'),
      const Tab(icon: Icon(Icons.tune), text: 'Preferences'),
      const Tab(icon: Icon(Icons.notifications), text: 'Notifications'),
      const Tab(icon: Icon(Icons.dashboard), text: 'Dashboard'),
    ];

    final tabViews = [
      const AccountTab(),
      const PreferencesTab(),
      const NotificationsTab(),
      const DashboardDefaultsTab(),
    ];

    if (isAdmin) {
      tabs.add(const Tab(icon: Icon(Icons.admin_panel_settings), text: 'Admin'));
      tabViews.add(const AdminTab());

      // Update tab controller length
      _tabController.dispose();
      _tabController = TabController(length: 5, vsync: this);
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
