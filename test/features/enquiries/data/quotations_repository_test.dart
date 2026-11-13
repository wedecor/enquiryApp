import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:we_decor_enquiries/core/constants/firestore_schema.dart';
import 'package:we_decor_enquiries/core/services/audit_service.dart';
import 'package:we_decor_enquiries/core/services/enquiry_financials.dart';
import 'package:we_decor_enquiries/features/enquiries/data/quotations_repository.dart';
import 'package:we_decor_enquiries/features/enquiries/domain/quotation.dart';

class MockAuditService extends Mock implements AuditService {}

void main() {
  late FakeFirebaseFirestore fakeDb;
  late MockAuditService mockAudit;
  late QuotationsRepository repo;

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
    repo = QuotationsRepository(fakeDb, mockAudit);
  });

  group('QuotationsRepository', () {
    test(
      'createDraft creates draft quote, writes history without amount, and getQuotation reads it',
      () async {
        final id = await repo.createDraft(
          enquiryId: 'enq-1',
          actorUid: 'admin-1',
          items: const [
            QuotationLineItem(
              description: 'Stage Decor',
              quantity: 1,
              unitPrice: 50000,
              gstPercent: 18,
            ),
          ],
          reference: 'Q-2026-001',
          notes: 'Includes setup',
        );

        final quote = await repo.getQuotation('enq-1', id);
        expect(quote, isNotNull);
        expect(quote!.status, Quotation.statusDraft);
        expect(quote.reference, 'Q-2026-001');
        expect(quote.items, hasLength(1));

        expect(await repo.getQuotation('enq-1', 'missing'), isNull);

        final historySnap = await fakeDb
            .collection(FirestoreCollections.enquiries)
            .doc('enq-1')
            .collection('history')
            .get();
        expect(historySnap.docs, hasLength(1));
        expect(historySnap.docs.first.data()['new_value'], 'draft Q-2026-001');
      },
    );

    test('updateDraft updates draft and rejects non-draft status', () async {
      final id = await repo.createDraft(
        enquiryId: 'enq-1',
        actorUid: 'admin-1',
        items: const [QuotationLineItem(description: 'Lights', unitPrice: 10000)],
      );

      await repo.updateDraft(
        enquiryId: 'enq-1',
        quoteId: id,
        actorUid: 'admin-1',
        items: const [QuotationLineItem(description: 'Lights + Sound', unitPrice: 15000)],
        status: Quotation.statusDraft,
      );

      final updated = await repo.getQuotation('enq-1', id);
      expect(updated!.items.first.description, 'Lights + Sound');

      await expectLater(
        repo.updateDraft(
          enquiryId: 'enq-1',
          quoteId: id,
          actorUid: 'admin-1',
          items: const [],
          status: Quotation.statusSent,
        ),
        throwsStateError,
      );
    });

    test('markSent computes totals, updates financial summary, and writes history', () async {
      final id = await repo.createDraft(
        enquiryId: 'enq-1',
        actorUid: 'admin-1',
        items: const [
          QuotationLineItem(description: 'Floral', quantity: 2, unitPrice: 10000, gstPercent: 18),
        ],
        reference: 'Q-100',
      );

      await repo.markSent(enquiryId: 'enq-1', quoteId: id, actorUid: 'admin-1');

      final sent = await repo.getQuotation('enq-1', id);
      expect(sent!.status, Quotation.statusSent);
      expect(sent.subtotal, 20000);
      expect(sent.gstTotal, 3600);
      expect(sent.total, 23600);

      final fin = await EnquiryFinancials.ref(fakeDb, 'enq-1').get();
      expect(fin.exists, isTrue);
      expect(fin.data()!['quotedAmount'], 23600);

      await expectLater(
        repo.markSent(enquiryId: 'enq-1', quoteId: 'missing', actorUid: 'admin-1'),
        throwsStateError,
      );
    });

    test('deleteDraft deletes drafts, ignores missing, and rejects sent quotes', () async {
      final id = await repo.createDraft(
        enquiryId: 'enq-1',
        actorUid: 'admin-1',
        items: const [QuotationLineItem(description: 'Item', unitPrice: 1000)],
      );
      await repo.deleteDraft(enquiryId: 'enq-1', quoteId: id);
      expect(await repo.getQuotation('enq-1', id), isNull);

      await repo.deleteDraft(enquiryId: 'enq-1', quoteId: 'does-not-exist');

      final sentId = await repo.createDraft(
        enquiryId: 'enq-1',
        actorUid: 'admin-1',
        items: const [QuotationLineItem(description: 'Item', unitPrice: 1000)],
      );
      await repo.markSent(enquiryId: 'enq-1', quoteId: sentId, actorUid: 'admin-1');
      await expectLater(repo.deleteDraft(enquiryId: 'enq-1', quoteId: sentId), throwsStateError);
    });

    test('watchQuotations, upsertCatalogItem, and watchCatalog stream data', () async {
      await repo.createDraft(
        enquiryId: 'enq-1',
        actorUid: 'admin-1',
        items: const [QuotationLineItem(description: 'A', unitPrice: 500)],
      );
      final quotes = await repo.watchQuotations('enq-1').first;
      expect(quotes, hasLength(1));

      final catId = await repo.upsertCatalogItem(
        const CatalogItem(id: '', name: 'Arch', unitPrice: 12000, gstPercent: 18),
      );
      await repo.upsertCatalogItem(
        CatalogItem(id: catId, name: 'Arch Deluxe', unitPrice: 15000, gstPercent: 18),
      );
      final catalog = await repo.watchCatalog().first;
      expect(catalog, hasLength(1));
      expect(catalog.first.name, 'Arch Deluxe');
    });
  });
}
