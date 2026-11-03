import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:we_decor_enquiries/core/services/firestore_service.dart';
import 'package:we_decor_enquiries/core/services/notification_service.dart';

class MockFirestoreService extends Mock implements FirestoreService {}

/// The app must not write notifications for other users (rules deny it); it only
/// announces enquiry events to the `notifyEnquiryEvent` function. These tests pin
/// the payloads so recipient flags at the call sites keep their meaning.
void main() {
  late List<Map<String, dynamic>> calls;
  late NotificationService service;

  setUp(() {
    calls = [];
    service = NotificationService(
      MockFirestoreService(),
      announcer: (payload) async => calls.add(payload),
    );
  });

  test('created sends only the enquiry id and event (no title/body/recipients)', () async {
    await service.notifyEnquiryCreated(
      enquiryId: 'e1',
      customerName: 'Priya',
      eventType: 'Birthday',
      createdBy: 'admin1',
    );
    expect(calls, [
      {'enquiryId': 'e1', 'event': 'created'},
    ]);
  });

  test('assigned forwards notifyAdmins', () async {
    await service.notifyEnquiryAssigned(
      enquiryId: 'e1',
      customerName: 'Priya',
      eventType: 'Birthday',
      assignedTo: 'staff1',
      assignedBy: 'admin1',
      notifyAdmins: false,
    );
    expect(calls.single, {'enquiryId': 'e1', 'event': 'assigned', 'notifyAdmins': false});
  });

  test('status change sends the raw old status value; null assignee skips the assignee', () async {
    await service.notifyStatusUpdated(
      enquiryId: 'e1',
      customerName: 'Priya',
      oldStatus: 'New',
      oldStatusValue: 'new',
      newStatus: 'In Talks',
      updatedBy: 'staff1',
    );
    expect(calls.single, {
      'enquiryId': 'e1',
      'event': 'status_changed',
      'oldStatus': 'new',
      'notifyAssignee': false,
    });
  });

  test('update with an assignee asks the server to include them', () async {
    await service.notifyEnquiryUpdated(
      enquiryId: 'e1',
      customerName: 'Priya',
      eventType: 'Birthday',
      updatedBy: 'admin1',
      assignedTo: 'staff1',
    );
    expect(calls.single['notifyAssignee'], isTrue);
  });

  test('a failing call never throws (the save already succeeded)', () async {
    final failing = NotificationService(
      MockFirestoreService(),
      announcer: (_) async => throw Exception('offline'),
    );
    await expectLater(
      failing.notifyEnquiryUpdated(
        enquiryId: 'e1',
        customerName: 'Priya',
        eventType: 'Birthday',
        updatedBy: 'admin1',
      ),
      completes,
    );
  });
}
