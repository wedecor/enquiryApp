import 'package:flutter/material.dart';
import '../../core/app_config.dart';

/// Privacy Policy screen for legal compliance
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Privacy Policy',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Text(
              'Last updated: ${_lastUpdated}',
              style: TextStyle(color: Colors.grey),
            ),
            SizedBox(height: 24),
            
            _SectionWidget(
              title: 'Information We Collect',
              content: 'We collect information you provide directly to us, such as when you create an account, submit enquiries, or contact us for support.',
            ),
            
            _SectionWidget(
              title: 'How We Use Information',
              content: 'We use the information we collect to provide, maintain, and improve our services, process transactions, and communicate with you.',
            ),
            
            _SectionWidget(
              title: 'Information Sharing',
              content: 'We do not sell, trade, or otherwise transfer your personal information to third parties without your consent, except as described in this policy.',
            ),
            
            _SectionWidget(
              title: 'Data Security',
              content: 'We implement appropriate security measures to protect your personal information against unauthorized access, alteration, disclosure, or destruction.',
            ),
            
            _SectionWidget(
              title: 'Contact Us',
              content: 'If you have questions about this Privacy Policy, please contact us at ${AppConfig.supportEmail}',
            ),
            
            SizedBox(height: 32),
            Text(
              'This is a placeholder privacy policy. Please replace with your actual privacy policy that complies with applicable laws (GDPR, CCPA, etc.).',
              style: TextStyle(
                fontStyle: FontStyle.italic,
                color: Colors.orange,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  static const String _lastUpdated = 'September 2025';
}

class _SectionWidget extends StatelessWidget {
  final String title;
  final String content;
  
  const _SectionWidget({
    required this.title,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
