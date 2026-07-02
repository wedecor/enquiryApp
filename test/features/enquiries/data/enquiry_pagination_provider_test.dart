import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:we_decor_enquiries/features/enquiries/data/enquiry_pagination_provider.dart';
import 'package:we_decor_enquiries/features/enquiries/data/enquiry_repository.dart';

class MockEnquiryRepository extends Mock implements EnquiryRepository {}

void main() {
  group('PaginatedEnquiriesNotifier', () {
    test('pageSize is 20 so Firestore reads at most 21 docs per request', () {
      final notifier = PaginatedEnquiriesNotifier(
        repository: MockEnquiryRepository(),
        isAdmin: true,
      );
      expect(notifier.pageSize, 20);
      expect(notifier.pageSize + 1, lessThanOrEqualTo(21));
    });

    test('PaginationParams equality is based on status filter', () {
      const all = PaginationParams();
      const contacted = PaginationParams(status: 'contacted');
      expect(all, isNot(equals(contacted)));
      expect(const PaginationParams(status: 'contacted'), equals(contacted));
    });
  });
}
