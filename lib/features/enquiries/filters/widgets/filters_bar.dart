import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/auth/current_user_role_provider.dart';
import '../../../../core/theme/tokens.dart';
import '../filters_controller.dart';
import '../filters_state.dart';

/// A horizontal bar showing active filters with options to clear them
class FiltersBar extends ConsumerWidget {
  const FiltersBar({super.key, this.onClearFilters, this.onShowFilters});

  final VoidCallback? onClearFilters;
  final VoidCallback? onShowFilters;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filters = ref.watch(enquiryFiltersProvider);
    final theme = Theme.of(context);

    if (!filters.hasActiveFilters) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: AppSpacing.horizontal4,
      height: 48,
      child: Row(
        children: [
          // Active filters count
          Container(
            padding: EdgeInsets.symmetric(horizontal: AppTokens.space3, vertical: AppTokens.space1),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: AppRadius.medium,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.filter_list,
                  size: AppTokens.iconSmall,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
                const SizedBox(width: AppTokens.space2),
                Text(
                  '${filters.activeFilterCount} filter${filters.activeFilterCount == 1 ? '' : 's'}',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: AppTokens.space2),

          // Filter chips
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  // Status filters
                  if (filters.statuses.isNotEmpty) ...[
                    ...filters.statuses.map(
                      (status) => _FilterChip(
                        label: 'Status: $status',
                        onDeleted: () =>
                            ref.read(enquiryFiltersProvider.notifier).toggleStatusFilter(status),
                      ),
                    ),
                  ],

                  // Event type filters
                  if (filters.eventTypes.isNotEmpty) ...[
                    ...filters.eventTypes.map(
                      (eventType) => _FilterChip(
                        label: 'Type: $eventType',
                        onDeleted: () => ref
                            .read(enquiryFiltersProvider.notifier)
                            .toggleEventTypeFilter(eventType),
                      ),
                    ),
                  ],

                  // Assignee filter
                  if (filters.assigneeId != null) ...[
                    _FilterChip(
                      label: 'Assignee: ${filters.assigneeId}',
                      onDeleted: () =>
                          ref.read(enquiryFiltersProvider.notifier).updateAssigneeFilter(null),
                    ),
                  ],

                  // Date range filter
                  if (filters.dateRange != null) ...[
                    _FilterChip(
                      label:
                          'Date: ${_formatDateRange(_convertToFlutterDateRange(filters.dateRange!))}',
                      onDeleted: () =>
                          ref.read(enquiryFiltersProvider.notifier).updateDateRangeFilter(null),
                    ),
                  ],

                  // Search query filter
                  if (filters.searchQuery?.isNotEmpty ?? false) ...[
                    _FilterChip(
                      label: 'Search: "${filters.searchQuery}"',
                      onDeleted: () =>
                          ref.read(enquiryFiltersProvider.notifier).updateSearchQuery(null),
                    ),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(width: AppTokens.space2),

          // Clear all button
          IconButton(
            onPressed: () {
              ref.read(enquiryFiltersProvider.notifier).clearFilters();
              onClearFilters?.call();
            },
            icon: const Icon(Icons.clear_all),
            tooltip: 'Clear all filters',
          ),
        ],
      ),
    );
  }

  /// Convert FilterDateRange to Flutter's DateTimeRange
  DateTimeRange _convertToFlutterDateRange(FilterDateRange range) {
    return DateTimeRange(start: range.start, end: range.end);
  }

  String _formatDateRange(DateTimeRange range) {
    final start = range.start;
    final end = range.end;

    if (start.year == end.year && start.month == end.month) {
      return '${start.day}-${end.day}/${start.month}/${start.year}';
    } else if (start.year == end.year) {
      return '${start.day}/${start.month} - ${end.day}/${end.month}/${start.year}';
    } else {
      return '${start.day}/${start.month}/${start.year} - ${end.day}/${end.month}/${end.year}';
    }
  }
}

/// Individual filter chip widget
class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, required this.onDeleted});

  final String label;
  final VoidCallback onDeleted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(right: AppTokens.space2),
      child: Chip(
        label: Text(label, style: theme.textTheme.labelSmall),
        deleteIcon: Icon(Icons.close, size: AppTokens.iconSmall),
        onDeleted: onDeleted,
        backgroundColor: theme.colorScheme.surfaceContainerHighest,
        deleteIconColor: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }
}

