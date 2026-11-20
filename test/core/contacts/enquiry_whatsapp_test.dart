import 'package:flutter_test/flutter_test.dart';
import 'package:we_decor_enquiries/core/contacts/enquiry_whatsapp.dart';

void main() {
  group('EnquiryWhatsApp.isFirstContact', () {
    test('true when never contacted', () {
      expect(EnquiryWhatsApp.isFirstContact(), isTrue);
      expect(EnquiryWhatsApp.isFirstContactFrom({}), isTrue);
      expect(EnquiryWhatsApp.isFirstContactFrom({'contactCount': 0}), isTrue);
    });

    test('false when firstContactAt or contactCount set', () {
      expect(EnquiryWhatsApp.isFirstContact(firstContactAt: DateTime(2026, 1, 1)), isFalse);
      expect(EnquiryWhatsApp.isFirstContact(contactCount: 2), isFalse);
      expect(
        EnquiryWhatsApp.isFirstContactFrom({
          'firstContactAt': DateTime(2026, 1, 1),
          'contactCount': 1,
        }),
        isFalse,
      );
    });
  });

  group('EnquiryWhatsApp.message', () {
    test('first contact introduces We Decor with first name and event', () {
      final msg = EnquiryWhatsApp.message(
        customerName: 'Priya Sharma',
        firstContact: true,
        eventTypeLabel: 'Wedding',
        eventDate: DateTime(2026, 1, 12),
      );
      expect(msg, contains('Hi Priya, greetings from We Decor.'));
      expect(msg, contains('wedding enquiry for 12 Jan'));
      expect(msg, contains('How can we help you today?'));
      expect(msg.toLowerCase(), isNot(contains('following up')));
    });

    test('follow-up is a short check-in', () {
      final msg = EnquiryWhatsApp.message(
        customerName: 'Ayesha Khan',
        firstContact: false,
        eventTypeLabel: 'Birthday',
      );
      expect(msg, contains('Hi Ayesha, greetings from We Decor.'));
      expect(msg, contains('Just checking in on your birthday enquiry'));
      expect(msg, contains('happy to answer any questions'));
    });
  });
}
