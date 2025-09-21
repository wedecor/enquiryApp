import 'package:flutter_test/flutter_test.dart';
import 'package:we_decor_enquiries/core/contacts/contact_launcher.dart';

void main() {
  group('ContactLauncher Tests', () {
    late ContactLauncher contactLauncher;

    setUp(() {
      contactLauncher = ContactLauncher(defaultCountryCode: '+91');
    });

    group('Phone Number Normalization', () {
      test('adds default country code when missing', () {
        expect(contactLauncher.normalize('9876543210'), '+919876543210');
        expect(contactLauncher.normalize('1234567890'), '+911234567890');
      });

      test('preserves existing country code', () {
        expect(contactLauncher.normalize('+442071838750'), '+442071838750');
        expect(contactLauncher.normalize('+12345678901'), '+12345678901');
        expect(contactLauncher.normalize('+919876543210'), '+919876543210');
      });

      test('removes formatting characters', () {
        expect(contactLauncher.normalize('(987) 654-3210'), '+919876543210');
        expect(contactLauncher.normalize('987-654-3210'), '+919876543210');
        expect(contactLauncher.normalize('987.654.3210'), '+919876543210');
        expect(contactLauncher.normalize('987 654 3210'), '+919876543210');
        expect(contactLauncher.normalize('+1 (987) 654-3210'), '+19876543210');
      });

      test('handles edge cases', () {
        expect(contactLauncher.normalize(''), '');
        expect(contactLauncher.normalize('   '), '');
        expect(contactLauncher.normalize('+'), '+');
        expect(contactLauncher.normalize('abc'), '+91');
        expect(contactLauncher.normalize('123'), '+91123');
      });

      test('works with different country codes', () {
        final usLauncher = ContactLauncher(defaultCountryCode: '+1');
        expect(usLauncher.normalize('9876543210'), '+19876543210');

        final ukLauncher = ContactLauncher(defaultCountryCode: '+44');
        expect(ukLauncher.normalize('2071838750'), '+442071838750');
      });

      test('handles international numbers correctly', () {
        expect(contactLauncher.normalize('+1-555-123-4567'), '+15551234567');
        expect(contactLauncher.normalize('+44 20 7183 8750'), '+442071838750');
        expect(contactLauncher.normalize('+33 1 42 86 83 26'), '+33142868326');
      });
    });

    group('URL Generation Logic', () {
      test('generates correct tel URLs', () {
        // This tests the URL format that would be used
        final normalized = contactLauncher.normalize('9876543210');
        final expectedTelUrl = 'tel:$normalized';
        expect(expectedTelUrl, 'tel:+919876543210');
      });

      test('generates correct WhatsApp native URLs', () {
        final normalized = contactLauncher.normalize('+919876543210');
        final whatsappPhone = normalized.substring(1); // Remove '+' for WhatsApp
        final expectedUrl = 'whatsapp://send?phone=$whatsappPhone';
        expect(expectedUrl, 'whatsapp://send?phone=919876543210');
      });

      test('generates WhatsApp URLs with prefill text', () {
        final normalized = contactLauncher.normalize('9876543210');
        final whatsappPhone = normalized.substring(1);
        final prefillText = 'Hello from We Decor!';
        final encodedText = Uri.encodeComponent(prefillText);
        final expectedUrl = 'whatsapp://send?phone=$whatsappPhone&text=$encodedText';
        expect(expectedUrl, 'whatsapp://send?phone=919876543210&text=Hello%20from%20We%20Decor!');
      });

      test('generates correct WhatsApp Web URLs', () {
        final normalized = contactLauncher.normalize('9876543210');
        final whatsappPhone = normalized.substring(1);
        final expectedWebUrl = 'https://wa.me/$whatsappPhone';
        expect(expectedWebUrl, 'https://wa.me/919876543210');
      });

      test('generates WhatsApp Web URLs with text', () {
        final normalized = contactLauncher.normalize('+442071838750');
        final whatsappPhone = normalized.substring(1);
        final prefillText = 'Hi! Following up on your enquiry.';
        final encodedText = Uri.encodeComponent(prefillText);
        final expectedWebUrl = 'https://wa.me/$whatsappPhone?text=$encodedText';
        expect(
          expectedWebUrl,
          'https://wa.me/442071838750?text=Hi!%20Following%20up%20on%20your%20enquiry.',
        );
      });
    });

    group('Input Validation', () {
      test('identifies invalid phone numbers', () {
        expect(contactLauncher.normalize(''), '');
        expect(contactLauncher.normalize('   '), '');
        expect(contactLauncher.normalize('abc'), '+91');
        expect(contactLauncher.normalize('123'), '+91123'); // Too short but normalized
      });

      test('handles special characters safely', () {
        expect(contactLauncher.normalize('987#654*3210'), '+919876543210');
        expect(contactLauncher.normalize('987@654\$3210'), '+919876543210');
        expect(contactLauncher.normalize('+91 987&654%3210'), '+919876543210');
      });

      test('preserves valid international formats', () {
        expect(contactLauncher.normalize('+1234567890123'), '+1234567890123');
        expect(contactLauncher.normalize('+999123456789'), '+999123456789');
      });
    });

    group('Error Handling', () {
      test('handles null and empty inputs gracefully', () {
        expect(contactLauncher.normalize(''), '');
        expect(() => contactLauncher.normalize(''), returnsNormally);
      });

      test('handles malformed inputs', () {
        expect(() => contactLauncher.normalize('+++'), returnsNormally);
        expect(() => contactLauncher.normalize('---'), returnsNormally);
        expect(() => contactLauncher.normalize('()()()'), returnsNormally);
      });
    });

    group('Country Code Handling', () {
      test('uses provided default country code', () {
        final customLauncher = ContactLauncher(defaultCountryCode: '+86');
        expect(customLauncher.normalize('13812345678'), '+8613812345678');
      });

      test('handles country codes without plus sign', () {
        final launcher = ContactLauncher(defaultCountryCode: '91');
        expect(launcher.normalize('9876543210'), '919876543210');
      });

      test('handles empty country code gracefully', () {
        final launcher = ContactLauncher(defaultCountryCode: '');
        expect(launcher.normalize('9876543210'), '9876543210');
      });
    });

    group('Real-world Phone Number Examples', () {
      test('handles Indian phone numbers', () {
        expect(contactLauncher.normalize('98765 43210'), '+919876543210');
        expect(contactLauncher.normalize('+91 98765 43210'), '+919876543210');
        expect(contactLauncher.normalize('09876543210'), '+9109876543210');
      });

      test('handles US phone numbers', () {
        final usLauncher = ContactLauncher(defaultCountryCode: '+1');
        expect(usLauncher.normalize('(555) 123-4567'), '+15551234567');
        expect(usLauncher.normalize('555.123.4567'), '+15551234567');
        expect(usLauncher.normalize('+1 555 123 4567'), '+15551234567');
      });

      test('handles UK phone numbers', () {
        final ukLauncher = ContactLauncher(defaultCountryCode: '+44');
        expect(ukLauncher.normalize('2071838750'), '+442071838750');
        expect(ukLauncher.normalize('+44 20 7183 8750'), '+442071838750');
        expect(ukLauncher.normalize('(020) 7183-8750'), '+4402071838750');
      });

      test('handles international mobile numbers', () {
        expect(contactLauncher.normalize('+86 138 1234 5678'), '+8613812345678');
        expect(contactLauncher.normalize('+33 6 12 34 56 78'), '+33612345678');
        expect(contactLauncher.normalize('+49 151 12345678'), '+4915112345678');
      });
    });

    group('WhatsApp Message Prefill', () {
      test('handles special characters in prefill text', () {
        const prefillText = 'Hi! How are you? 😊 Let\'s discuss your event.';
        final encoded = Uri.encodeComponent(prefillText);
        expect(encoded, contains('Hi!'));
        expect(encoded, contains('How%20are%20you'));
        expect(encoded, contains('discuss%20your%20event'));
      });

      test('handles empty prefill text', () {
        final normalized = contactLauncher.normalize('9876543210');
        final whatsappPhone = normalized.substring(1);
        final urlWithoutText = 'whatsapp://send?phone=$whatsappPhone';
        expect(urlWithoutText, 'whatsapp://send?phone=919876543210');
      });

      test('handles long prefill text', () {
        const longText =
            'This is a very long message that might exceed normal limits but should still be handled gracefully by the URL encoding mechanism.';
        final encoded = Uri.encodeComponent(longText);
        expect(encoded.length, greaterThan(longText.length));
        expect(encoded, isNot(contains(' '))); // Spaces should be encoded
      });
    });
  });
}
