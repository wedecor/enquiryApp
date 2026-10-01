import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../../core/app_config.dart';
import '../../../../core/feedback/feedback_sheet.dart';
import '../../../../core/services/consent_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../ui/components/brand_mark.dart';
import '../../../../ui/primitives/primitives.dart';
import '../../../legal/privacy_policy_screen.dart';
import '../../../legal/terms_of_service_screen.dart';
import '../widgets/settings_layout.dart';
import '../widgets/settings_tiles.dart';

class PrivacyTab extends ConsumerStatefulWidget {
  const PrivacyTab({super.key});

  @override
  ConsumerState<PrivacyTab> createState() => _PrivacyTabState();
}

class _PrivacyTabState extends ConsumerState<PrivacyTab> {
  bool _analyticsConsent = false;
  bool _crashlyticsConsent = false;
  String? _versionDisplay;
  bool _isLoadingVersion = true;

  @override
  void initState() {
    super.initState();
    _loadConsentState();
    _loadAppInfo();
  }

  Future<void> _loadConsentState() async {
    await ConsentService.instance.initialize();
    setState(() {
      _analyticsConsent = ConsentService.instance.hasAnalyticsConsent;
      _crashlyticsConsent = ConsentService.instance.hasCrashlyticsConsent;
    });
  }

  Future<void> _loadAppInfo() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      if (!mounted) return;
      setState(() {
        _versionDisplay = '${packageInfo.version}+${packageInfo.buildNumber}';
        _isLoadingVersion = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _versionDisplay = 'Unknown';
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
          padding: const EdgeInsets.fromLTRB(
            AppTokens.space1,
            AppTokens.space5,
            AppTokens.space1,
            0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SplitHeading(light: 'Privacy &', bold: 'Data', style: t.headlineMedium),
              const SizedBox(height: AppTokens.space2),
              Text(
                'Manage your privacy preferences and data sharing settings.',
                style: t.bodyMedium?.copyWith(
                  color: cs.onSurfaceVariant,
                  fontWeight: FontWeight.w300,
                ),
              ),
            ],
          ),
        ),
        SettingsGroup(
          eyebrow: 'Consent',
          title: 'Data Sharing',
          children: [
            SettingsSwitchTile(
              icon: Icons.insights_rounded,
              iconColor: AppColorScheme.chartBlue,
              title: 'Share Anonymous Analytics',
              subtitle:
                  'Help us improve the app by sharing anonymous usage data. '
                  'No personal information is collected.',
              value: _analyticsConsent,
              onChanged: AppConfig.enableAnalytics
                  ? (value) async {
                      await ConsentService.instance.setAnalyticsConsent(value);
                      setState(() {
                        _analyticsConsent = value;
                      });

                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              value
                                  ? 'Analytics enabled. Thank you for helping us improve!'
                                  : 'Analytics disabled. Your privacy is protected.',
                            ),
                          ),
                        );
                      }
                    }
                  : null,
            ),
            SettingsSwitchTile(
              icon: Icons.bug_report_outlined,
              iconColor: AppColorScheme.chartOrange,
              title: 'Share Crash Reports',
              subtitle:
                  'Help us fix bugs by automatically sending crash reports. '
                  'Requires app restart to take effect.',
              value: _crashlyticsConsent,
              onChanged: AppConfig.enableCrashlytics
                  ? (value) async {
                      await ConsentService.instance.setCrashlyticsConsent(value);
                      setState(() {
                        _crashlyticsConsent = value;
                      });

                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Crash reporting preference saved. Restart app to apply changes.',
                            ),
                          ),
                        );
                      }
                    }
                  : null,
            ),
          ],
        ),
        SettingsGroup(
          eyebrow: 'Policies',
          title: 'Legal Documents',
          children: [
            SettingsTile(
              icon: Icons.privacy_tip_outlined,
              title: 'Privacy Policy',
              subtitle: 'How we handle your personal information',
              trailing: const SettingsChevron(),
              onTap: () => Navigator.of(
                context,
              ).push(MaterialPageRoute<void>(builder: (context) => const PrivacyPolicyScreen())),
            ),
            SettingsTile(
              icon: Icons.description_outlined,
              title: 'Terms of Service',
              subtitle: 'Terms and conditions for using this app',
              trailing: const SettingsChevron(),
              onTap: () => Navigator.of(
                context,
              ).push(MaterialPageRoute<void>(builder: (context) => const TermsOfServiceScreen())),
            ),
          ],
        ),
        SettingsGroup(
          eyebrow: 'Support',
          title: 'Help & Support',
          children: [
            SettingsTile(
              icon: Icons.feedback_outlined,
              title: 'Send Feedback',
              subtitle: 'Report issues or suggest improvements',
              trailing: const SettingsChevron(),
              onTap: () => showFeedbackSheet(context),
            ),
          ],
        ),
        SettingsGroup(
          eyebrow: 'Build',
          title: 'App Information',
          separated: false,
          padding: const EdgeInsets.all(AppTokens.space4),
          children: [
            const Padding(
              padding: EdgeInsets.only(bottom: AppTokens.space3),
              child: BrandMark(showSubtitle: true, size: 26),
            ),
            SettingsInfoRow(
              label: 'Version',
              value: _versionDisplay ?? (_isLoadingVersion ? 'Loading…' : 'Unknown'),
            ),
            const SettingsInfoRow(label: 'Environment', value: AppConfig.env),
            const SettingsInfoRow(
              label: 'Build',
              value: kReleaseMode ? 'Production' : 'Development',
            ),
            const SizedBox(height: AppTokens.space2),
            Text(
              '© ${DateTime.now().year} We Decor Enquiries. All rights reserved.',
              style: t.bodySmall?.copyWith(fontWeight: FontWeight.w300),
            ),
          ],
        ),
      ],
    );
  }
}
