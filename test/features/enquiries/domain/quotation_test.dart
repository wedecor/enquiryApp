import 'package:flutter_test/flutter_test.dart';
import 'package:we_decor_enquiries/features/enquiries/domain/quotation.dart';

void main() {
  group('QuotationLineItem', () {
    test('amount includes GST after discount', () {
      const item = QuotationLineItem(
        description: 'Mandap',
        quantity: 1,
        unitPrice: 10000,
        gstPercent: 18,
        discount: 1000,
      );
      expect(item.lineSubtotal, 9000);
      expect(item.gstAmount, 1620);
      expect(item.amount, 10620);
    });

    test('negative after discount clamps to zero', () {
      const item = QuotationLineItem(description: 'X', quantity: 1, unitPrice: 100, discount: 500);
      expect(item.lineSubtotal, 0);
      expect(item.amount, 0);
    });
  });

  group('QuotationTotals', () {
    test('sums lines', () {
      final totals = QuotationTotals.of([
        const QuotationLineItem(description: 'A', quantity: 2, unitPrice: 1000, gstPercent: 18),
        const QuotationLineItem(
          description: 'B',
          quantity: 1,
          unitPrice: 5000,
          gstPercent: 18,
          discount: 500,
        ),
      ]);
      expect(totals.subtotal, 7000);
      expect(totals.discountTotal, 500);
      expect(totals.gstTotal, closeTo(2 * 1000 * 0.18 + 4500 * 0.18, 0.01));
      expect(totals.total, closeTo(6500 + totals.gstTotal, 0.01));
    });
  });

  group('Quotation.fromMap', () {
    test('missing pastCustomer-style fields default to draft', () {
      final q = Quotation.fromMap('q1', {
        'items': [
          {'description': 'Stage', 'quantity': 1, 'unitPrice': 20000, 'gstPercent': 18},
        ],
        'subtotal': 20000,
        'gstTotal': 3600,
        'discountTotal': 0,
        'total': 23600,
      });
      expect(q.id, 'q1');
      expect(q.isDraft, isTrue);
      expect(q.items.single.description, 'Stage');
      expect(q.items.single.amount, 23600);
    });
  });

  group('CatalogItem.toLineItem', () {
    test('uses description when present, else name', () {
      const named = CatalogItem(id: '1', name: 'Floral arch', unitPrice: 8000);
      expect(named.toLineItem().description, 'Floral arch');
      const withDesc = CatalogItem(
        id: '2',
        name: 'Arch',
        description: 'Floral arch — entrance',
        unitPrice: 8000,
        gstPercent: 18,
      );
      expect(withDesc.toLineItem().description, 'Floral arch — entrance');
      expect(withDesc.toLineItem().gstPercent, 18);
    });
  });
}
