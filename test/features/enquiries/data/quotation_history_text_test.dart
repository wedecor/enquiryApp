import 'package:flutter_test/flutter_test.dart';

/// Contract for [QuotationsRepository.markSent] history `new_value`:
/// staff can read enquiry history, so the sent line must never carry ₹ amounts.
void main() {
  test('sent-quote history text contains no rupee amount', () {
    const reference = 'Q-20261112-0445';
    // Same format as quotations_repository markSent history entry.
    const newValue = 'sent $reference';

    expect(newValue.contains('₹'), isFalse);
    expect(newValue, equals('sent Q-20261112-0445'));
    expect(newValue, isNot(contains(RegExp(r'₹\s*[\d,]+'))));
  });
}
