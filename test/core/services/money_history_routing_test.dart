import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:we_decor_enquiries/core/services/audit_service.dart';
import 'package:we_decor_enquiries/core/services/firestore_service.dart';
import 'package:we_decor_enquiries/core/services/notification_service.dart' as notification_service;
import 'package:we_decor_enquiries/features/enquiries/data/enquiry_repository.dart';
import 'package:we_decor_enquiries/services/dropdown_lookup.dart';

class _MockFirebaseAuth extends Mock implements FirebaseAuth {}

class _MockUser extends Mock implements User {}

class _MockFirestoreService extends Mock implements FirestoreService {}

class _MockNotificationService extends Mock implements notification_service.NotificationService {}

class _MockDropdownLookup extends Mock implements DropdownLookup {}

void main() {
  late FakeFirebaseFirestore fakeDb;
  late _MockFirebaseAuth mockAuth;
  late _MockUser mockUser;
  late _MockFirestoreService mockFirestoreService;
  late AuditService auditService;

  setUp(() {
    fakeDb = FakeFirebaseFirestore();
    mockAuth = _MockFirebaseAuth();
    mockUser = _MockUser();
    mockFirestoreService = _MockFirestoreService();

    when(() => mockUser.uid).thenReturn('admin-1');
    when(() => mockUser.email).thenReturn('admin@wedecor.test');
    when(() => mockAuth.currentUser).thenReturn(mockUser);
    when(() => mockFirestoreService.firestore).thenReturn(fakeDb);
    when(() => mockFirestoreService.enquiriesCollection).thenReturn(fakeDb.collection('enquiries'));

    auditService = AuditService(mockFirestoreService, auth: mockAuth);
  });

  group('AuditService money history routing', () {
    test('isMoneyHistoryField matches all money fields case-insensitively', () {
      for (final f in [
        'totalCost',
        'totalcost',
        'advancePaid',
        'ADVANCEPAID',
        'quotedAmount',
        'quotedAt',
        'paymentStatus',
        'paymentStatusValue',
        'paymentStatusLabel',
      ]) {
        expect(AuditService.isMoneyHistoryField(f), isTrue, reason: f);
      }

      for (final f in ['notes', 'statusValue', 'eventLocation', 'quotation']) {
        expect(AuditService.isMoneyHistoryField(f), isFalse, reason: f);
      }
    });

    test('buildHistoryEntry truncates string old_value and new_value to 2000 chars', () {
      final longOld = 'a' * 2500;
      final longNew = 'b' * 2100;
      final entry = auditService.buildHistoryEntry(
        fieldChanged: 'notes',
        oldValue: longOld,
        newValue: longNew,
      );
      expect((entry['old_value'] as String).length, 2000);
      expect((entry['new_value'] as String).length, 2000);
    });

    test('admin edit changing totalCost writes to financial_history and not history', () async {
      await auditService.recordMultipleChanges(
        enquiryId: 'enq-1',
        changes: {
          'totalCost': {'old_value': 10000, 'new_value': 15000},
          'advancePaid': {'old_value': 2000, 'new_value': 5000},
          'paymentStatusValue': {'old_value': 'unpaid', 'new_value': 'partial'},
          'notes': {'old_value': 'Old', 'new_value': 'New'},
        },
      );

      final publicHist = await fakeDb
          .collection('enquiries')
          .doc('enq-1')
          .collection('history')
          .get();
      final finHist = await fakeDb
          .collection('enquiries')
          .doc('enq-1')
          .collection('financial_history')
          .get();

      expect(publicHist.docs.map((d) => d['field_changed']).toList(), ['notes']);
      for (final doc in publicHist.docs) {
        expect(AuditService.isMoneyHistoryField(doc['field_changed'] as String), isFalse);
      }
      expect(
        finHist.docs.map((d) => d['field_changed']).toList(),
        unorderedEquals(['totalCost', 'advancePaid', 'paymentStatusValue']),
      );
    });

    test(
      'confirm-booking path (updateStatus) writes money changes to financial_history only',
      () async {
        await fakeDb.collection('enquiries').doc('enq-book').set({
          'customerName': 'Priya',
          'statusValue': 'in_talks',
          'statusLabel': 'In Talks',
          'eventLocation': 'Indiranagar, Bengaluru',
        });

        final mockLookup = _MockDropdownLookup();
        when(() => mockLookup.labelForStatus(any())).thenReturn('Confirmed');

        final repo = EnquiryRepository(
          mockFirestoreService,
          Future.value(mockLookup),
          auditService,
          _MockNotificationService(),
        );

        await repo.updateStatus(
          id: 'enq-book',
          nextStatus: 'confirmed',
          userId: 'admin-1',
          extraFields: {
            'totalCost': 50000,
            'advancePaid': 15000,
            'paymentStatusValue': 'partial',
            'paymentStatusLabel': 'Partial',
            'eventLocation': 'Koramangala, Bengaluru',
          },
        );

        final publicHist = await fakeDb
            .collection('enquiries')
            .doc('enq-book')
            .collection('history')
            .get();
        final finHist = await fakeDb
            .collection('enquiries')
            .doc('enq-book')
            .collection('financial_history')
            .get();

        final publicFields = publicHist.docs.map((d) => d['field_changed'] as String).toList();
        expect(publicFields, unorderedEquals(['statusValue', 'eventLocation']));
        for (final f in publicFields) {
          expect(AuditService.isMoneyHistoryField(f), isFalse);
        }

        final finFields = finHist.docs.map((d) => d['field_changed'] as String).toList();
        expect(finFields, containsAll(['totalCost', 'advancePaid', 'paymentStatus']));
      },
    );

    test(
      'getMergedEnquiryHistoryStream merges for admin and skips financial_history for staff',
      () async {
        final col = fakeDb.collection('enquiries').doc('enq-stream');
        await col.collection('history').doc('h1').set({
          'field_changed': 'notes',
          'old_value': 'a',
          'new_value': 'b',
          'timestamp': Timestamp.fromDate(DateTime(2026, 11, 10, 10)),
        });
        await col.collection('financial_history').doc('f1').set({
          'field_changed': 'totalCost',
          'old_value': 1000,
          'new_value': 2000,
          'timestamp': Timestamp.fromDate(DateTime(2026, 11, 10, 12)),
        });

        final staffItems = await auditService
            .getMergedEnquiryHistoryStream('enq-stream', includeFinancial: false)
            .first;
        expect(staffItems.map((e) => e['field_changed']).toList(), ['notes']);

        final adminItems = await auditService
            .getMergedEnquiryHistoryStream('enq-stream', includeFinancial: true)
            .firstWhere((items) => items.length == 2);
        expect(adminItems.map((e) => e['field_changed']).toList(), ['totalCost', 'notes']);
      },
    );
  });
}
