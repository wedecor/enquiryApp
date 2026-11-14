import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:we_decor_enquiries/core/contacts/contact_launcher.dart';
import 'package:we_decor_enquiries/core/services/review_request_service.dart';

class _FakeLauncher extends Mock implements ContactLauncher {}

void main() {
  late ReviewRequestService service;

  setUp(() {
    service = ReviewRequestService(_FakeLauncher());
  });

  group('generateReviewMessage', () {
    test('uses first name, lower-case event, link and business', () {
      final msg = service.generateReviewMessage(
        customerName: 'Neha Sharma',
        eventTypeLabel: 'Wedding',
        googleReviewLink: 'https://reviews.example/abc',
        businessName: 'WeDecor Events',
      );
      expect(msg, contains('Hi Neha,'));
      expect(msg, contains('your wedding'));
      expect(msg, contains('https://reviews.example/abc'));
      expect(msg, contains('Warm wishes from WeDecor Events.'));
      expect(msg, isNot(contains('👋')));
      expect(msg, isNot(contains('Instagram')));
      expect(msg, isNot(contains('website')));
      expect(msg, isNot(contains('@wedecorbangalore')));
    });

    test('unknown event becomes celebration; empty link uses default', () {
      final msg = service.generateReviewMessage(
        customerName: 'Aarav',
        eventTypeLabel: '  ',
        businessName: 'We Decor',
      );
      expect(msg, contains('your celebration'));
      expect(msg, contains(kDefaultGoogleReviewLink));
    });

    test('multi-word event label is lower-cased as-is', () {
      final msg = service.generateReviewMessage(
        customerName: 'Priya',
        eventTypeLabel: 'Birthday Celebration',
      );
      expect(msg, contains('your birthday celebration'));
    });
  });
}
