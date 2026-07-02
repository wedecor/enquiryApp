import 'package:flutter_test/flutter_test.dart';
import 'package:we_decor_enquiries/features/enquiries/filters/apply_enquiry_filters.dart';
import 'package:we_decor_enquiries/features/enquiries/filters/filters_state.dart';

void main() {
  const sample = {
    'customerName': 'Alice',
    'statusValue': 'new',
    'eventTypeValue': 'wedding',
    'assignedTo': 'user-1',
    'customerPhone': '9876543210',
  };

  test('passes when no filters active', () {
    expect(matchesEnquiryFilters(sample, const EnquiryFilters()), isTrue);
  });

  test('filters by status', () {
    const filters = EnquiryFilters(statuses: ['contacted']);
    expect(matchesEnquiryFilters(sample, filters), isFalse);

    const match = EnquiryFilters(statuses: ['new']);
    expect(matchesEnquiryFilters(sample, match), isTrue);
  });

  test('legacy status values match canonical filter slugs', () {
    const legacyInTalks = {'statusValue': 'quote_sent'};
    const filters = EnquiryFilters(statuses: ['in_talks']);
    expect(matchesEnquiryFilters(legacyInTalks, filters), isTrue);

    const legacyApproved = {'statusValue': 'scheduled'};
    const approvedFilter = EnquiryFilters(statuses: ['approved']);
    expect(matchesEnquiryFilters(legacyApproved, approvedFilter), isTrue);
  });

  test('filters by assignee including current user alias', () {
    const filters = EnquiryFilters(assigneeId: 'current_user_id');
    expect(
      matchesEnquiryFilters(sample, filters, currentUserId: 'user-2'),
      isFalse,
    );
    expect(
      matchesEnquiryFilters(sample, filters, currentUserId: 'user-1'),
      isTrue,
    );
  });

  test('filters by search query', () {
    const filters = EnquiryFilters(searchQuery: '98765');
    expect(matchesEnquiryFilters(sample, filters), isTrue);

    const noMatch = EnquiryFilters(searchQuery: 'bob');
    expect(matchesEnquiryFilters(sample, noMatch), isFalse);
  });
}
