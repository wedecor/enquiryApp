import 'package:flutter/material.dart';
import '../../core/app_config.dart';

/// Terms of Service screen for legal compliance
class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Terms of Service'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Terms of Service', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            SizedBox(height: 16),
            Text('Last updated: ${_lastUpdated}', style: TextStyle(color: Colors.grey)),
            SizedBox(height: 24),

            _SectionWidget(
              title: 'Acceptance of Terms',
              content:
                  'By accessing and using this application, you accept and agree to be bound by the terms and provision of this agreement.',
            ),

            _SectionWidget(
              title: 'Use License',
              content:
                  'Permission is granted to temporarily use this application for personal, non-commercial transitory viewing only.',
            ),

            _SectionWidget(
              title: 'Disclaimer',
              content:
                  'The materials in this application are provided on an "as is" basis. We make no warranties, expressed or implied.',
            ),

            _SectionWidget(
              title: 'Limitations',
              content:
                  'In no event shall We Decor Enquiries or its suppliers be liable for any damages arising out of the use or inability to use this application.',
            ),

            _SectionWidget(
              title: 'Governing Law',
              content:
                  'These terms and conditions are governed by and construed in accordance with applicable laws.',
            ),

            _SectionWidget(
              title: 'Contact Information',
              content:
                  'If you have any questions about these Terms of Service, please contact us at ${AppConfig.supportEmail}',
            ),

            SizedBox(height: 32),
            Text(
              'This is a placeholder terms of service. Please replace with your actual terms that comply with applicable laws and your business requirements.',
              style: TextStyle(fontStyle: FontStyle.italic, color: Colors.orange, fontSize: 12),
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

  const _SectionWidget({required this.title, required this.content});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text(content, style: const TextStyle(fontSize: 14, height: 1.5)),
        ],
      ),
    );
  }
}
