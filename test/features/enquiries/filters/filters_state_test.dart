import 'package:flutter_test/flutter_test.dart';
import 'package:we_decor_enquiries/features/enquiries/filters/filters_state.dart';

void main() {
  group('EnquiryFilters', () {
    test('creates with default values', () {
      const filters = EnquiryFilters();
      expect(filters.statuses, isEmpty);
      expect(filters.eventTypes, isEmpty);
      expect(filters.assigneeId, isNull);
      expect(filters.dateRange, isNull);
      expect(filters.searchQuery, isNull);
    });

    test('creates with custom values', () {
      const filters = EnquiryFilters(
        statuses: ['new', 'contacted'],
        eventTypes: ['wedding'],
        assigneeId: 'user123',
        searchQuery: 'test',
      );
      expect(filters.statuses, ['new', 'contacted']);
      expect(filters.eventTypes, ['wedding']);
      expect(filters.assigneeId, 'user123');
      expect(filters.searchQuery, 'test');
    });
  });

  group('EnquiryFiltersExtension', () {
    group('hasActiveFilters', () {
      test('returns false for empty filters', () {
        const filters = EnquiryFilters();
        expect(filters.hasActiveFilters, isFalse);
      });

      test('returns true when statuses are set', () {
        const filters = EnquiryFilters(statuses: ['new']);
        expect(filters.hasActiveFilters, isTrue);
      });

      test('returns true when eventTypes are set', () {
        const filters = EnquiryFilters(eventTypes: ['wedding']);
        expect(filters.hasActiveFilters, isTrue);
      });

      test('returns true when assigneeId is set', () {
        const filters = EnquiryFilters(assigneeId: 'user123');
        expect(filters.hasActiveFilters, isTrue);
      });

      test('returns true when dateRange is set', () {
        final filters = EnquiryFilters(
          dateRange: FilterDateRange(start: DateTime.now(), end: DateTime.now()),
        );
        expect(filters.hasActiveFilters, isTrue);
      });

      test('returns true when searchQuery is set', () {
        const filters = EnquiryFilters(searchQuery: 'test');
        expect(filters.hasActiveFilters, isTrue);
      });
    });

    group('activeFilterCount', () {
      test('returns 0 for empty filters', () {
        const filters = EnquiryFilters();
        expect(filters.activeFilterCount, 0);
      });

      test('returns correct count for multiple filters', () {
        const filters = EnquiryFilters(
          statuses: ['new'],
          eventTypes: ['wedding'],
          assigneeId: 'user123',
          searchQuery: 'test',
        );
        expect(filters.activeFilterCount, 4);
      });
    });

    group('clearFilters', () {
      test('clears all filters', () {
        const filters = EnquiryFilters(
          statuses: ['new'],
          eventTypes: ['wedding'],
          assigneeId: 'user123',
          searchQuery: 'test',
        );
        final cleared = filters.clearFilters();
        expect(cleared.hasActiveFilters, isFalse);
        expect(cleared.activeFilterCount, 0);
      });
    });

    group('resetSorting', () {
      test('resets to default sorting', () {
        const filters = EnquiryFilters(
          sortBy: EnquirySortBy.eventDate,
          sortOrder: SortOrder.ascending,
        );
        final reset = filters.resetSorting();
        expect(reset.sortBy, EnquirySortBy.createdAt);
        expect(reset.sortOrder, SortOrder.descending);
      });
    });

    group('activeFilterDescriptions', () {
      test('returns empty list for no filters', () {
        const filters = EnquiryFilters();
        expect(filters.activeFilterDescriptions, isEmpty);
      });

      test('returns descriptions for active filters', () {
        const filters = EnquiryFilters(
          statuses: ['new', 'contacted'],
          eventTypes: ['wedding'],
          assigneeId: 'user123',
          searchQuery: 'test query',
        );
        final descriptions = filters.activeFilterDescriptions;
        expect(descriptions.length, 4);
        expect(descriptions.any((d) => d.contains('Status')), isTrue);
        expect(descriptions.any((d) => d.contains('Event Type')), isTrue);
        expect(descriptions.any((d) => d.contains('Assignee')), isTrue);
        expect(descriptions.any((d) => d.contains('Search')), isTrue);
      });
    });
  });

  group('FilterDateRange', () {
    test('creates with start and end dates', () {
      final start = DateTime(2024, 1, 1);
      final end = DateTime(2024, 1, 31);
      final range = FilterDateRange(start: start, end: end);
      expect(range.start, start);
      expect(range.end, end);
    });
  });

  group('EnquirySortBy', () {
    test('has correct field names', () {
      expect(EnquirySortBy.createdAt.field, 'createdAt');
      expect(EnquirySortBy.eventDate.field, 'eventDate');
      expect(EnquirySortBy.customerName.field, 'customerName');
    });

    test('has display names', () {
      expect(EnquirySortBy.createdAt.displayName, 'Created Date');
      expect(EnquirySortBy.eventDate.displayName, 'Event Date');
    });
  });

  group('SortOrder', () {
    test('has correct values', () {
      expect(SortOrder.ascending.value, 'asc');
      expect(SortOrder.descending.value, 'desc');
    });

    test('has display names', () {
      expect(SortOrder.ascending.displayName, 'Ascending');
      expect(SortOrder.descending.displayName, 'Descending');
    });
  });
}
