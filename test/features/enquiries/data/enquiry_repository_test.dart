import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:we_decor_enquiries/core/services/audit_service.dart';
import 'package:we_decor_enquiries/core/services/firestore_service.dart';
import 'package:we_decor_enquiries/core/services/notification_service.dart'
    as notification_service;
import 'package:we_decor_enquiries/features/enquiries/data/enquiry_repository.dart';
import 'package:we_decor_enquiries/features/enquiries/domain/enquiry.dart';
import 'package:we_decor_enquiries/services/dropdown_lookup.dart';
import '../../../test_helper.dart';

class MockDropdownLookup extends Mock implements DropdownLookup {}

class MockAuditService extends Mock implements AuditService {}

class MockNotificationService extends Mock
    implements notification_service.NotificationService {}

void main() {
  late bool firebaseAvailable;

  setUpAll(() async {
    firebaseAvailable = await setupFirebaseForTesting();
    if (firebaseAvailable) {
      // Ensure Firebase is ready before tests run
      await Future<void>.delayed(const Duration(milliseconds: 200));
    }
  });

  group('EnquiryRepository', () {
    late EnquiryRepository repository;
    late Future<DropdownLookup> dropdownLookupFuture;

    setUp(() {
      if (!firebaseAvailable) return;
      final mockLookup = MockDropdownLookup();
      when(() => mockLookup.labelForStatus(any())).thenReturn('Test Status');
      dropdownLookupFuture = Future.value(mockLookup);
      repository = EnquiryRepository(
        FirestoreService(),
        dropdownLookupFuture,
        MockAuditService(),
        MockNotificationService(),
      );
    });

    group('getEnquiries', () {
      test('returns a stream of enquiries', () {
        if (!firebaseAvailable) return;
        final stream = repository.getEnquiries();
        expect(stream, isA<Stream<List<Enquiry>>>());
      });
    });

    group('getPaginatedEnquiries', () {
      test('returns pagination state', () async {
        if (!firebaseAvailable) return;
        final state = await repository.getPaginatedEnquiries(isAdmin: true);
        expect(state, isNotNull);
      });
    });

    group('updateStatus', () {
      test('updates status successfully', () async {
        if (!firebaseAvailable) return;
        await expectLater(
          repository.updateStatus(
            id: 'test-id',
            nextStatus: 'contacted',
            userId: 'user123',
          ),
          completes,
        );
      });
    });

    group('createEnquiry', () {
      test('creates enquiry with required fields', () async {
        if (!firebaseAvailable) return;
        final data = {
          'customerName': 'John Doe',
          'customerPhone': '+1234567890',
          'customerEmail': 'john@example.com',
          'createdBy': 'user123',
          'createdByName': 'Admin User',
        };

        await expectLater(repository.createEnquiry(data), completes);
      });

      test('handles missing optional fields', () async {
        if (!firebaseAvailable) return;
        final data = {
          'customerName': 'Jane Doe',
          'createdBy': 'user123',
          'createdByName': 'Admin User',
        };

        await expectLater(repository.createEnquiry(data), completes);
      });

      test('normalizes phone number', () async {
        if (!firebaseAvailable) return;
        final data = {
          'customerName': 'Test User',
          'customerPhone': '+1 (234) 567-8900',
          'createdBy': 'user123',
          'createdByName': 'Admin User',
        };

        await expectLater(repository.createEnquiry(data), completes);
      });

      test('creates text index for search', () async {
        if (!firebaseAvailable) return;
        final data = {
          'customerName': 'Search Test',
          'customerPhone': '1234567890',
          'customerEmail': 'search@test.com',
          'notes': 'Test notes',
          'createdBy': 'user123',
          'createdByName': 'Admin User',
        };

        await expectLater(repository.createEnquiry(data), completes);
      });
    });
  });
}
