import 'package:flutter_test/flutter_test.dart';
import 'package:we_decor_enquiries/core/constants/status_vocabulary.dart';
import 'package:we_decor_enquiries/core/theme/app_theme.dart';

void main() {
  group('EnquiryStatus', () {
    test('every enum value has a non-empty label and category', () {
      for (final status in EnquiryStatus.values) {
        expect(status.label.trim(), isNotEmpty);
        expect(status.category, isNotNull);
      }
    });

    test('every status has transitions entry (terminal may be empty)', () {
      for (final status in EnquiryStatus.values) {
        expect(EnquiryStatus.staffTransitions.containsKey(status), isTrue);
      }
    });

    test('staff transitions are closed over enum values', () {
      for (final entry in EnquiryStatus.staffTransitions.entries) {
        for (final target in entry.value) {
          expect(EnquiryStatus.values.contains(target), isTrue);
        }
      }
    });

    test('every legacy alias resolves to canonical status', () {
      for (final alias in EnquiryStatus.legacyAliases.keys) {
        expect(EnquiryStatus.fromValue(alias), isNotNull);
      }
    });

    test('legacy aliases map to expected canonical values', () {
      expect(EnquiryStatus.fromValue('in_progress'), EnquiryStatus.inTalks);
      expect(EnquiryStatus.fromValue('confirmed'), EnquiryStatus.approved);
      expect(EnquiryStatus.fromValue('quoted'), EnquiryStatus.quoteSent);
      expect(EnquiryStatus.fromValue('enquired'), EnquiryStatus.newEnquiry);
      expect(EnquiryStatus.fromValue('assigned'), EnquiryStatus.inTalks);
    });

    test('terminal statuses have empty transition sets', () {
      const terminal = {
        EnquiryStatus.completed,
        EnquiryStatus.cancelled,
        EnquiryStatus.closedLost,
        EnquiryStatus.notInterested,
      };
      for (final status in terminal) {
        expect(EnquiryStatus.staffTransitions[status], isEmpty);
      }
    });

    test('status color mapping resolves for all canonical values', () {
      for (final status in EnquiryStatus.values) {
        final color = AppColorScheme.statusColorFor(status.value);
        expect(color, isNotNull);
      }
    });
  });
}
