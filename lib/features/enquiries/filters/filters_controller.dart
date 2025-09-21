import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/logging/logger.dart';
import '../../data/enquiry_repository.dart';
import '../../domain/enquiry.dart';
import 'filters_state.dart';

/// Provider for the current enquiry filters
final enquiryFiltersProvider = StateNotifierProvider<EnquiryFiltersController, EnquiryFilters>((ref) {
  return EnquiryFiltersController(ref);
});

/// Provider for filtered enquiries
final filteredEnquiriesProvider = FutureProvider<List<Enquiry>>((ref) {
  final filters = ref.watch(enquiryFiltersProvider);
  final repository = ref.watch(enquiryRepositoryProvider);
  
  return repository.getFilteredEnquiries(filters);
});

/// Provider for enquiry filters with local filtering
final locallyFilteredEnquiriesProvider = Provider<List<Enquiry>>((ref) {
  final allEnquiriesAsync = ref.watch(enquiryRepositoryProvider).getEnquiries();
  final filters = ref.watch(enquiryFiltersProvider);
  
  return allEnquiriesAsync.when(
    data: (enquiries) => _applyLocalFilters(enquiries, filters),
    loading: () => [],
    error: (_, __) => [],
  );
});

/// Controller for managing enquiry filters and applying them
class EnquiryFiltersController extends StateNotifier<EnquiryFilters> {
  EnquiryFiltersController(this.ref) : super(const EnquiryFilters());

  final Ref ref;

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
  void updateDateRangeFilter(DateTimeRange? dateRange) {
    state = state.copyWith(dateRange: dateRange);
    Logger.info('Updated date range filter: $dateRange', tag: 'Filters');
  }

  /// Update search query
  void updateSearchQuery(String? query) {
    state = state.copyWith(searchQuery: query);
    Logger.info('Updated search query: $query', tag: 'Filters');
  }

  /// Update sorting
  void updateSorting(EnquirySortBy sortBy, SortOrder sortOrder) {
    state = state.copyWith(sortBy: sortBy, sortOrder: sortOrder);
    Logger.info('Updated sorting: $sortBy $sortOrder', tag: 'Filters');
  }

  /// Clear all filters
  void clearFilters() {
    state = state.clearFilters();
    Logger.info('Cleared all filters', tag: 'Filters');
  }

  /// Reset sorting to default
  void resetSorting() {
    state = state.resetSorting();
    Logger.info('Reset sorting to default', tag: 'Filters');
  }

  /// Apply saved filters
  void applyFilters(EnquiryFilters filters) {
    state = filters;
    Logger.info('Applied saved filters: ${filters.activeFilterDescriptions}', tag: 'Filters');
  }

  /// Toggle status filter
  void toggleStatusFilter(String status) {
    final currentStatuses = List<String>.from(state.statuses);
    if (currentStatuses.contains(status)) {
      currentStatuses.remove(status);
    } else {
      currentStatuses.add(status);
    }
    updateStatusFilters(currentStatuses);
  }

  /// Toggle event type filter
  void toggleEventTypeFilter(String eventType) {
    final currentEventTypes = List<String>.from(state.eventTypes);
    if (currentEventTypes.contains(eventType)) {
      currentEventTypes.remove(eventType);
    } else {
      currentEventTypes.add(eventType);
    }
    updateEventTypeFilters(currentEventTypes);
  }

  /// Build Firestore query based on current filters
  Query<Map<String, dynamic>> buildQuery(CollectionReference<Map<String, dynamic>> collection) {
    Query<Map<String, dynamic>> query = collection;

    // Apply status filters
    if (state.statuses.isNotEmpty) {
      query = query.where('status', whereIn: state.statuses);
    }

    // Apply event type filters
    if (state.eventTypes.isNotEmpty) {
      query = query.where('eventType', whereIn: state.eventTypes);
    }

    // Apply assignee filter
    if (state.assigneeId != null) {
      query = query.where('assignedTo', isEqualTo: state.assigneeId);
    }

    // Apply date range filter
    if (state.dateRange != null) {
      query = query
          .where('eventDate', isGreaterThanOrEqualTo: state.dateRange!.start)
          .where('eventDate', isLessThanOrEqualTo: state.dateRange!.end);
    }

    // Apply search query (if supported by Firestore)
    if (state.searchQuery?.isNotEmpty ?? false) {
      // Note: Firestore doesn't support full-text search natively
      // This would need to be handled client-side or with a search service
      Logger.warning('Search query not applied to Firestore query (client-side filtering)', tag: 'Filters');
    }

    // Apply sorting
    final orderByField = state.sortBy.field;
    final descending = state.sortOrder == SortOrder.descending;
    
    if (orderByField == 'createdAt' || orderByField == 'updatedAt') {
      query = query.orderBy(orderByField, descending: descending);
    } else {
      // For non-timestamp fields, we need to order by createdAt first for Firestore
      query = query.orderBy(orderByField, descending: descending);
      if (orderByField != 'createdAt') {
        query = query.orderBy('createdAt', descending: true);
      }
    }

    return query;
  }
}

