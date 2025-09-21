import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../logging/logger.dart';

/// Service for checking app updates and notifying users
class UpdateService {
  static const String _updateCheckUrl = 'https://wedecorenquries.web.app/internal/rc3/version.json';
  static const String _downloadUrl = 'https://wedecorenquries.web.app/internal/rc3/app-release.apk';
  static const String _lastDismissedKey = 'last_dismissed_update';
  static const String _lastCheckedKey = 'last_update_check';

  /// Check for available updates
  static Future<UpdateInfo?> checkForUpdate() async {
    try {
      // Rate limit: only check once per hour
      final prefs = await SharedPreferences.getInstance();
      final lastChecked = prefs.getInt(_lastCheckedKey) ?? 0;
      final now = DateTime.now().millisecondsSinceEpoch;
      
      if (now - lastChecked < 3600000) { // 1 hour
        Logger.debug('Update check skipped - rate limited', tag: 'UpdateService');
        return null;
      }

      // Get current app version
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;
      final currentBuildNumber = int.tryParse(packageInfo.buildNumber) ?? 0;

      Logger.info('Checking for updates - current: $currentVersion+$currentBuildNumber', tag: 'UpdateService');

      // Fetch remote version info
      final response = await http.get(
        Uri.parse(_updateCheckUrl),
        headers: {'Cache-Control': 'no-cache'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        Logger.warn('Update check failed - HTTP ${response.statusCode}', tag: 'UpdateService');
        return null;
      }

      final versionData = json.decode(response.body) as Map<String, dynamic>;
      final remoteVersion = versionData['version'] as String?;
      final remoteBuildNumber = versionData['buildNumber'] as int?;
      final releaseNotes = versionData['releaseNotes'] as String?;
      final isForced = versionData['forceUpdate'] as bool? ?? false;
      final downloadUrl = versionData['downloadUrl'] as String? ?? _downloadUrl;

      if (remoteVersion == null || remoteBuildNumber == null) {
        Logger.warn('Invalid version data received', tag: 'UpdateService');
        return null;
      }

      // Update last checked timestamp
      await prefs.setInt(_lastCheckedKey, now);

      // Check if update is available
      if (remoteBuildNumber > currentBuildNumber) {
        Logger.info('Update available: $remoteVersion+$remoteBuildNumber', tag: 'UpdateService');
        
        return UpdateInfo(
          currentVersion: currentVersion,
          currentBuildNumber: currentBuildNumber,
          latestVersion: remoteVersion,
          latestBuildNumber: remoteBuildNumber,
          releaseNotes: releaseNotes ?? 'Bug fixes and improvements',
          downloadUrl: downloadUrl,
          isForced: isForced,
        );
      }

      Logger.info('App is up to date', tag: 'UpdateService');
      return null;
    } catch (e) {
      Logger.error('Error checking for updates', error: e, tag: 'UpdateService');
      return null;
    }
  }

  /// Show update dialog to user
  static Future<void> showUpdateDialog(BuildContext context, UpdateInfo updateInfo) async {
    final prefs = await SharedPreferences.getInstance();
    final lastDismissed = prefs.getInt(_lastDismissedKey) ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;

    // Don't show again if dismissed within last 24 hours (unless forced)
    if (!updateInfo.isForced && now - lastDismissed < 86400000) { // 24 hours
      return;
    }

    if (!context.mounted) return;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: !updateInfo.isForced,
      builder: (context) => UpdateDialog(updateInfo: updateInfo),
    );

    // Record dismissal if user chose not to update
    if (result == false) {
      await prefs.setInt(_lastDismissedKey, now);
    }
  }

  /// Launch download URL
  static Future<void> downloadUpdate(String downloadUrl) async {
    try {
      final uri = Uri.parse(downloadUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        Logger.info('Update download launched', tag: 'UpdateService');
      } else {
        throw Exception('Cannot launch download URL');
      }
    } catch (e) {
      Logger.error('Failed to launch download', error: e, tag: 'UpdateService');
    }
  }

