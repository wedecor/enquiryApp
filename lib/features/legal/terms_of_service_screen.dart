import 'package:flutter/material.dart';

import '../../core/app_config.dart';
import 'widgets/legal_document.dart';

/// Terms of Service screen for legal compliance
class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const LegalDocument(
      title: 'Terms of Service',
      lastUpdated: _lastUpdated,
      sections: [
        LegalSection(
          title: 'Acceptance of Terms',
          content:
              'By accessing and using this application, you accept and agree to be bound by the terms and provision of this agreement.',
        ),
        LegalSection(
          title: 'Use License',
          content:
              'Permission is granted to temporarily use this application for personal, non-commercial transitory viewing only.',
        ),
        LegalSection(
          title: 'Disclaimer',
          content:
              'The materials in this application are provided on an "as is" basis. We make no warranties, expressed or implied.',
        ),
        LegalSection(
          title: 'Limitations',
          content:
              'In no event shall We Decor Enquiries or its suppliers be liable for any damages arising out of the use or inability to use this application.',
        ),
        LegalSection(
          title: 'Governing Law',
          content:
              'These terms and conditions are governed by and construed in accordance with applicable laws.',
        ),
        LegalSection(
          title: 'Contact Information',
          content:
              'If you have any questions about these Terms of Service, please contact us at ${AppConfig.supportEmail}',
        ),
      ],
      disclaimer:
          'This is a placeholder terms of service. Please replace with your actual terms that comply with applicable laws and your business requirements.',
    );
  }

  static const String _lastUpdated = 'September 2025';
}
