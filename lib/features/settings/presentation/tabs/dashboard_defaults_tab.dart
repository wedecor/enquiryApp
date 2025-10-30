import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/logging/safe_log.dart';
import '../../domain/user_settings.dart';
import '../../providers/settings_providers.dart';

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
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error loading dashboard settings: $error')),
    );
  }

  Widget _buildDashboardContent(BuildContext context, UserSettings settings) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDateRangeSection(context),
                const SizedBox(height: 24),
                _buildStatusTabsSection(context),
                const SizedBox(height: 24),
                _buildColumnsSection(context),
              ],
            ),
          ),
        ),
        if (_hasChanges) _buildSaveSection(context),
      ],
    );
  }

  Widget _buildDateRangeSection(BuildContext context) {
    final dateRangeOptions = [
      ('7d', '7 Days', 'Last 7 days'),
      ('30d', '30 Days', 'Last 30 days (default)'),
      ('90d', '90 Days', 'Last 90 days'),
      ('ytd', 'Year to Date', 'From January 1st'),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Default Date Range', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              'Default time period for dashboard and analytics',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            Column(
              children: dateRangeOptions.map((option) {
                final (value, title, subtitle) = option;
                return RadioListTile<String>(
                  value: value,
                  groupValue: _currentSettings?.dashboard.dateRange ?? '30d',
                  onChanged: (newRange) {
                    if (newRange != null) {
                      final newDashboard = _currentSettings!.dashboard.copyWith(
                        dateRange: newRange,
                      );
                      _updateSettings(_currentSettings!.copyWith(dashboard: newDashboard));
                    }
                  },
                  title: Text(title),
                  subtitle: Text(subtitle),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusTabsSection(BuildContext context) {
    final availableStatuses = [
      ('new', 'New', 'Newly created enquiries'),
      ('in_talks', 'In Talks', 'Currently being discussed with customer'),
      ('quote_sent', 'Quote Sent', 'Quotes sent to customers'),
      ('approved', 'Approved', 'Approved by customers'),
      ('completed', 'Completed', 'Successfully completed'),
      ('cancelled', 'Cancelled', 'Cancelled enquiries'),
      ('closed_lost', 'Closed Lost', 'Lost opportunities'),
    ];

    final currentTabs =
        _currentSettings?.dashboard.statusTabs ?? ['new', 'in_talks', 'quote_sent'];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Default Status Tabs', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              'Which status tabs to show by default on the dashboard',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            Column(
              children: availableStatuses.map((status) {
                final (value, title, subtitle) = status;
                final isSelected = currentTabs.contains(value);

                return CheckboxListTile(
                  value: isSelected,
                  onChanged: (checked) {
                    List<String> newTabs = List.from(currentTabs);
                    if (checked == true) {
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
                  title: Text(title),
                  subtitle: Text(subtitle),
                );
              }).toList(),
            ),
          ],
        ),
      ),
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

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Table Columns', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              'Configure which columns to show in enquiry lists',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            Column(
              children: availableColumns.map((column) {
                final (id, title, subtitle) = column;
                final existingColumn = currentColumns.firstWhere(
                  (col) => col.id == id,
                  orElse: () => ColumnSettings(id: id, visible: false, order: 0),
                );

                return CheckboxListTile(
                  value: existingColumn.visible,
                  onChanged: (checked) {
                    final List<ColumnSettings> newColumns = List.from(currentColumns);

                    // Remove existing column with same id
                    newColumns.removeWhere((col) => col.id == id);

                    if (checked == true) {
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
                  title: Text(title),
                  subtitle: Text(subtitle),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveSection(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _isSaving ? null : _saveChanges,
              icon: _isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save),
              label: Text(_isSaving ? 'Saving...' : 'Save Changes'),
            ),
          ),
          const SizedBox(width: 16),
          TextButton(onPressed: _isSaving ? null : _discardChanges, child: const Text('Discard')),
        ],
      ),
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
        backgroundColor: isError ? Colors.red : Colors.green,
        action: SnackBarAction(label: 'OK', textColor: Colors.white, onPressed: () {}),
      ),
    );
  }
}
