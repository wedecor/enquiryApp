import 'package:flutter_test/flutter_test.dart';
import 'package:we_decor_enquiries/features/enquiries/presentation/widgets/review_request_button.dart';

void main() {
  test('thankedOnLabel and alreadySentMessage use d MMM yyyy', () {
    final at = DateTime(2026, 11, 15);
    expect(ReviewRequestButton.label, 'Thank you');
    expect(ReviewRequestButton.thankedOnLabel(at), 'Thanked on 15 Nov 2026');
    expect(ReviewRequestButton.alreadySentMessage(at), 'Already sent on 15 Nov 2026. Send again?');
  });
}
