import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/role_provider.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/models/user_model.dart';
import 'tabs/account_tab.dart';
import 'tabs/admin_tab.dart';
import 'tabs/dashboard_defaults_tab.dart';
import 'tabs/notifications_tab.dart';
import 'tabs/preferences_tab.dart';
import 'tabs/privacy_tab.dart';
import '../../../ui/components/glass_page_scaffold.dart';
import '../../../ui/components/glass_segmented_tabs.dart';
import '../../../ui/components/glass_state_message.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key, this.embeddedInShell = false});

  final bool embeddedInShell;

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> with TickerProviderStateMixin {
  late TabController _tabController;

  static const _baseSegments = [
    GlassSegment('Account', icon: Icons.person_outline_rounded),
    GlassSegment('Preferences', icon: Icons.tune_rounded),
    GlassSegment('Notifications', icon: Icons.notifications_none_rounded),
    GlassSegment('Dashboard', icon: Icons.space_dashboard_outlined),
    GlassSegment('Privacy', icon: Icons.privacy_tip_outlined),
  ];

  static const _adminSegment = GlassSegment('Admin', icon: Icons.admin_panel_settings_outlined);

  @override
  void initState() {
    super.initState();
    // Start with base (non-admin) tab count; upgraded to 6 once role resolves.
    _tabController = TabController(length: 5, vsync: this);
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
      loading: () => _wrap(const GlassLoadingState()),
      error: (error, stack) => _wrap(
        GlassStateMessage(
          icon: Icons.error_outline_rounded,
          title: 'Settings unavailable',
          message: 'Error: $error',
          color: Theme.of(context).colorScheme.error,
        ),
      ),
    );
  }

  Widget _wrap(Widget body) {
    if (widget.embeddedInShell) return body;
    return GlassPageScaffold(eyebrow: 'Workspace', title: 'Settings', body: body);
  }

  /// Swaps in a controller with [length] tabs when the segment count changes
  /// (admin tab appears/disappears), keeping the selected index. The old
  /// controller is still attached to the widgets from the previous frame, so
  /// it is disposed after this frame instead of during build.
  void _ensureTabCount(int length) {
    if (_tabController.length == length) return;
    final old = _tabController;
    _tabController = TabController(
      length: length,
      vsync: this,
      initialIndex: math.min(old.index, length - 1),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => old.dispose());
  }

  Widget _buildSettingsScreen(BuildContext context, bool isAdmin) {
    const baseTabViews = [
      AccountTab(),
      PreferencesTab(),
      NotificationsTab(),
      DashboardDefaultsTab(),
      PrivacyTab(),
    ];

    final segments = isAdmin ? [..._baseSegments, _adminSegment] : _baseSegments;
    final tabViews = isAdmin ? [...baseTabViews, const AdminTab()] : baseTabViews;

    _ensureTabCount(segments.length);

    return _wrap(
      Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppTokens.space4,
              AppTokens.space3,
              AppTokens.space4,
              AppTokens.space1,
            ),
            child: GlassSegmentedTabs(controller: _tabController, segments: segments),
          ),
          Expanded(
            child: TabBarView(controller: _tabController, children: tabViews),
          ),
        ],
      ),
    );
  }
}
