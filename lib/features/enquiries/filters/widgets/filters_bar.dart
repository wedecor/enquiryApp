import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/auth/current_user_role_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../ui/primitives/primitives.dart';
import '../filters_controller.dart';
import '../filters_state.dart';
import 'filter_pill.dart';
import 'quick_filter_options.dart';

/// Horizontally scrolling glass pills: the quick presets (animated selected
/// state), then any other active filters as removable pills, then "Clear".
/// The search query is shown by the search field, not here.
class FiltersBar extends ConsumerWidget {
  const FiltersBar({super.key, this.onClearFilters, this.onShowFilters});

  final VoidCallback? onClearFilters;

  /// When set, a leading "Filters" pill opens the full filter sheet.
  final VoidCallback? onShowFilters;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filters = ref.watch(enquiryFiltersProvider);
    final uid = ref.watch(currentUserUidProvider);
    final notifier = ref.read(enquiryFiltersProvider.notifier);

    final pills = <Widget>[
      if (onShowFilters != null)
        FilterPill(
          key: const ValueKey('pill-filters'),
          label: filters.activeFilterCount > 0
              ? 'Filters · ${filters.activeFilterCount}'
              : 'Filters',
          icon: Icons.tune_rounded,
          onTap: onShowFilters,
        ),
      for (final option in quickFilterOptions(ref, filters))
        FilterPill(
          key: ValueKey('pill-${option.label}'),
          label: option.label,
          selected: option.isActive,
          onTap: option.onTap,
        ),
      for (final status in filters.statuses.where((s) => s != 'new'))
        FilterPill(
          key: ValueKey('pill-status-$status'),
          label: 'Status: ${_pretty(status)}',
          onDeleted: () => notifier.toggleStatusFilter(status),
        ),
      for (final eventType in filters.eventTypes)
        FilterPill(
          key: ValueKey('pill-type-$eventType'),
          label: 'Type: ${_pretty(eventType)}',
          onDeleted: () => notifier.toggleEventTypeFilter(eventType),
        ),
      if (filters.assigneeId != null && filters.assigneeId != uid)
        FilterPill(
          key: const ValueKey('pill-assignee'),
          label: 'Assignee: ${filters.assigneeId}',
          onDeleted: () => notifier.updateAssigneeFilter(null),
        ),
      if (filters.dateRange != null &&
          !isTodayRange(filters.dateRange) &&
          !isThisWeekRange(filters.dateRange))
        FilterPill(
          key: const ValueKey('pill-date'),
          label: 'Date: ${_formatDateRange(filters.dateRange!)}',
          onDeleted: () => notifier.updateDateRangeFilter(null),
        ),
      if (filters.hasActiveFilters)
        FilterPill(
          key: const ValueKey('pill-clear'),
          label: 'Clear',
          icon: Icons.clear_all_rounded,
          tooltip: 'Clear all filters',
          onTap: () {
            notifier.clearFilters();
            onClearFilters?.call();
          },
        ),
    ];

    return SizedBox(
      height: 52,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppTokens.space4),
        itemCount: pills.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppTokens.space2),
        itemBuilder: (context, i) => StaggerIn(index: i, offsetY: 0.2, child: pills[i]),
      ),
    );
  }

  static String _pretty(String value) => value
      .replaceAll('_', ' ')
      .split(' ')
      .where((w) => w.isNotEmpty)
      .map((w) => '${w[0].toUpperCase()}${w.substring(1)}')
      .join(' ');

  String _formatDateRange(FilterDateRange range) {
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

/// Filter summary widget showing active filter descriptions
class FilterSummary extends ConsumerWidget {
  const FilterSummary({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filters = ref.watch(enquiryFiltersProvider);
    final theme = Theme.of(context);
    final s = AppSurfaces.of(context);

    return AnimatedSize(
      duration: AppMotion.of(context, AppMotion.standard),
      curve: AppMotion.standardCurve,
      alignment: Alignment.topCenter,
      child: !filters.hasActiveFilters
          ? const SizedBox(width: double.infinity)
          : GlassPanel(
              borderRadius: AppRadius.large,
              padding: const EdgeInsets.fromLTRB(
                AppTokens.space4,
                AppTokens.space2,
                AppTokens.space2,
                AppTokens.space4,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(child: Eyebrow('Active filters', accent: true)),
                      TextButton(
                        onPressed: () => ref.read(enquiryFiltersProvider.notifier).clearFilters(),
                        child: const Text('Clear All'),
                      ),
                    ],
                  ),
                  for (final description in filters.activeFilterDescriptions)
                    Padding(
                      padding: const EdgeInsets.only(top: AppTokens.space1),
                      child: Row(
                        children: [
                          StatusDot(color: s.accent, size: 5),
                          const SizedBox(width: AppTokens.space2),
                          Expanded(
                            child: Text(
                              description,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface,
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
}

/// Quick filter presets as wrapping glass pills (used in the filters sheet).
class QuickFilters extends ConsumerWidget {
  const QuickFilters({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filters = ref.watch(enquiryFiltersProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTokens.space3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Eyebrow('Quick filters'),
          const SizedBox(height: AppTokens.space2),
          Wrap(
            spacing: AppTokens.space2,
            children: [
              for (final option in quickFilterOptions(ref, filters))
                FilterPill(
                  label: option.label,
                  icon: option.icon,
                  selected: option.isActive,
                  onTap: option.onTap,
                ),
            ],
          ),
        ],
      ),
    );
  }
}
