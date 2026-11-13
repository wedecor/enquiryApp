import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:we_decor_enquiries/core/constants/firestore_schema.dart';
import 'package:we_decor_enquiries/core/services/audit_service.dart';
import 'package:we_decor_enquiries/core/services/firestore_service.dart';
import 'package:we_decor_enquiries/features/enquiries/data/enquiry_merge_service.dart';

class MockAuditService extends Mock implements AuditService {}

void main() {
  late FakeFirebaseFirestore fakeDb;
  late MockAuditService mockAudit;
  late EnquiryMergeService service;

  setUp(() {
    fakeDb = FakeFirebaseFirestore();
    mockAudit = MockAuditService();
    when(() => mockAudit.newHistoryRef(any())).thenAnswer(
      (inv) => fakeDb
          .collection(FirestoreCollections.enquiries)
          .doc(inv.positionalArguments.first as String)
          .collection('history')
          .doc(),
    );
    when(
      () => mockAudit.buildHistoryEntry(
        fieldChanged: any(named: 'fieldChanged'),
        oldValue: any(named: 'oldValue'),
        newValue: any(named: 'newValue'),
      ),
    ).thenAnswer(
      (inv) => {
        'field_changed': inv.namedArguments[#fieldChanged],
        'old_value': inv.namedArguments[#oldValue],
        'new_value': inv.namedArguments[#newValue],
      },
    );
    service = EnquiryMergeService(FirestoreService(firestore: fakeDb), mockAudit);
  });

  group('EnquiryMergeService', () {
    test('mergeNote formats with and without date', () {
      expect(
        EnquiryMergeService.mergeNote(
          customerName: 'Priya',
          sourceCreatedAt: DateTime(2026, 11, 4),
          notes: 'Extra flowers',
        ),
        'Merged from duplicate enquiry Priya 4 Nov 2026: Extra flowers',
      );
      expect(
        EnquiryMergeService.mergeNote(
          customerName: 'Priya',
          sourceCreatedAt: null,
          notes: 'Extra flowers',
        ),
        'Merged from duplicate enquiry Priya: Extra flowers',
      );
    });

    test('markAsDuplicate rejects self-merge, missing docs, and already-merged target', () async {
      await expectLater(
        service.markAsDuplicate(sourceId: 'e1', targetId: 'e1', userId: 'admin-1'),
        throwsArgumentError,
      );

      await expectLater(
        service.markAsDuplicate(sourceId: 'missing', targetId: 'e2', userId: 'admin-1'),
        throwsStateError,
      );

      await fakeDb.collection('enquiries').doc('e1').set({'customerName': 'A', 'statusValue': 'new'});
      await expectLater(
        service.markAsDuplicate(sourceId: 'e1', targetId: 'missing', userId: 'admin-1'),
        throwsStateError,
      );

      await fakeDb.collection('enquiries').doc('e2').set({
        'customerName': 'B',
        'mergedInto': 'e3',
      });
      await expectLater(
        service.markAsDuplicate(sourceId: 'e1', targetId: 'e2', userId: 'admin-1'),
        throwsStateError,
      );
    });

    test('markAsDuplicate closes source as duplicate, merges notes and images into target, and writes history', () async {
      await fakeDb.collection('enquiries').doc('src').set({
        'customerName': 'Priya Sharma',
        'statusValue': 'new',
        'notes': 'Stage + entrance',
        'images': ['https://example.com/a.jpg', 'https://example.com/b.jpg'],
        'createdAt': Timestamp.fromDate(DateTime(2026, 11, 1)),
      });
      await fakeDb.collection('enquiries').doc('tgt').set({
        'customerName': 'Priya Sharma',
        'customerPhone': '9876543210',
        'statusValue': 'in_talks',
        'notes': 'Initial call',
        'images': ['https://example.com/a.jpg'],
      });

      await service.markAsDuplicate(sourceId: 'src', targetId: 'tgt', userId: 'admin-1');

      final srcSnap = await fakeDb.collection('enquiries').doc('src').get();
      expect(srcSnap.data()!['statusValue'], 'closed_lost');
      expect(srcSnap.data()!['lostReason'], 'duplicate');
      expect(srcSnap.data()!['mergedInto'], 'tgt');

      final tgtSnap = await fakeDb.collection('enquiries').doc('tgt').get();
      expect(tgtSnap.data()!['notes'], contains('Initial call'));
      expect(tgtSnap.data()!['notes'], contains('Merged from duplicate enquiry Priya Sharma 1 Nov 2026: Stage + entrance'));
      expect(
        List<String>.from(tgtSnap.data()!['images'] as List),
        unorderedEquals(['https://example.com/a.jpg', 'https://example.com/b.jpg']),
      );

      final srcHistory = await fakeDb.collection('enquiries').doc('src').collection('history').get();
      final tgtHistory = await fakeDb.collection('enquiries').doc('tgt').collection('history').get();
      expect(srcHistory.docs.map((d) => d.data()['field_changed']), containsAll(['statusValue', 'lostReason', 'mergedInto']));
      expect(tgtHistory.docs.map((d) => d.data()['field_changed']), containsAll(['mergedFrom', 'notes', 'images']));
    });
  });
}
