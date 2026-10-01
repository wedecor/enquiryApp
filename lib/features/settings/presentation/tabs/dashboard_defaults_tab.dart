import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/logging/safe_log.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/user_settings.dart';
import '../../providers/settings_providers.dart';
import '../../../../ui/components/glass_state_message.dart';
import '../widgets/settings_layout.dart';
import '../widgets/settings_tiles.dart';

class DashboardDefaultsTab extends ConsumerStatefulWidget {
  const DashboardDefaultsTab({super.key});

  @override
  ConsumerState<DashboardDefaultsTab> createState() => _DashboardDefaultsTabState();
}

class _DashboardDefaultsTabState extends ConsumerState<DashboardDefaultsTab> {
  UserSettings? _originalSettings;
  UserSettings? _currentSettings;
  bool _hasChanges = false;
  bool _isSaving = false;

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(currentUserSettingsProvider);

    return settingsAsync.when(
      data: (settings) {
        if (_originalSettings == null) {
          _originalSettings = settings;
          _currentSettings = settings;
        }

        return _buildDashboardContent(context, settings);
      },
      loading: () => const GlassLoadingState(),
      error: (error, stack) => GlassStateMessage(
        icon: Icons.error_outline_rounded,
        title: 'Dashboard settings unavailable',
        message: 'Error loading dashboard settings: $error',
        color: Theme.of(context).colorScheme.error,
      ),
    );
  }

  Widget _buildDashboardContent(BuildContext context, UserSettings settings) {
    return SettingsEditableBody(
      hasChanges: _hasChanges,
      isSaving: _isSaving,
      onSave: _saveChanges,
      onDiscard: _discardChanges,
      child: SettingsScrollBody(
        children: [
          _buildDateRangeSection(context),
          _buildStatusTabsSection(context),
          _buildColumnsSection(context),
        ],
      ),
    );
  }

  Widget _buildDateRangeSection(BuildContext context) {
    final dateRangeOptions = [
      ('7d', '7 Days', 'Last 7 days'),
      ('30d', '30 Days', 'Last 30 days (default)'),
      ('90d', '90 Days', 'Last 90 days'),
      ('ytd', 'Year to Date', 'From January 1st'),
    ];
    final groupValue = _currentSettings?.dashboard.dateRange ?? '30d';

    return SettingsGroup(
      eyebrow: 'Period',
      title: 'Default Date Range',
      subtitle: 'Default time period for dashboard and analytics',
      dividerIndent: 16,
      children: [
        for (final (value, title, subtitle) in dateRangeOptions)
          SettingsChoiceTile(
            title: title,
            subtitle: subtitle,
            selected: groupValue == value,
            onTap: () {
              final newDashboard = _currentSettings!.dashboard.copyWith(dateRange: value);
              _updateSettings(_currentSettings!.copyWith(dashboard: newDashboard));
            },
          ),
      ],
    );
  }

  Widget _buildStatusTabsSection(BuildContext context) {
    final availableStatuses = [
      ('new', 'New', 'Newly created enquiries'),
      ('in_talks', 'In Talks', 'Currently being discussed with customer'),
      ('approved', 'Approved', 'Booking confirmed — event date set'),
      ('completed', 'Completed', 'Successfully completed'),
      ('cancelled', 'Cancelled', 'Cancelled enquiries'),
      ('closed_lost', 'Closed Lost', 'Lost opportunities'),
    ];

    final currentTabs = _currentSettings?.dashboard.statusTabs ?? ['new', 'in_talks', 'approved'];

    return SettingsGroup(
      eyebrow: 'Pipeline',
      title: 'Default Status Tabs',
      subtitle: 'Which status tabs to show by default on the dashboard',
      children: [
        for (final (value, title, subtitle) in availableStatuses)
          SettingsChoiceTile(
            multiSelect: true,
            icon: Icons.fiber_manual_record_rounded,
            iconColor: AppColorScheme.statusColorFor(value),
            title: title,
            subtitle: subtitle,
            selected: currentTabs.contains(value),
            onTap: () {
              final checked = !currentTabs.contains(value);
              List<String> newTabs = List.from(currentTabs);
              if (checked) {
                if (!newTabs.contains(value)) {
                  newTabs.add(value);
                }
              } else {
                newTabs.remove(value);
              }

              // Ensure at least one tab is selected
              if (newTabs.isEmpty) {
                newTabs = ['new'];
              }

              final newDashboard = _currentSettings!.dashboard.copyWith(statusTabs: newTabs);
              _updateSettings(_currentSettings!.copyWith(dashboard: newDashboard));
            },
          ),
      ],
    );
  }

  Widget _buildColumnsSection(BuildContext context) {
    final availableColumns = [
      ('customer', 'Customer', 'Customer name and contact'),
      ('eventType', 'Event Type', 'Type of event'),
      ('status', 'Status', 'Current enquiry status'),
      ('priority', 'Priority', 'Priority level'),
      ('createdAt', 'Created Date', 'When enquiry was created'),
      ('assignedTo', 'Assigned To', 'Staff member assigned'),
      ('totalCost', 'Total Cost', 'Estimated total cost'),
      ('source', 'Source', 'How customer found us'),
    ];

    final currentColumns = _currentSettings?.dashboard.columns ?? [];

    return SettingsGroup(
      eyebrow: 'Lists',
      title: 'Table Columns',
      subtitle: 'Configure which columns to show in enquiry lists',
      dividerIndent: 16,
      children: [
        for (final (id, title, subtitle) in availableColumns)
          SettingsChoiceTile(
            multiSelect: true,
            title: title,
            subtitle: subtitle,
            selected: currentColumns
                .firstWhere(
                  (col) => col.id == id,
                  orElse: () => ColumnSettings(id: id, visible: false, order: 0),
                )
                .visible,
            onTap: () {
              final existingColumn = currentColumns.firstWhere(
                (col) => col.id == id,
                orElse: () => ColumnSettings(id: id, visible: false, order: 0),
              );
              final checked = !existingColumn.visible;
              final List<ColumnSettings> newColumns = List.from(currentColumns);

              // Remove existing column with same id
              newColumns.removeWhere((col) => col.id == id);

              if (checked) {
                // Add column with next order
                final maxOrder = newColumns.isEmpty
                    ? 0
                    : newColumns.map((col) => col.order).reduce((a, b) => a > b ? a : b);
                newColumns.add(ColumnSettings(id: id, visible: true, order: maxOrder + 1));
              }

              // Sort by order
              newColumns.sort((a, b) => a.order.compareTo(b.order));

              final newDashboard = _currentSettings!.dashboard.copyWith(columns: newColumns);
              _updateSettings(_currentSettings!.copyWith(dashboard: newDashboard));
            },
          ),
      ],
    );
  }

  void _updateSettings(UserSettings newSettings) {
    setState(() {
      _currentSettings = newSettings;
      _hasChanges = _currentSettings != _originalSettings;
    });
  }

  Future<void> _saveChanges() async {
    if (_currentSettings == null || !_hasChanges || _isSaving) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final updateSettings = ref.read(updateUserSettingsProvider);
      await updateSettings(_currentSettings!);

      setState(() {
        _originalSettings = _currentSettings;
        _hasChanges = false;
        _isSaving = false;
      });

      safeLog('dashboard_settings_saved', {
        'dateRange': _currentSettings!.dashboard.dateRange,
        'statusTabsCount': _currentSettings!.dashboard.statusTabs.length,
        'visibleColumnsCount': _currentSettings!.dashboard.columns
            .where((col) => col.visible)
            .length,
      });

      if (mounted) {
        _showSnackBar('Dashboard settings saved successfully');
      }
    } catch (e) {
      setState(() {
        _isSaving = false;
      });

      safeLog('dashboard_settings_save_error', {
        'error': e.toString(),
        'errorType': e.runtimeType.toString(),
      });

      if (mounted) {
        _showSnackBar('Failed to save dashboard settings', isError: true);
      }
    }
  }

  void _discardChanges() {
    setState(() {
      _currentSettings = _originalSettings;
      _hasChanges = false;
    });
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColorScheme.snackError : AppColorScheme.snackSuccess,
        action: SnackBarAction(label: 'OK', textColor: Colors.white, onPressed: () {}),
      ),
    );
  }
}
