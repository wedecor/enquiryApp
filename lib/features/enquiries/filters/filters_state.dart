import 'package:freezed_annotation/freezed_annotation.dart';

part 'filters_state.freezed.dart';
part 'filters_state.g.dart';

/// State for enquiry filtering with faceted search capabilities
@freezed
class EnquiryFilters with _$EnquiryFilters {
  const factory EnquiryFilters({
    @Default([]) List<String> statuses,
    @Default([]) List<String> eventTypes,
    String? assigneeId,
    FilterDateRange? dateRange,
    String? searchQuery,
    @Default(EnquirySortBy.createdAt) EnquirySortBy sortBy,
    @Default(SortOrder.descending) SortOrder sortOrder,
  }) = _EnquiryFilters;

  factory EnquiryFilters.fromJson(Map<String, dynamic> json) => _$EnquiryFiltersFromJson(json);
}

/// Date range for filtering enquiries
@freezed
class FilterDateRange with _$FilterDateRange {
  const factory FilterDateRange({required DateTime start, required DateTime end}) =
      _FilterDateRange;

  factory FilterDateRange.fromJson(Map<String, dynamic> json) => _$FilterDateRangeFromJson(json);
}

/// Sort options for enquiries
enum EnquirySortBy {
  createdAt('createdAt', 'Created Date'),
  updatedAt('updatedAt', 'Updated Date'),
  eventDate('eventDate', 'Event Date'),
  customerName('customerName', 'Customer Name'),
  eventType('eventType', 'Event Type'),
  status('status', 'Status'),
  priority('priority', 'Priority');

  const EnquirySortBy(this.field, this.displayName);
  final String field;
  final String displayName;
}

/// Sort order options
enum SortOrder {
  ascending('asc', 'Ascending'),
  descending('desc', 'Descending');

  const SortOrder(this.value, this.displayName);
  final String value;
  final String displayName;
}

/// Saved view for enquiry filters
@freezed
class SavedView with _$SavedView {
  const factory SavedView({
    required String id,
    required String name,
    required EnquiryFilters filters,
    @Default(false) bool isDefault,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _SavedView;

  factory SavedView.fromJson(Map<String, dynamic> json) => _$SavedViewFromJson(json);
}

/// State for saved views management
@freezed
class SavedViewsState with _$SavedViewsState {
  const factory SavedViewsState({
    @Default([]) List<SavedView> views,
    @Default(false) bool isLoading,
    String? error,
  }) = _SavedViewsState;
}

/// Extension methods for EnquiryFilters
extension EnquiryFiltersExtension on EnquiryFilters {
  /// Check if any filters are applied
  bool get hasActiveFilters {
    return statuses.isNotEmpty ||
        eventTypes.isNotEmpty ||
        assigneeId != null ||
        dateRange != null ||
        (searchQuery?.isNotEmpty ?? false);
  }

  /// Get count of active filters
  int get activeFilterCount {
    int count = 0;
    if (statuses.isNotEmpty) count++;
    if (eventTypes.isNotEmpty) count++;
    if (assigneeId != null) count++;
    if (dateRange != null) count++;
    if (searchQuery?.isNotEmpty ?? false) count++;
    return count;
  }

  /// Create a copy with cleared filters
  EnquiryFilters clearFilters() {
    return copyWith(
      statuses: const [],
      eventTypes: const [],
      assigneeId: null,
      dateRange: null,
      searchQuery: null,
    );
  }

  /// Create a copy with reset to default sorting
  EnquiryFilters resetSorting() {
    return copyWith(sortBy: EnquirySortBy.createdAt, sortOrder: SortOrder.descending);
  }

  /// Get display text for active filters
  List<String> get activeFilterDescriptions {
    final descriptions = <String>[];

    if (statuses.isNotEmpty) {
      descriptions.add('Status: ${statuses.join(', ')}');
    }

    if (eventTypes.isNotEmpty) {
      descriptions.add('Event Type: ${eventTypes.join(', ')}');
    }

    if (assigneeId != null) {
      descriptions.add('Assignee: $assigneeId');
    }

    if (dateRange != null) {
      final start = dateRange!.start;
      final end = dateRange!.end;
      descriptions.add(
        'Date: ${start.day}/${start.month}/${start.year} - ${end.day}/${end.month}/${end.year}',
      );
    }

    if (searchQuery?.isNotEmpty ?? false) {
      descriptions.add('Search: "$searchQuery"');
    }

    return descriptions;
  }
}

/// Extension methods for SavedView
extension SavedViewExtension on SavedView {
  /// Create a copy with updated timestamp
  SavedView touch() {
    return copyWith(updatedAt: DateTime.now());
  }

  /// Create a copy with toggled default status
  SavedView toggleDefault() {
    return copyWith(isDefault: !isDefault);
  }

  /// Get display name with default indicator
  String get displayName {
    return isDefault ? '$name (Default)' : name;
  }
}

/// Extension methods for SavedViewsState
extension SavedViewsStateExtension on SavedViewsState {
  /// Get default view if exists
  SavedView? get defaultView {
    try {
      return views.firstWhere((view) => view.isDefault);
    } catch (e) {
      return null;
    }
  }

  /// Get non-default views
  List<SavedView> get nonDefaultViews {
    return views.where((view) => !view.isDefault).toList();
  }

  /// Check if view with given name exists
  bool hasViewWithName(String name) {
    return views.any((view) => view.name.toLowerCase() == name.toLowerCase());
  }

  /// Get view by ID
  SavedView? getViewById(String id) {
    try {
      return views.firstWhere((view) => view.id == id);
    } catch (e) {
      return null;
    }
  }
}
