import 'package:flutter_test/flutter_test.dart';
import 'package:we_decor_enquiries/features/dashboard/presentation/widgets/dashboard_enquiry_utils.dart';

void main() {
  group('formatDateLabel', () {
    test('returns dash for epoch fallback dates', () {
      expect(formatDateLabel(DateTime.fromMillisecondsSinceEpoch(0)), '—');
    });

    test('returns Date TBC for null', () {
      expect(formatDateLabel(null), 'Date TBC');
    });

    test('formats valid dates', () {
      expect(formatDateLabel(DateTime(2026, 3, 5)), '05/03/2026');
    });
  });

  group('phone search ignores +91 / 0 prefixes', () {
    bool m(String stored, String query) =>
        matchesEnquirySearchQuery({'customerPhone': stored}, query);

    test('stored without code, searched with code', () {
      expect(m('9876543210', '+91 98765 43210'), isTrue);
      expect(m('9876543210', '919876543210'), isTrue);
      expect(m('9876543210', '0091 9876543210'), isTrue);
      expect(m('9876543210', '09876543210'), isTrue);
      expect(m('9876543210', '+91 98765'), isTrue);
    });

    test('stored with code, searched without', () {
      expect(m('+91 98765 43210', '9876543210'), isTrue);
      expect(m('+919876543210', '98765'), isTrue);
    });

    test('different numbers do not match', () {
      expect(m('9812345678', '9123456789'), isFalse);
      expect(m('9876543210', '+91 99999'), isFalse);
    });
  });
}
