import 'package:flutter/material.dart';

import '../../core/app_config.dart';
import 'widgets/legal_document.dart';

/// Privacy Policy screen for legal compliance
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const LegalDocument(
      title: 'Privacy Policy',
      lastUpdated: _lastUpdated,
      sections: [
        LegalSection(
          title: 'Information We Collect',
          content:
              'We collect information you provide directly to us, such as when you create an account, submit enquiries, or contact us for support.',
        ),
        LegalSection(
          title: 'How We Use Information',
          content:
              'We use the information we collect to provide, maintain, and improve our services, process transactions, and communicate with you.',
        ),
        LegalSection(
          title: 'Information Sharing',
          content:
              'We do not sell, trade, or otherwise transfer your personal information to third parties without your consent, except as described in this policy.',
        ),
        LegalSection(
          title: 'Data Security',
          content:
              'We implement appropriate security measures to protect your personal information against unauthorized access, alteration, disclosure, or destruction.',
        ),
        LegalSection(
          title: 'Contact Us',
          content:
              'If you have questions about this Privacy Policy, please contact us at ${AppConfig.supportEmail}',
        ),
      ],
      disclaimer:
          'This is a placeholder privacy policy. Please replace with your actual privacy policy that complies with applicable laws (GDPR, CCPA, etc.).',
    );
  }

  static const String _lastUpdated = 'September 2025';
}
