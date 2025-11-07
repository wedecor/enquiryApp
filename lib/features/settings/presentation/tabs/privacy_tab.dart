import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/app_config.dart';
import '../../../../core/feedback/feedback_sheet.dart';
import '../../../../core/services/consent_service.dart';
import '../../../legal/privacy_policy_screen.dart';
import '../../../legal/terms_of_service_screen.dart';

class PrivacyTab extends ConsumerStatefulWidget {
  const PrivacyTab({super.key});

  @override
  ConsumerState<PrivacyTab> createState() => _PrivacyTabState();
}

class _PrivacyTabState extends ConsumerState<PrivacyTab> {
  bool _analyticsConsent = false;
  bool _crashlyticsConsent = false;

  @override
  void initState() {
    super.initState();
    _loadConsentState();
  }

  Future<void> _loadConsentState() async {
    await ConsentService.instance.initialize();
    setState(() {
      _analyticsConsent = ConsentService.instance.hasAnalyticsConsent;
      _crashlyticsConsent = ConsentService.instance.hasCrashlyticsConsent;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Privacy & Data', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text(
          'Manage your privacy preferences and data sharing settings.',
          style: TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 24),

        // Analytics Consent
        Card(
          child: SwitchListTile(
            title: const Text('Share Anonymous Analytics'),
            subtitle: const Text(
              'Help us improve the app by sharing anonymous usage data. '
              'No personal information is collected.',
            ),
            value: _analyticsConsent,
            onChanged: AppConfig.enableAnalytics
                ? (value) async {
                    await ConsentService.instance.setAnalyticsConsent(value);
                    setState(() {
                      _analyticsConsent = value;
                    });

                    if (mounted) {
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
        ),

        const SizedBox(height: 16),

        // Crash Reporting Consent
        Card(
          child: SwitchListTile(
            title: const Text('Share Crash Reports'),
            subtitle: const Text(
              'Help us fix bugs by automatically sending crash reports. '
              'Requires app restart to take effect.',
            ),
            value: _crashlyticsConsent,
            onChanged: AppConfig.enableCrashlytics
                ? (value) async {
                    await ConsentService.instance.setCrashlyticsConsent(value);
                    setState(() {
                      _crashlyticsConsent = value;
                    });

                    if (mounted) {
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
        ),

        const SizedBox(height: 32),

        // Legal Documents
        const Text('Legal Documents', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),

        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.privacy_tip),
                title: const Text('Privacy Policy'),
                subtitle: const Text('How we handle your personal information'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => Navigator.of(
                  context,
                ).push(MaterialPageRoute<void>(builder: (context) => const PrivacyPolicyScreen())),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.description),
                title: const Text('Terms of Service'),
                subtitle: const Text('Terms and conditions for using this app'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => Navigator.of(
                  context,
                ).push(MaterialPageRoute<void>(builder: (context) => const TermsOfServiceScreen())),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Help & Support
        const Text('Help & Support', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),

        Card(
          child: ListTile(
            leading: const Icon(Icons.feedback),
            title: const Text('Send Feedback'),
            subtitle: const Text('Report issues or suggest improvements'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => showFeedbackSheet(context),
          ),
        ),

        const SizedBox(height: 24),

        // App Information
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'App Information',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                const Text('Version: 1.0.0+1'),
                const Text('Environment: ${AppConfig.env}'),
                const Text('Build: ${kReleaseMode ? "Production" : "Development"}'),
                const SizedBox(height: 8),
                Text('© ${DateTime.now().year} We Decor Enquiries. All rights reserved.'),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
