import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../appearance_controller.dart';
import '../tokens.dart';

/// Appearance setting widget for selecting light/dark/system theme
/// 
/// Provides a segmented button interface for theme selection with
/// immediate visual feedback and persistence across app restarts.
class AppearanceSetting extends ConsumerWidget {
  const AppearanceSetting({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(appearanceControllerProvider);
    final theme = Theme.of(context);

    void onChanged(AppearanceMode? m) {
      if (m != null) {
        ref.read(appearanceControllerProvider.notifier).set(m);
      }
    }

    return Card(
      child: Padding(
        padding: EdgeInsets.all(AppTokens.space4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Appearance',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: AppTokens.space2),
            Text(
              'Choose how the app looks on your device',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            SizedBox(height: AppTokens.space4),
            
            // Segmented Button for theme selection
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<AppearanceMode>(
                segments: [
                  ButtonSegment(
                    value: AppearanceMode.system,
                    label: const Text('System'),
                    icon: const Icon(Icons.brightness_auto),
                    tooltip: 'Follow system setting',
                  ),
                  ButtonSegment(
                    value: AppearanceMode.light,
                    label: const Text('Light'),
                    icon: const Icon(Icons.light_mode),
                    tooltip: 'Always use light theme',
                  ),
                  ButtonSegment(
                    value: AppearanceMode.dark,
                    label: const Text('Dark'),
                    icon: const Icon(Icons.dark_mode),
                    tooltip: 'Always use dark theme',
                  ),
                ],
                selected: {mode},
                onSelectionChanged: (selection) => onChanged(selection.first),
                style: SegmentedButton.styleFrom(
                  selectedBackgroundColor: theme.colorScheme.primaryContainer,
                  selectedForegroundColor: theme.colorScheme.onPrimaryContainer,
                  foregroundColor: theme.colorScheme.onSurface,
                ),
              ),
            ),
            
            SizedBox(height: AppTokens.space3),
            
            // Current mode description
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(AppTokens.space3),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                borderRadius: AppRadius.medium,
              ),
              child: Row(
                children: [
                  Icon(
                    _getModeIcon(mode),
                    size: AppTokens.iconSmall,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  SizedBox(width: AppTokens.space2),
                  Expanded(
                    child: Text(
                      _getModeDescription(mode),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getModeIcon(AppearanceMode mode) {
    switch (mode) {
      case AppearanceMode.system:
        return Icons.brightness_auto;
      case AppearanceMode.light:
        return Icons.light_mode;
      case AppearanceMode.dark:
        return Icons.dark_mode;
    }
  }

  String _getModeDescription(AppearanceMode mode) {
    switch (mode) {
      case AppearanceMode.system:
        return 'Theme changes automatically based on your device settings';
      case AppearanceMode.light:
        return 'App will always use the light theme';
      case AppearanceMode.dark:
        return 'App will always use the dark theme';
    }
  }
}
