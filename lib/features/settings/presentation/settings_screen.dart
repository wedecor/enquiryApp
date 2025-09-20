import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/current_user_role_provider.dart' as auth_provider;
import '../../legal/privacy_policy_screen.dart';
import '../../legal/terms_of_service_screen.dart';
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
    _tabController = TabController(length: 5, vsync: this);
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
      const Tab(icon: Icon(Icons.gavel), text: 'Legal'),
    ];

    final tabViews = [
      const AccountTab(),
      const PreferencesTab(),
      const NotificationsTab(),
      const DashboardDefaultsTab(),
      _buildLegalTab(context),
    ];

    if (isAdmin) {
      tabs.add(const Tab(icon: Icon(Icons.admin_panel_settings), text: 'Admin'));
      tabViews.add(const AdminTab());

      // Update tab controller length for admin
      _tabController.dispose();
      _tabController = TabController(length: 6, vsync: this);
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

  Widget _buildLegalTab(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Legal & Privacy',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 24),
        
        _buildLegalCard(
          context,
          icon: Icons.privacy_tip,
          title: 'Privacy Policy',
          description: 'Learn how we collect, use, and protect your personal information.',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (context) => const PrivacyPolicyScreen()),
          ),
        ),
        
        const SizedBox(height: 16),
        
        _buildLegalCard(
          context,
          icon: Icons.description,
          title: 'Terms of Service',
          description: 'Read our terms and conditions for using this service.',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (context) => const TermsOfServiceScreen()),
          ),
        ),
        
        const SizedBox(height: 24),
        
        const Text(
          'App Information',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Version: 1.0.0+1'),
                const SizedBox(height: 8),
                const Text('Build: Production'),
                const SizedBox(height: 8),
                Text('© ${DateTime.now().year} We Decor Enquiries. All rights reserved.'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLegalCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required VoidCallback onTap,
  }) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: Theme.of(context).primaryColor),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(description),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}
