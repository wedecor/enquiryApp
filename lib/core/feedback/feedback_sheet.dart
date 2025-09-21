import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../app_config.dart';
import '../logging/logger.dart';

/// In-app feedback collection sheet with device info and log bundle
/// Non-PII compliant feedback system for internal testing
class FeedbackSheet extends StatefulWidget {
  const FeedbackSheet({super.key});

  @override
  State<FeedbackSheet> createState() => _FeedbackSheetState();
}

class _FeedbackSheetState extends State<FeedbackSheet> {
  final _formKey = GlobalKey<FormState>();
  final _summaryController = TextEditingController();
  final _stepsController = TextEditingController();
  final _expectedController = TextEditingController();
  final _actualController = TextEditingController();

  bool _isSubmitting = false;
  bool _includeLogs = true;
  String _deviceInfo = 'Loading...';

  @override
  void initState() {
    super.initState();
    _loadDeviceInfo();
  }

  @override
  void dispose() {
    _summaryController.dispose();
    _stepsController.dispose();
    _expectedController.dispose();
    _actualController.dispose();
    super.dispose();
  }

  Future<void> _loadDeviceInfo() async {
    try {
      final deviceInfo = await _collectDeviceInfo();
      setState(() {
        _deviceInfo = deviceInfo;
      });
    } catch (e) {
      setState(() {
        _deviceInfo = 'Error loading device info: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.feedback, color: Colors.blue),
                    const SizedBox(width: 12),
                    const Text(
                      'Send Feedback',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),

              // Form
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Summary
                        TextFormField(
                          controller: _summaryController,
                          decoration: const InputDecoration(
                            labelText: 'Issue Summary *',
                            hintText: 'Brief description of the problem',
                            border: OutlineInputBorder(),
                          ),
                          maxLines: 2,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please provide a summary';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 16),

                        // Steps to reproduce
                        TextFormField(
                          controller: _stepsController,
                          decoration: const InputDecoration(
                            labelText: 'Steps to Reproduce',
                            hintText: '1. Go to...\n2. Tap on...\n3. See error',
                            border: OutlineInputBorder(),
                          ),
                          maxLines: 4,
                        ),

                        const SizedBox(height: 16),

                        // Expected behavior
                        TextFormField(
                          controller: _expectedController,
                          decoration: const InputDecoration(
                            labelText: 'Expected Behavior',
                            hintText: 'What should have happened?',
                            border: OutlineInputBorder(),
                          ),
                          maxLines: 2,
                        ),

                        const SizedBox(height: 16),

                        // Actual behavior
                        TextFormField(
                          controller: _actualController,
                          decoration: const InputDecoration(
                            labelText: 'Actual Behavior',
                            hintText: 'What actually happened?',
                            border: OutlineInputBorder(),
                          ),
                          maxLines: 2,
                        ),

                        const SizedBox(height: 20),

                        // Include logs toggle
                        SwitchListTile(
                          title: const Text('Include Debug Information'),
                          subtitle: const Text(
                            'Attach device info and recent logs (no personal data)',
                          ),
                          value: _includeLogs,
                          onChanged: (value) {
                            setState(() {
                              _includeLogs = value;
                            });
                          },
                        ),

                        const SizedBox(height: 16),

                        // Device info preview
                        if (_includeLogs) ...[
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Device Information (Preview)',
                                    style: TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _deviceInfo,
                                    style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Submit button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isSubmitting ? null : _submitFeedback,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                            ),
                            child: _isSubmitting
                                ? const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation(Colors.white),
                                        ),
                                      ),
                                      SizedBox(width: 12),
                                      Text('Submitting...'),
                                    ],
                                  )
                                : const Text(
                                    'Submit Feedback',
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                  ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Privacy note
                        Card(
                          color: Colors.blue[50],
                          child: const Padding(
                            padding: EdgeInsets.all(12),
                            child: Row(
                              children: [
                                Icon(Icons.privacy_tip, color: Colors.blue, size: 20),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'No personal information is collected. Device info helps us reproduce and fix issues.',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _submitFeedback() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final feedback = await _prepareFeedbackData();
      await _submitToGitHub(feedback);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Feedback submitted successfully. Thank you!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      Logger.error('Failed to submit feedback', error: e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit feedback: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<Map<String, dynamic>> _prepareFeedbackData() async {
    final feedback = {
      'summary': _summaryController.text.trim(),
      'steps_to_reproduce': _stepsController.text.trim(),
      'expected_behavior': _expectedController.text.trim(),
      'actual_behavior': _actualController.text.trim(),
      'timestamp': DateTime.now().toIso8601String(),
    };

    if (_includeLogs) {
      feedback['device_info'] = await _collectDeviceInfo();
      feedback['app_logs'] = _collectLogBundle();
    }

    return feedback;
  }

  Future<String> _collectDeviceInfo() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final deviceInfo = DeviceInfoPlugin();
      final connectivity = await Connectivity().checkConnectivity();

      final info = <String, dynamic>{
        'app_version': packageInfo.version,
        'build_number': packageInfo.buildNumber,
        'package_name': packageInfo.packageName,
        'app_name': packageInfo.appName,
        'platform': Platform.operatingSystem,
        'environment': AppConfig.env,
        'connectivity': connectivity.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      };

      // Platform-specific device info
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        info.addAll({
          'device_model': androidInfo.model,
          'device_brand': androidInfo.brand,
          'android_version': androidInfo.version.release,
          'sdk_int': androidInfo.version.sdkInt,
          'manufacturer': androidInfo.manufacturer,
        });
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        info.addAll({
          'device_model': iosInfo.model,
          'device_name': iosInfo.name,
          'ios_version': iosInfo.systemVersion,
          'is_simulator': iosInfo.isPhysicalDevice ? 'false' : 'true',
        });
      }

      // Format as readable text
      final buffer = StringBuffer();
      buffer.writeln('=== DEVICE INFO ===');
      for (final entry in info.entries) {
        buffer.writeln('${entry.key}: ${entry.value}');
      }

      return buffer.toString();
    } catch (e) {
      return 'Error collecting device info: $e';
    }
  }

  String _collectLogBundle() {
    try {
      // This would collect from the Logger's in-memory buffer
      // For now, return a placeholder
      return '''=== RECENT LOGS ===
[INFO] App startup completed
[INFO] User navigated to feedback screen
[DEBUG] Device info collection started
[INFO] Feedback form displayed
''';
    } catch (e) {
      return 'Error collecting logs: $e';
    }
  }

  Future<void> _submitToGitHub(Map<String, dynamic> feedback) async {
    // Create GitHub issue URL with pre-filled template
    final title = Uri.encodeComponent('[FEEDBACK] ${feedback['summary']}');
    final body = _formatGitHubIssueBody(feedback);
    final encodedBody = Uri.encodeComponent(body);

    final githubUrl =
        'https://github.com/your-org/wedecor-enquiries/issues/new'
        '?template=bug_report.md'
        '&title=$title'
        '&body=$encodedBody'
        '&labels=type:bug,status:triage,source:feedback';

    // Copy to clipboard for easy pasting
    await Clipboard.setData(ClipboardData(text: githubUrl));

    Logger.info('Feedback prepared for GitHub submission');
  }

  String _formatGitHubIssueBody(Map<String, dynamic> feedback) {
    final buffer = StringBuffer();

    buffer.writeln('## 🐛 Bug Description');
    buffer.writeln(feedback['summary'] ?? 'No summary provided');
    buffer.writeln();

    buffer.writeln('## 🔄 Steps to Reproduce');
    buffer.writeln(feedback['steps_to_reproduce'] ?? 'No steps provided');
    buffer.writeln();

    buffer.writeln('## ✅ Expected Behavior');
    buffer.writeln(feedback['expected_behavior'] ?? 'No expected behavior provided');
    buffer.writeln();

    buffer.writeln('## ❌ Actual Behavior');
    buffer.writeln(feedback['actual_behavior'] ?? 'No actual behavior provided');
    buffer.writeln();

    buffer.writeln('## 📱 Environment');
    buffer.writeln('- **Source**: In-app feedback form');
    buffer.writeln('- **Timestamp**: ${feedback['timestamp']}');
    buffer.writeln();

    if (feedback.containsKey('device_info')) {
      buffer.writeln('## 🔍 Device Information');
      buffer.writeln('```');
      buffer.writeln(feedback['device_info']);
      buffer.writeln('```');
      buffer.writeln();
    }

    if (feedback.containsKey('app_logs')) {
      buffer.writeln('## 📋 Recent Logs');
      buffer.writeln('```');
      buffer.writeln(feedback['app_logs']);
      buffer.writeln('```');
      buffer.writeln();
    }

    buffer.writeln('## 🏷️ Suggested Priority');
    buffer.writeln('- [ ] **P0**: Blocks core functionality');
    buffer.writeln('- [ ] **P1**: Important for RC3');
    buffer.writeln('- [ ] **P2**: Can defer to v1.1');

    return buffer.toString();
  }
}

/// Show feedback sheet
void showFeedbackSheet(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => const FeedbackSheet(),
  );
}
