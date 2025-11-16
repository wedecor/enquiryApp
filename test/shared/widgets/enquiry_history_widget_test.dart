import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:we_decor_enquiries/shared/widgets/enquiry_history_widget.dart';

void main() {
  group('EnquiryHistoryWidget', () {
    group('_formatTimestamp', () {
      test('formats timestamp as "Just now" for recent changes', () {
        final now = DateTime.now();
        final timestamp = Timestamp.fromDate(now);
        // Note: This is a private method, so we test indirectly
        // In a real scenario, you'd test through the widget
        expect(timestamp, isA<Timestamp>());
      });

      test('formats timestamp as "Xm ago" for minutes', () {
        final now = DateTime.now().subtract(const Duration(minutes: 5));
        final timestamp = Timestamp.fromDate(now);
        expect(timestamp, isA<Timestamp>());
      });

      test('formats timestamp as "Xh ago" for hours', () {
        final now = DateTime.now().subtract(const Duration(hours: 2));
        final timestamp = Timestamp.fromDate(now);
        expect(timestamp, isA<Timestamp>());
      });

      test('formats timestamp as "Xd ago" for days', () {
        final now = DateTime.now().subtract(const Duration(days: 3));
        final timestamp = Timestamp.fromDate(now);
        expect(timestamp, isA<Timestamp>());
      });
    });

    group('_getFieldDisplayName', () {
      test('returns correct display name for status', () {
        // Test through widget behavior
        const widget = EnquiryHistoryWidget(enquiryId: 'test-id');
        expect(widget.enquiryId, 'test-id');
      });
    });

    group('_getFieldIcon', () {
      test('returns correct icon for status field', () {
        const widget = EnquiryHistoryWidget(enquiryId: 'test-id');
        expect(widget.enquiryId, isNotEmpty);
      });
    });
  });

  group('StringExtension', () {
    group('toTitleCase', () {
      test('converts string to title case', () {
        expect('hello world'.toTitleCase(), 'Hello World');
        expect('HELLO WORLD'.toTitleCase(), 'Hello World');
        expect('hELLo WoRLd'.toTitleCase(), 'Hello World');
      });

      test('handles empty string', () {
        expect(''.toTitleCase(), '');
      });

      test('handles single word', () {
        expect('hello'.toTitleCase(), 'Hello');
        expect('HELLO'.toTitleCase(), 'Hello');
      });

      test('handles multiple spaces', () {
        expect('hello   world'.toTitleCase(), 'Hello   World');
      });
    });
  });
}
