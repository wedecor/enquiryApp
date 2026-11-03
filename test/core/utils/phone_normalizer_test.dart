import 'package:flutter_test/flutter_test.dart';
import 'package:we_decor_enquiries/core/services/firestore_service.dart';
import 'package:we_decor_enquiries/core/utils/phone_normalizer.dart';

void main() {
  group('normalizePhone', () {
    test('Indian mobile formats all map to the same 10 digits', () {
      const expected = '9876543210';
      expect(normalizePhone('9876543210'), expected);
      expect(normalizePhone('+91 98765 43210'), expected);
      expect(normalizePhone('+91-98765-43210'), expected);
      expect(normalizePhone('919876543210'), expected);
      expect(normalizePhone('0091 9876543210'), expected);
      expect(normalizePhone('09876543210'), expected);
      expect(normalizePhone('(98765) 43210'), expected);
    });

    test('short numbers are kept as digits', () {
      expect(normalizePhone('080-2345678'), '0802345678');
      expect(normalizePhone('2345 678'), '2345678');
    });

    test('long international numbers keep the last 10 digits', () {
      expect(normalizePhone('+971 50 123 4567'), '1501234567');
    });

    test('null, empty and digit-free input give an empty string', () {
      expect(normalizePhone(null), '');
      expect(normalizePhone(''), '');
      expect(normalizePhone('n/a'), '');
    });

    test('phoneDigitCount counts digits only', () {
      expect(phoneDigitCount('+91 98765 43210'), 12);
      expect(phoneDigitCount(null), 0);
    });

    test('new enquiry writes store the same key', () {
      final fields = FirestoreService.searchIndexFieldsFor(
        customerName: 'Asha',
        customerPhone: '+91 98765 43210',
      );
      expect(fields['phoneNormalized'], '9876543210');
    });
  });
}
