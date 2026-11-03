import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:we_decor_enquiries/core/services/enquiry_financials.dart';

void main() {
  group('EnquiryFinancials', () {
    test('split sends every money field to the summary and nothing else', () {
      final parts = EnquiryFinancials.split({
        'customerName': 'Priya',
        'statusValue': 'approved',
        'totalCost': 90000,
        'advancePaid': 20000,
        'paymentStatus': 'partial',
        'paymentStatusValue': 'partial',
        'paymentStatusLabel': 'Partial',
        'quotedAmount': 95000,
        'quotedAt': Timestamp.now(),
      });
      expect(parts.parent.keys, unorderedEquals(['customerName', 'statusValue']));
      expect(parts.money.keys, unorderedEquals(EnquiryFinancials.fields));
    });

    test('summaryWrite turns deletes into nulls and stamps updatedAt', () {
      final write = EnquiryFinancials.summaryWrite({
        'totalCost': FieldValue.delete(),
        'advancePaid': 100,
      });
      expect(write['totalCost'], isNull);
      expect(write['advancePaid'], 100);
      expect(write['updatedAt'], isA<FieldValue>());
    });

    test('merge prefers the summary; falls back to legacy parent money without one', () {
      final parent = {'customerName': 'Priya', 'totalCost': 1, 'advancePaid': 1};
      final merged = EnquiryFinancials.merge(parent, {'totalCost': 90000});
      expect(merged['totalCost'], 90000);
      expect(merged.containsKey('advancePaid'), isFalse, reason: 'summary is authoritative');
      expect(merged['customerName'], 'Priya');
      expect(EnquiryFinancials.merge(parent, null), same(parent));
    });

    test('strip removes every money field (non-admin views)', () {
      final stripped = EnquiryFinancials.strip({
        'customerName': 'Priya',
        for (final f in EnquiryFinancials.fields) f: 1,
      });
      expect(stripped.keys, ['customerName']);
    });
  });
}
