import 'package:flutter_test/flutter_test.dart';
import 'package:we_decor_enquiries/core/utils/enquiry_fields.dart';

void main() {
  group('amountText', () {
    test('drops the trailing .0 Firestore adds to whole amounts', () {
      expect(amountText(50000.0), '50000');
      expect(amountText(50000), '50000');
    });

    test('keeps real decimals', () {
      expect(amountText(1250.5), '1250.5');
    });

    test('empty for null, passthrough for strings', () {
      expect(amountText(null), '');
      expect(amountText('12,000'), '12,000');
    });
  });
}
