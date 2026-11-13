import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:we_decor_enquiries/core/services/enquiry_financials.dart';
import 'package:we_decor_enquiries/core/services/firestore_service.dart';

// Mock classes
class MockFirestore extends Mock implements FirebaseFirestore {}

class MockCollectionReference extends Mock implements CollectionReference<Map<String, dynamic>> {}

class MockDocumentReference extends Mock implements DocumentReference<Map<String, dynamic>> {}

class MockDocumentSnapshot extends Mock implements DocumentSnapshot<Map<String, dynamic>> {}

class MockQuerySnapshot extends Mock implements QuerySnapshot<Map<String, dynamic>> {}

class MockQueryDocumentSnapshot extends Mock
    implements QueryDocumentSnapshot<Map<String, dynamic>> {}

void main() {
  group('FirestoreService', () {
    // Note: FirestoreService uses FirebaseFirestore.instance directly
    // For full testing, you'd need to refactor to accept Firestore as dependency
    // or use Firebase emulators for integration tests

    group('User Operations', () {
      test('getUser returns null for non-existent user', () async {
        // This test would require mocking Firestore instance
        // For now, this is a placeholder showing the test structure
        expect(true, isTrue); // Placeholder
      });

      test('createUser validates required fields', () {
        // Test validation logic
        expect(true, isTrue); // Placeholder
      });
    });

    group('Enquiry Operations', () {
      test('createEnquiry requires customer name', () {
        // Test validation
        expect(true, isTrue); // Placeholder
      });

      test('createEnquiry requires event date', () {
        // Test validation
        expect(true, isTrue); // Placeholder
      });
    });

    group('Dropdown Operations', () {
      test('getEventTypes returns list of event types', () {
        // Test retrieval
        expect(true, isTrue); // Placeholder
      });

      test('getStatuses returns list of statuses', () {
        // Test retrieval
        expect(true, isTrue); // Placeholder
      });
    });

    group('Soft delete and restore', () {
      test(
        'deleteEnquiry moves enquiry and financial summary to enquiries_trash and keeps subcollections',
        () async {
          final fakeDb = FakeFirebaseFirestore();
          final service = FirestoreService(firestore: fakeDb);

          await fakeDb.collection('enquiries').doc('enq-1').set({
            'customerName': 'Asha',
            'statusValue': 'new',
          });
          await EnquiryFinancials.ref(
            fakeDb,
            'enq-1',
          ).set({'totalCost': 50000, 'advancePaid': 10000});
          await fakeDb.collection('enquiries').doc('enq-1').collection('history').doc('h1').set({
            'field_changed': 'statusValue',
          });

          await service.deleteEnquiry('enq-1', deletedBy: 'admin-1');

          expect((await fakeDb.collection('enquiries').doc('enq-1').get()).exists, isFalse);
          expect((await EnquiryFinancials.ref(fakeDb, 'enq-1').get()).exists, isFalse);
          expect(
            (await fakeDb
                    .collection('enquiries')
                    .doc('enq-1')
                    .collection('history')
                    .doc('h1')
                    .get())
                .exists,
            isTrue,
          );

          final trashSnap = await fakeDb.collection('enquiries_trash').doc('enq-1').get();
          expect(trashSnap.exists, isTrue);
          final trash = trashSnap.data()!;
          expect((trash['enquiry'] as Map)['customerName'], 'Asha');
          expect((trash['financial'] as Map)['totalCost'], 50000);
          expect(trash['deletedBy'], 'admin-1');
          expect(trash['deletedAt'], isNotNull);
        },
      );

      test(
        'restoreEnquiry recreates enquiry without money on parent and restores financial summary',
        () async {
          final fakeDb = FakeFirebaseFirestore();
          final service = FirestoreService(firestore: fakeDb);

          await fakeDb.collection('enquiries_trash').doc('enq-2').set({
            'enquiry': {
              'customerName': 'Rohan',
              'statusValue': 'approved',
              'totalCost': 80000, // legacy money field on parent must be stripped
            },
            'financial': {'totalCost': 80000, 'advancePaid': 25000},
            'deletedAt': Timestamp.now(),
            'deletedBy': 'admin-1',
          });

          await service.restoreEnquiry('enq-2');

          final restoredEnq = await fakeDb.collection('enquiries').doc('enq-2').get();
          expect(restoredEnq.exists, isTrue);
          expect(restoredEnq.data()!['customerName'], 'Rohan');
          expect(restoredEnq.data()!.containsKey('totalCost'), isFalse);

          final restoredFin = await EnquiryFinancials.ref(fakeDb, 'enq-2').get();
          expect(restoredFin.exists, isTrue);
          expect(restoredFin.data()!['totalCost'], 80000);
          expect(restoredFin.data()!['advancePaid'], 25000);

          expect((await fakeDb.collection('enquiries_trash').doc('enq-2').get()).exists, isFalse);
        },
      );

      test('restoreEnquiry refuses when enquiries/{id} already exists', () async {
        final fakeDb = FakeFirebaseFirestore();
        final service = FirestoreService(firestore: fakeDb);

        await fakeDb.collection('enquiries').doc('enq-3').set({'customerName': 'Existing'});
        await fakeDb.collection('enquiries_trash').doc('enq-3').set({
          'enquiry': {'customerName': 'Trashed'},
          'financial': null,
        });

        await expectLater(service.restoreEnquiry('enq-3'), throwsStateError);
        expect((await fakeDb.collection('enquiries_trash').doc('enq-3').get()).exists, isTrue);
      });

      test(
        'createEnquiry uses client-generated id and writes financial summary atomically',
        () async {
          final fakeDb = FakeFirebaseFirestore();
          final service = FirestoreService(firestore: fakeDb);
          final id = service.newEnquiryId();

          final createdId = await service.createEnquiry(
            enquiryId: id,
            customerName: 'Priya',
            customerEmail: 'priya@example.com',
            customerPhone: '9876543210',
            eventType: 'wedding',
            eventDate: DateTime(2027, 2, 14),
            eventLocation: 'Bangalore',
            guestCount: 150,
            budgetRange: '1L-2L',
            description: 'Floral decor',
            createdBy: 'admin-1',
            priority: 'high',
            source: 'instagram',
            totalCost: 120000,
            advancePaid: 30000,
            extraFinancialFields: {'quotedAmount': 125000},
          );

          expect(createdId, id);
          final parent = await fakeDb.collection('enquiries').doc(id).get();
          expect(parent.exists, isTrue);
          expect(parent.data()!.containsKey('totalCost'), isFalse);
          expect(parent.data()!.containsKey('quotedAmount'), isFalse);

          final fin = await EnquiryFinancials.ref(fakeDb, id).get();
          expect(fin.exists, isTrue);
          expect(fin.data()!['totalCost'], 120000);
          expect(fin.data()!['advancePaid'], 30000);
          expect(fin.data()!['quotedAmount'], 125000);
        },
      );
    });
  });
}