/// Filter summary widget showing active filter descriptions
class FilterSummary extends ConsumerWidget {
  const FilterSummary({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filters = ref.watch(enquiryFiltersProvider);
    final theme = Theme.of(context);

    if (!filters.hasActiveFilters) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: AppSpacing.space4,
      margin: AppSpacing.horizontal4,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: AppRadius.medium,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.filter_list, size: AppTokens.iconMedium, color: theme.colorScheme.primary),
              const SizedBox(width: AppTokens.space2),
              Text(
                'Active Filters',
                style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.primary),
              ),
              const Spacer(),
              TextButton(
                onPressed: () {
                  ref.read(enquiryFiltersProvider.notifier).clearFilters();
                },
                child: const Text('Clear All'),
              ),
            ],
          ),
          const SizedBox(height: AppTokens.space2),
          ...filters.activeFilterDescriptions.map(
            (description) => Padding(
              padding: const EdgeInsets.only(bottom: AppTokens.space1),
              child: Text(
                '• $description',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Quick filter buttons for common filter combinations
class QuickFilters extends ConsumerWidget {
  const QuickFilters({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final filters = ref.watch(enquiryFiltersProvider);

    return Container(
      padding: AppSpacing.space4,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Quick Filters', style: theme.textTheme.labelLarge),
          const SizedBox(height: AppTokens.space3),
          Wrap(
            spacing: AppTokens.space2,
            runSpacing: AppTokens.space2,
            children: [
              _QuickFilterButton(
                label: 'Today',
                isActive: _isTodayFilterActive(filters),
                onTap: () => _applyTodayFilter(ref),
              ),
              _QuickFilterButton(
                label: 'This Week',
                isActive: _isThisWeekFilterActive(filters),
                onTap: () => _applyThisWeekFilter(ref),
              ),
              _QuickFilterButton(
                label: 'Pending',
                isActive: filters.statuses.contains('pending'),
                onTap: () =>
                    ref.read(enquiryFiltersProvider.notifier).toggleStatusFilter('pending'),
              ),
              _QuickFilterButton(
                label: 'Assigned to Me',
                isActive: filters.assigneeId != null,
                onTap: () => _toggleAssignedToMeFilter(ref),
              ),
            ],
          ),
        ],
      ),
    );
  }

  bool _isTodayFilterActive(EnquiryFilters filters) {
    if (filters.dateRange == null) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    return filters.dateRange!.start.isAtSameMomentAs(today) &&
        filters.dateRange!.end.isAtSameMomentAs(tomorrow);
  }

  bool _isThisWeekFilterActive(EnquiryFilters filters) {
    if (filters.dateRange == null) return false;
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final startOfWeekDay = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
    final endOfWeek = startOfWeekDay.add(const Duration(days: 7));

    return filters.dateRange!.start.isAtSameMomentAs(startOfWeekDay) &&
        filters.dateRange!.end.isAtSameMomentAs(endOfWeek);
  }

  void _applyTodayFilter(WidgetRef ref) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    ref
        .read(enquiryFiltersProvider.notifier)
        .updateDateRangeFilter(FilterDateRange(start: today, end: tomorrow));
  }

  void _applyThisWeekFilter(WidgetRef ref) {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final startOfWeekDay = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
    final endOfWeek = startOfWeekDay.add(const Duration(days: 7));

    ref
        .read(enquiryFiltersProvider.notifier)
        .updateDateRangeFilter(FilterDateRange(start: startOfWeekDay, end: endOfWeek));
  }

  void _toggleAssignedToMeFilter(WidgetRef ref) {
    final currentFilters = ref.read(enquiryFiltersProvider);
    if (currentFilters.assigneeId != null) {
      ref.read(enquiryFiltersProvider.notifier).updateAssigneeFilter(null);
    } else {
      final currentUserAsync = ref.read(currentUserAsyncProvider);
      final currentUser = currentUserAsync.valueOrNull;
      if (currentUser != null) {
        ref.read(enquiryFiltersProvider.notifier).updateAssigneeFilter(currentUser.uid);
      }
    }
  }
}

/// Individual quick filter button
class _QuickFilterButton extends StatelessWidget {
  const _QuickFilterButton({required this.label, required this.isActive, required this.onTap});

  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return FilterChip(
      label: Text(label),
      selected: isActive,
      onSelected: (_) => onTap(),
      selectedColor: theme.colorScheme.primaryContainer,
      checkmarkColor: theme.colorScheme.onPrimaryContainer,
      backgroundColor: theme.colorScheme.surfaceContainerHighest,
    );
  }
}
