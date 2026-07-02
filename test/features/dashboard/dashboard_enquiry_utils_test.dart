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
}
