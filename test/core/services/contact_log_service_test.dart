import 'package:flutter_test/flutter_test.dart';
import 'package:we_decor_enquiries/core/constants/firestore_schema.dart';
import 'package:we_decor_enquiries/core/services/contact_log_service.dart';

void main() {
  group('ContactLogService.contactUpdateFields', () {
    test('first contact stamps firstContactAt and bumps count', () {
      final fields = ContactLogService.contactUpdateFields(const {}, type: ContactType.whatsapp);
      expect(fields.containsKey('firstContactAt'), isTrue);
      expect(fields['firstContactEstimated'], isFalse);
      expect(fields.containsKey('lastContactAt'), isTrue);
      expect(fields.containsKey('contactCount'), isTrue);
      expect(fields.containsKey(EnquiryFields.reviewAskedAt), isFalse);
      expect(fields.containsKey(EnquiryFields.lastReviewRequestedAt), isFalse);
    });

    test('review request sets asked once and always refreshes lastReviewRequestedAt', () {
      final first = ContactLogService.contactUpdateFields(
        const {},
        type: ContactType.reviewRequest,
      );
      expect(first.containsKey(EnquiryFields.reviewAskedAt), isTrue);
      expect(first.containsKey(EnquiryFields.lastReviewRequestedAt), isTrue);

      final again = ContactLogService.contactUpdateFields({
        'reviewAskedAt': DateTime(2026, 1, 1),
        'firstContactAt': DateTime(2026, 1, 1),
      }, type: ContactType.reviewRequest);
      expect(again.containsKey(EnquiryFields.reviewAskedAt), isFalse);
      expect(again.containsKey(EnquiryFields.lastReviewRequestedAt), isTrue);
      expect(again.containsKey('firstContactAt'), isFalse);
    });
  });
}