  /// Copy download URL to clipboard
  static Future<void> copyDownloadUrl(String downloadUrl) async {
    try {
      await Clipboard.setData(ClipboardData(text: downloadUrl));
      Logger.info('Download URL copied to clipboard', tag: 'UpdateService');
    } catch (e) {
      Logger.error('Failed to copy download URL', error: e, tag: 'UpdateService');
    }
  }
}

/// Model for update information
class UpdateInfo {
  final String currentVersion;
  final int currentBuildNumber;
  final String latestVersion;
  final int latestBuildNumber;
  final String releaseNotes;
  final String downloadUrl;
  final bool isForced;

  UpdateInfo({
    required this.currentVersion,
    required this.currentBuildNumber,
    required this.latestVersion,
    required this.latestBuildNumber,
    required this.releaseNotes,
    required this.downloadUrl,
    required this.isForced,
  });

  String get currentVersionString => '$currentVersion+$currentBuildNumber';
  String get latestVersionString => '$latestVersion+$latestBuildNumber';
}

/// Dialog widget for showing update information
class UpdateDialog extends StatelessWidget {
  final UpdateInfo updateInfo;

  const UpdateDialog({super.key, required this.updateInfo});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: Row(
        children: [
          Icon(
            updateInfo.isForced ? Icons.system_update : Icons.system_update_alt,
            color: updateInfo.isForced ? Colors.red : theme.colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Text(
            updateInfo.isForced ? 'Update Required' : 'Update Available',
            style: TextStyle(
              color: updateInfo.isForced ? Colors.red : theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Version info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text('Current: ', style: TextStyle(fontWeight: FontWeight.w500)),
                      Text(updateInfo.currentVersionString),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Text('Latest: ', style: TextStyle(fontWeight: FontWeight.w500)),
                      Text(
                        updateInfo.latestVersionString,
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Release notes
            Text(
              'What\'s New:',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              updateInfo.releaseNotes,
              style: theme.textTheme.bodyMedium,
            ),

            if (updateInfo.isForced) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  border: Border.all(color: Colors.red[200]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning, color: Colors.red[700], size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'This update is required to continue using the app.',
                        style: TextStyle(
                          color: Colors.red[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        if (!updateInfo.isForced)
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Later'),
          ),
        TextButton(
          onPressed: () {
            UpdateService.copyDownloadUrl(updateInfo.downloadUrl);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Download link copied to clipboard'),
                duration: Duration(seconds: 2),
              ),
            );
          },
          child: const Text('Copy Link'),
        ),
        ElevatedButton(
          onPressed: () {
            UpdateService.downloadUpdate(updateInfo.downloadUrl);
            Navigator.of(context).pop(true);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: updateInfo.isForced ? Colors.red : theme.colorScheme.primary,
            foregroundColor: Colors.white,
          ),
          child: const Text('Download'),
        ),
      ],
    );
  }
}

/// Widget to check for updates and show notification
class UpdateChecker extends StatefulWidget {
  final Widget child;
  final bool checkOnStart;

  const UpdateChecker({
    super.key,
    required this.child,
    this.checkOnStart = true,
  });

  @override
  State<UpdateChecker> createState() => _UpdateCheckerState();
}

class _UpdateCheckerState extends State<UpdateChecker> {
  @override
  void initState() {
    super.initState();
    if (widget.checkOnStart) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _checkForUpdate();
      });
    }
  }

  Future<void> _checkForUpdate() async {
    try {
      final updateInfo = await UpdateService.checkForUpdate();
      if (updateInfo != null && mounted) {
        await UpdateService.showUpdateDialog(context, updateInfo);
      }
    } catch (e) {
      Logger.error('Error in update checker', error: e, tag: 'UpdateChecker');
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

/// Extension to easily add update checking to any widget
extension UpdateCheckExtension on Widget {
  /// Wrap widget with update checker
  Widget withUpdateChecker({bool checkOnStart = true}) {
    return UpdateChecker(
      checkOnStart: checkOnStart,
      child: this,
    );
  }
}
