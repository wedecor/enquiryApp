import 'package:flutter_test/flutter_test.dart';
import 'package:we_decor_enquiries/core/constants/firestore_schema.dart';
import 'package:we_decor_enquiries/features/enquiries/data/review_received_service.dart';

void main() {
  test('markFields attributes to caller with server timestamps', () {
    final fields = ReviewReceivedService.markFields('uid-1');
    expect(fields[EnquiryFields.reviewReceivedBy], 'uid-1');
    expect(fields['updatedBy'], 'uid-1');
    expect(fields.containsKey(EnquiryFields.reviewReceivedAt), isTrue);
  });

  test('clearFields deletes both stamps', () {
    final fields = ReviewReceivedService.clearFields('uid-1');
    expect(fields.containsKey(EnquiryFields.reviewReceivedAt), isTrue);
    expect(fields.containsKey(EnquiryFields.reviewReceivedBy), isTrue);
    expect(fields['updatedBy'], 'uid-1');
  });
}
