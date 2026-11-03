import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/auth/current_user_role_provider.dart';
import '../date_range_presets.dart';
import '../filters_controller.dart';
import '../filters_state.dart';

/// A one-tap filter preset shared by the filters bar and the filters sheet.
class QuickFilterOption {
  const QuickFilterOption({
    required this.label,
    required this.icon,
    required this.isActive,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;
}

List<QuickFilterOption> quickFilterOptions(WidgetRef ref, EnquiryFilters filters) {
  final notifier = ref.read(enquiryFiltersProvider.notifier);
  return [
    QuickFilterOption(
      label: 'Today',
      icon: Icons.today_outlined,
      isActive: isTodayRange(filters.dateRange),
      onTap: () => notifier.updateDateRangeFilter(_todayRange()),
    ),
    QuickFilterOption(
      label: 'This Week',
      icon: Icons.date_range_outlined,
      isActive: isThisWeekRange(filters.dateRange),
      onTap: () => notifier.updateDateRangeFilter(_thisWeekRange()),
    ),
    QuickFilterOption(
      label: 'New',
      icon: Icons.fiber_new_outlined,
      isActive: filters.statuses.contains('new'),
      onTap: () => notifier.toggleStatusFilter('new'),
    ),
    QuickFilterOption(
      label: 'Assigned to Me',
      icon: Icons.person_outline_rounded,
      isActive: filters.assigneeId != null,
      onTap: () => _toggleAssignedToMe(ref),
    ),
  ];
}

bool isTodayRange(FilterDateRange? range) => DateRangePreset.keyFor(range) == DateRangePreset.today;

bool isThisWeekRange(FilterDateRange? range) =>
    DateRangePreset.keyFor(range) == DateRangePreset.thisWeek;

FilterDateRange _todayRange() => DateRangePreset.todayRange();

FilterDateRange _thisWeekRange() => DateRangePreset.thisWeekRange();

void _toggleAssignedToMe(WidgetRef ref) {
  final currentFilters = ref.read(enquiryFiltersProvider);
  if (currentFilters.assigneeId != null) {
    ref.read(enquiryFiltersProvider.notifier).updateAssigneeFilter(null);
  } else {
    final uid = ref.read(currentUserUidProvider);
    if (uid != null) {
      ref.read(enquiryFiltersProvider.notifier).updateAssigneeFilter(uid);
    }
  }
}
