import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/theme/tokens.dart';
import '../../../../../ui/components/brand_mark.dart';
import '../../../../../ui/primitives/primitives.dart';
import '../../widgets/settings_layout.dart';
import '../../widgets/settings_tiles.dart';

class AboutTab extends ConsumerStatefulWidget {
  const AboutTab({super.key});

  @override
  ConsumerState<AboutTab> createState() => _AboutTabState();
}

class _AboutTabState extends ConsumerState<AboutTab> {
  String? _versionDisplay;
  String? _buildNumber;
  bool _isLoadingVersion = true;

  @override
  void initState() {
    super.initState();
    _loadAppInfo();
  }

  Future<void> _loadAppInfo() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      if (!mounted) return;
      setState(() {
        _versionDisplay = packageInfo.version;
        _buildNumber = packageInfo.buildNumber;
        _isLoadingVersion = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _versionDisplay = 'Unknown';
        _buildNumber = 'Unknown';
        _isLoadingVersion = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    return SettingsScrollBody(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(AppTokens.space1, AppTokens.space5, 0, 0),
          child: SplitHeading(light: 'About', bold: 'WeDecor Events', style: t.headlineMedium),
        ),
        Padding(
          padding: const EdgeInsets.only(top: AppTokens.space5),
          child: GlassPanel(
            padding: const EdgeInsets.all(AppTokens.space5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const BrandMark(showSubtitle: true, size: 34),
                const SizedBox(height: AppTokens.space5),
                Text(
                  'WeDecor Events Management System',
                  style: t.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: AppTokens.space2),
                Text(
                  'A comprehensive enquiry and event management system built with Flutter, Firebase, and modern web technologies.',
                  style: t.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w300,
                    color: cs.onSurfaceVariant,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: AppTokens.space4),
                const Divider(height: 1),
                const SizedBox(height: AppTokens.space2),
                SettingsInfoRow(
                  label: 'Version',
                  value: _isLoadingVersion ? 'Loading...' : '$_versionDisplay+$_buildNumber',
                ),
                const SettingsInfoRow(label: 'Build', value: kDebugMode ? 'Debug' : 'Release'),
                const SettingsInfoRow(label: 'Region', value: 'asia-south1'),
                SettingsInfoRow(
                  label: 'Platform',
                  value: kIsWeb
                      ? 'Web'
                      : (defaultTargetPlatform == TargetPlatform.android
                            ? 'Android'
                            : defaultTargetPlatform == TargetPlatform.iOS
                            ? 'iOS'
                            : 'Unknown'),
                ),
                const SettingsInfoRow(label: 'Framework', value: 'Flutter 3.x'),
                const SettingsInfoRow(label: 'Backend', value: 'Firebase'),
              ],
            ),
          ),
        ),
        const SettingsGroup(
          eyebrow: 'Capabilities',
          title: 'Features',
          separated: false,
          padding: EdgeInsets.symmetric(horizontal: AppTokens.space4, vertical: AppTokens.space2),
          children: [
            _FeatureItem('Enquiry Management', 'Track and manage customer enquiries'),
            _FeatureItem('User Management', 'Role-based access control'),
            _FeatureItem('Analytics', 'Comprehensive reporting and insights'),
            _FeatureItem('Notifications', 'Real-time push and email notifications'),
            _FeatureItem('Settings', 'Customizable user and system preferences'),
            _FeatureItem('Export', 'CSV export for data analysis'),
          ],
        ),
        SettingsNote(
          title: 'Support',
          icon: Icons.support_agent_rounded,
          body:
              'For technical support or feature requests, please contact your system administrator.',
          child: Row(
            children: [
              const Icon(Icons.verified_user_outlined, color: AppColorScheme.chartGreen, size: 16),
              const SizedBox(width: AppTokens.space2),
              Expanded(
                child: Text(
                  'All data is encrypted and securely stored',
                  style: t.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FeatureItem extends StatelessWidget {
  const _FeatureItem(this.title, this.description);

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final s = AppSurfaces.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTokens.space2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: StatusDot(color: s.accent, size: 6),
          ),
          const SizedBox(width: AppTokens.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: t.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                Text(
                  description,
                  style: t.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w300,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