/// Apply local filters to a list of enquiries
List<Enquiry> _applyLocalFilters(List<Enquiry> enquiries, EnquiryFilters filters) {
  var filteredEnquiries = List<Enquiry>.from(enquiries);

  // Apply status filters
  if (filters.statuses.isNotEmpty) {
    filteredEnquiries = filteredEnquiries
        .where((enquiry) => filters.statuses.contains(enquiry.status))
        .toList();
  }

  // Apply event type filters
  if (filters.eventTypes.isNotEmpty) {
    filteredEnquiries = filteredEnquiries
        .where((enquiry) => filters.eventTypes.contains(enquiry.eventType))
        .toList();
  }

  // Apply assignee filter
  if (filters.assigneeId != null) {
    filteredEnquiries = filteredEnquiries
        .where((enquiry) => enquiry.assignedTo == filters.assigneeId)
        .toList();
  }

  // Apply date range filter
  if (filters.dateRange != null) {
    filteredEnquiries = filteredEnquiries
        .where((enquiry) {
          if (enquiry.eventDate == null) return false;
          final eventDate = enquiry.eventDate!;
          return eventDate.isAfter(filters.dateRange!.start) &&
                 eventDate.isBefore(filters.dateRange!.end);
        })
        .toList();
  }

  // Apply search query
  if (filters.searchQuery?.isNotEmpty ?? false) {
    final query = filters.searchQuery!.toLowerCase();
    filteredEnquiries = filteredEnquiries
        .where((enquiry) {
          return enquiry.customerName.toLowerCase().contains(query) ||
                 enquiry.customerEmail.toLowerCase().contains(query) ||
                 enquiry.customerPhone.toLowerCase().contains(query) ||
                 enquiry.eventType.toLowerCase().contains(query) ||
                 enquiry.notes.toLowerCase().contains(query);
        })
        .toList();
  }

  // Apply sorting
  filteredEnquiries.sort((a, b) {
    int comparison = 0;
    
    switch (filters.sortBy) {
      case EnquirySortBy.createdAt:
        comparison = a.createdAt.compareTo(b.createdAt);
        break;
      case EnquirySortBy.updatedAt:
        comparison = a.updatedAt.compareTo(b.updatedAt);
        break;
      case EnquirySortBy.eventDate:
        final aDate = a.eventDate ?? DateTime(1970);
        final bDate = b.eventDate ?? DateTime(1970);
        comparison = aDate.compareTo(bDate);
        break;
      case EnquirySortBy.customerName:
        comparison = a.customerName.compareTo(b.customerName);
        break;
      case EnquirySortBy.eventType:
        comparison = a.eventType.compareTo(b.eventType);
        break;
      case EnquirySortBy.status:
        comparison = a.status.compareTo(b.status);
        break;
      case EnquirySortBy.priority:
        comparison = a.priority.index.compareTo(b.priority.index);
        break;
    }

    return filters.sortOrder == SortOrder.ascending ? comparison : -comparison;
  });

  return filteredEnquiries;
}

/// Provider for available filter options
final filterOptionsProvider = FutureProvider<FilterOptions>((ref) async {
  final repository = ref.watch(enquiryRepositoryProvider);
  final enquiries = await repository.getEnquiries();
  
  return FilterOptions.fromEnquiries(enquiries);
});

/// Available filter options extracted from enquiries
class FilterOptions {
  const FilterOptions({
    required this.availableStatuses,
    required this.availableEventTypes,
    required this.availableAssignees,
    required this.dateRange,
  });

  final List<String> availableStatuses;
  final List<String> availableEventTypes;
  final List<String> availableAssignees;
  final DateTimeRange dateRange;

  factory FilterOptions.fromEnquiries(List<Enquiry> enquiries) {
    final statuses = enquiries.map((e) => e.status).toSet().toList()..sort();
    final eventTypes = enquiries.map((e) => e.eventType).toSet().toList()..sort();
    final assignees = enquiries
        .map((e) => e.assignedTo)
        .where((assignee) => assignee != null && assignee.isNotEmpty)
        .toSet()
        .toList()
      ..sort();

    DateTime? earliestDate;
    DateTime? latestDate;
    
    for (final enquiry in enquiries) {
      if (enquiry.eventDate != null) {
        if (earliestDate == null || enquiry.eventDate!.isBefore(earliestDate)) {
          earliestDate = enquiry.eventDate;
        }
        if (latestDate == null || enquiry.eventDate!.isAfter(latestDate)) {
          latestDate = enquiry.eventDate;
        }
      }
    }

    final dateRange = DateTimeRange(
      start: earliestDate ?? DateTime.now().subtract(const Duration(days: 365)),
      end: latestDate ?? DateTime.now().add(const Duration(days: 365)),
    );

    return FilterOptions(
      availableStatuses: statuses,
      availableEventTypes: eventTypes,
      availableAssignees: assignees,
      dateRange: dateRange,
    );
  }
}
