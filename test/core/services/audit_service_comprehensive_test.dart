import 'package:flutter_test/flutter_test.dart';
import 'package:we_decor_enquiries/core/services/audit_service.dart';
import '../../test_helper.dart';

void main() {
  late bool firebaseAvailable;

  setUpAll(() async {
    firebaseAvailable = await setupFirebaseForTesting();
    if (firebaseAvailable) {
      // Ensure Firebase is ready before tests run
      await Future<void>.delayed(const Duration(milliseconds: 200));
    }
  });

  group('AuditService', () {
    setUp(() {
      if (!firebaseAvailable) {
        // Skip creating service if Firebase is not available
        return;
      }
    });

    group('recordChange', () {
      test('completes successfully for valid change', () async {
        if (!firebaseAvailable) {
          // Skip test if Firebase is not available (e.g., in VM tests without emulators)
          // To run this test, start Firebase emulators: firebase emulators:start --only auth,firestore
          return;
        }
        final service = AuditService();
        await expectLater(
          service.recordChange(
            enquiryId: 'test-enquiry-id',
            fieldChanged: 'status',
            oldValue: 'new',
            newValue: 'contacted',
          ),
          completes,
        );
      });

      test('handles null old value', () async {
        if (!firebaseAvailable) return;
        final service = AuditService();
        await expectLater(
          service.recordChange(
            enquiryId: 'test-enquiry-id',
            fieldChanged: 'assignedTo',
            oldValue: null,
            newValue: 'user123',
          ),
          completes,
        );
      });

      test('handles null new value', () async {
        if (!firebaseAvailable) return;
        final service = AuditService();
        await expectLater(
          service.recordChange(
            enquiryId: 'test-enquiry-id',
            fieldChanged: 'assignedTo',
            oldValue: 'user123',
            newValue: null,
          ),
          completes,
        );
      });

      test('handles custom userId', () async {
        if (!firebaseAvailable) return;
        final service = AuditService();
        await expectLater(
          service.recordChange(
            enquiryId: 'test-enquiry-id',
            fieldChanged: 'status',
            oldValue: 'new',
            newValue: 'contacted',
            userId: 'custom-user-id',
          ),
          completes,
        );
      });

      test('handles different field types', () async {
        if (!firebaseAvailable) return;
        final service = AuditService();
        await expectLater(
          service.recordChange(
            enquiryId: 'test-enquiry-id',
            fieldChanged: 'totalCost',
            oldValue: 1000,
            newValue: 2000,
          ),
          completes,
        );
      });
    });

    group('recordMultipleChanges', () {
      test('records multiple changes in batch', () async {
        if (!firebaseAvailable) return;
        final service = AuditService();
        final changes = {
          'status': {'old_value': 'new', 'new_value': 'contacted'},
          'priority': {'old_value': 'low', 'new_value': 'high'},
        };

        await expectLater(
          service.recordMultipleChanges(
            enquiryId: 'test-enquiry-id',
            changes: changes,
          ),
          completes,
        );
      });

      test('handles empty changes map', () async {
        if (!firebaseAvailable) return;
        final service = AuditService();
        await expectLater(
          service.recordMultipleChanges(
            enquiryId: 'test-enquiry-id',
            changes: {},
          ),
          completes,
        );
      });

      test('handles custom userId for batch', () async {
        if (!firebaseAvailable) return;
        final service = AuditService();
        final changes = {
          'status': {'old_value': 'new', 'new_value': 'contacted'},
        };

        await expectLater(
          service.recordMultipleChanges(
            enquiryId: 'test-enquiry-id',
            changes: changes,
            userId: 'custom-user-id',
          ),
          completes,
        );
      });
    });

    group('getEnquiryHistoryStream', () {
      test('returns a stream', () {
        if (!firebaseAvailable) return;
        final service = AuditService();
        final stream = service.getEnquiryHistoryStream('test-enquiry-id');
        expect(stream, isA<Stream<List<Map<String, dynamic>>>>());
      });

      test('handles non-existent enquiry', () {
        if (!firebaseAvailable) return;
        final service = AuditService();
        final stream = service.getEnquiryHistoryStream('non-existent-id');
        expect(stream, isA<Stream<List<Map<String, dynamic>>>>());
      });
    });
  });
}
