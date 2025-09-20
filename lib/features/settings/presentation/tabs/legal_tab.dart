import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class LegalTab extends StatelessWidget {
  const LegalTab({super.key});

  @override
  Widget build(BuildContext context) {
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
          onTap: () => _launchUrl('https://your-domain.com/privacy-policy'),
        ),
        
        const SizedBox(height: 16),
        
        _buildLegalCard(
          context,
          icon: Icons.description,
          title: 'Terms of Service',
          description: 'Read our terms and conditions for using this service.',
          onTap: () => _launchUrl('https://your-domain.com/terms-of-service'),
        ),
        
        const SizedBox(height: 16),
        
        _buildLegalCard(
          context,
          icon: Icons.cookie,
          title: 'Data & Cookies',
          description: 'Manage your data preferences and cookie settings.',
          onTap: () => _showDataPreferences(context),
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

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _showDataPreferences(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Data Preferences'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Analytics: Enabled'),
            Text('Crash Reporting: Enabled'),
            Text('Performance Monitoring: Enabled'),
            SizedBox(height: 16),
            Text(
              'Note: These settings help us improve the app experience. '
              'You can opt-out by contacting support.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
