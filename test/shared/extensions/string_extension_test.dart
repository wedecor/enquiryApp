import 'package:flutter_test/flutter_test.dart';
import 'package:we_decor_enquiries/shared/widgets/enquiry_history_widget.dart';

void main() {
  group('StringExtension', () {
    group('toTitleCase', () {
      test('converts lowercase string to title case', () {
        expect('hello world'.toTitleCase(), 'Hello World');
        expect('hello'.toTitleCase(), 'Hello');
      });

      test('handles already title cased strings', () {
        expect('Hello World'.toTitleCase(), 'Hello World');
        expect('Hello'.toTitleCase(), 'Hello');
      });

      test('handles mixed case strings', () {
        expect('hELLo WoRLd'.toTitleCase(), 'Hello World');
        expect('HELLO WORLD'.toTitleCase(), 'Hello World');
      });

      test('handles empty string', () {
        expect(''.toTitleCase(), '');
      });

      test('handles single character', () {
        expect('h'.toTitleCase(), 'H');
        expect('H'.toTitleCase(), 'H');
      });

      test('handles strings with multiple spaces', () {
        expect('hello   world'.toTitleCase(), 'Hello   World');
        expect('  hello  world  '.toTitleCase(), '  Hello  World  ');
      });

      test('handles strings with special characters', () {
        expect('hello-world'.toTitleCase(), 'Hello-world');
        expect('hello_world'.toTitleCase(), 'Hello_world');
      });
    });
  });
}
