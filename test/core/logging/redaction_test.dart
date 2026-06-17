import 'package:flutter_test/flutter_test.dart';
import 'package:we_decor_enquiries/core/logging/logger.dart';
import 'package:we_decor_enquiries/core/logging/redaction.dart';

void main() {
  group('redactSensitiveText', () {
    test('redacts phone numbers in free text', () {
      const input = 'Called customer at 8762385315 for follow-up';
      final output = redactSensitiveText(input);

      expect(output, isNot(contains('8762385315')));
      expect(output, contains('***'));
    });

    test('redacts email addresses in free text', () {
      const input = 'Sent invite to connect2wedecor@gmail.com';
      final output = redactSensitiveText(input);

      expect(output, isNot(contains('connect2wedecor@gmail.com')));
    });
  });

  group('redactMapEntry', () {
    test('redacts values for phone-like keys', () {
      final output = redactMapEntry('customerPhone', '8762385315');

      expect(output, isNot('8762385315'));
      expect(output, contains('***'));
    });

    test('redacts phone numbers even when key is neutral', () {
      final output = redactMapEntry('note', 'callback on 8762385315');

      expect(output, isNot(contains('8762385315')));
    });
  });

  group('formatLogData', () {
    test('redacts phone values in map data by key', () {
      final output = formatLogData({'phone': '8762385315'});

      expect(output, isNot(contains('8762385315')));
      expect(output, contains('***'));
    });
  });
}
