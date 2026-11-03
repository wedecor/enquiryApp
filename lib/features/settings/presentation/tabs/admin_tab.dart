import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/tokens.dart';
import '../../../../ui/components/glass_segmented_tabs.dart';
import 'widgets/admin_about_section.dart';
import 'widgets/admin_company_section.dart';
import 'widgets/admin_data_section.dart';
import 'widgets/admin_notification_section.dart';
import 'widgets/admin_reengagement_section.dart';
import 'widgets/admin_security_section.dart';

class AdminTab extends ConsumerStatefulWidget {
  const AdminTab({super.key});

  @override
  ConsumerState<AdminTab> createState() => _AdminTabState();
}

class _AdminTabState extends ConsumerState<AdminTab> with TickerProviderStateMixin {
  late TabController _adminTabController;

  static const _segments = [
    GlassSegment('Company', icon: Icons.storefront_outlined),
    GlassSegment('Notifications', icon: Icons.campaign_outlined),
    GlassSegment('Re-engagement', icon: Icons.event_repeat_outlined),
    GlassSegment('Security', icon: Icons.shield_outlined),
    GlassSegment('Data', icon: Icons.storage_rounded),
    GlassSegment('About', icon: Icons.info_outline_rounded),
  ];

  @override
  void initState() {
    super.initState();
    _adminTabController = TabController(length: _segments.length, vsync: this);
  }

  @override
  void dispose() {
    _adminTabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppTokens.space4,
            AppTokens.space2,
            AppTokens.space4,
            0,
          ),
          child: GlassSegmentedTabs(
            controller: _adminTabController,
            segments: _segments,
            minSegmentWidth: 124,
            subtle: true,
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _adminTabController,
            children: const [
              CompanyConfigTab(),
              NotificationConfigTab(),
              ReengagementConfigTab(),
              SecurityConfigTab(),
              DataIntegrationsTab(),
              AboutTab(),
            ],
          ),
        ),
      ],
    );
  }
}
