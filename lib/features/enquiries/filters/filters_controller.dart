import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/logging/logger.dart';
import 'filters_state.dart';

/// Provider for the current enquiry filters
final enquiryFiltersProvider = StateNotifierProvider<EnquiryFiltersController, EnquiryFilters>((
  ref,
) {
  return EnquiryFiltersController();
});

/// Simplified controller for managing enquiry filters
/// This is a placeholder implementation for the advanced filtering feature
class EnquiryFiltersController extends StateNotifier<EnquiryFilters> {
  EnquiryFiltersController() : super(const EnquiryFilters());

  /// Update status filters
  void updateStatusFilters(List<String> statuses) {
    state = state.copyWith(statuses: statuses);
    Logger.info('Updated status filters: $statuses', tag: 'Filters');
  }

  /// Update event type filters
  void updateEventTypeFilters(List<String> eventTypes) {
    state = state.copyWith(eventTypes: eventTypes);
    Logger.info('Updated event type filters: $eventTypes', tag: 'Filters');
  }

  /// Update assignee filter
  void updateAssigneeFilter(String? assigneeId) {
    state = state.copyWith(assigneeId: assigneeId);
    Logger.info('Updated assignee filter: $assigneeId', tag: 'Filters');
  }

  /// Update date range filter
  void updateDateRangeFilter(FilterDateRange? dateRange) {
    state = state.copyWith(dateRange: dateRange);
    Logger.info('Updated date range filter', tag: 'Filters');
  }

  /// Update search query
  void updateSearchQuery(String? query) {
    state = state.copyWith(searchQuery: query);
    Logger.info('Updated search query', tag: 'Filters');
  }

  /// Update sort options
  void updateSort(EnquirySortBy sortBy, SortOrder sortOrder) {
    state = state.copyWith(sortBy: sortBy, sortOrder: sortOrder);
    Logger.info('Updated sort: ${sortBy.field} ${sortOrder.name}', tag: 'Filters');
  }

  /// Clear all filters
  void clearFilters() {
    state = const EnquiryFilters();
    Logger.info('Cleared all filters', tag: 'Filters');
  }

  /// Toggle a status filter
  void toggleStatusFilter(String status) {
    final currentStatuses = List<String>.from(state.statuses);
    if (currentStatuses.contains(status)) {
      currentStatuses.remove(status);
    } else {
      currentStatuses.add(status);
    }
    updateStatusFilters(currentStatuses);
  }

  /// Toggle an event type filter
  void toggleEventTypeFilter(String eventType) {
    final currentTypes = List<String>.from(state.eventTypes);
    if (currentTypes.contains(eventType)) {
      currentTypes.remove(eventType);
    } else {
      currentTypes.add(eventType);
    }
    updateEventTypeFilters(currentTypes);
  }

  /// Apply filters (placeholder for complex filtering logic)
  void applyFilters(EnquiryFilters filters) {
    state = filters;
    Logger.info('Applied filters', tag: 'Filters');
  }

  /// Check if any filters are active
  bool get hasActiveFilters {
    return state.statuses.isNotEmpty ||
        state.eventTypes.isNotEmpty ||
        state.assigneeId != null ||
        state.dateRange != null ||
        (state.searchQuery?.isNotEmpty ?? false);
  }
}
