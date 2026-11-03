import 'package:flutter_test/flutter_test.dart';
import 'package:we_decor_enquiries/core/utils/name_case.dart';

void main() {
  group('tidyPersonName', () {
    test('capitalises names typed in small letters', () {
      expect(tidyPersonName('priya sharma'), 'Priya Sharma');
      expect(tidyPersonName('  mohammed   ilyas '), 'Mohammed Ilyas');
    });

    test('leaves words that already have a capital alone', () {
      expect(tidyPersonName('McKenzie'), 'McKenzie');
      expect(tidyPersonName('ABC events'), 'ABC Events');
      expect(tidyPersonName("D'Souza"), "D'Souza");
    });

    test('handles empty input and non-letters', () {
      expect(tidyPersonName(''), '');
      expect(tidyPersonName('   '), '');
      expect(tidyPersonName('9876'), '9876');
    });
  });
}
