import 'package:flutter_test/flutter_test.dart';
import 'package:we_decor_enquiries/features/reengagement/domain/occasion_kind.dart';
import 'package:we_decor_enquiries/features/reengagement/presentation/customer_card.dart';

void main() {
  CustomerCardContent card(
    OccasionKind kind, {
    String? person,
    int nth = 5,
    bool enquired = false,
  }) => CustomerCardContent.forOccasion(
    kind: kind,
    customerName: 'Neha Sharma',
    nth: nth,
    enquired: enquired,
    person: person,
  );

  group('CustomerCardContent past customer', () {
    test('birthday with a person puts the name in gold', () {
      final c = card(OccasionKind.birthday, person: 'Aarav');
      expect(c.greeting, 'Birthday Wishes');
      expect(c.headlineLines, ['Aarav']);
      expect(c.bodyLine, 'A wonderful year ahead.');
    });

    test('birthday without a person greets the customer by first name', () {
      final c = card(OccasionKind.birthday);
      expect(c.greeting, 'Dear Neha,');
      expect(c.headlineLines, ['Birthday', 'Wishes']);
    });

    test('wedding anniversary shows the year as a word; anniversary party does not', () {
      expect(card(OccasionKind.weddingAnniversary).headlineLines, ['Fifth Anniversary', 'Wishes']);
      expect(card(OccasionKind.anniversary).headlineLines, ['Anniversary', 'Wishes']);
      expect(card(OccasionKind.weddingAnniversary).eyebrow, 'WISHING YOU BOTH');
    });

    test('home counts years as words; nth below 1 reads First', () {
      expect(card(OccasionKind.home, nth: 2).headlineLines.first, 'Second Year');
      expect(card(OccasionKind.home, nth: 0).headlineLines.first, 'First Year');
    });

    test('corporate uses WARM WISHES', () {
      final c = card(OccasionKind.corporate);
      expect(c.eyebrow, 'WARM WISHES');
      expect(c.bodyLine, 'From all of us at We Decor.');
    });
  });

  group('CustomerCardContent enquired only', () {
    test('never claims the event happened or shows an ordinal', () {
      for (final kind in OccasionKind.values) {
        final c = card(kind, enquired: true, nth: 5, person: 'Aarav');
        final all = [c.eyebrow, c.greeting, ...c.headlineLines, c.bodyLine].join(' ');
        expect(all.toLowerCase(), isNot(contains('it was a joy')), reason: kind.value);
        expect(
          all,
          isNot(contains(RegExp(r'\b(First|Second|Third|Fourth|Fifth|1st|2nd|5th)\b'))),
          reason: kind.value,
        );
        expect(c.headlineLines, ['Warm', 'Wishes'], reason: kind.value);
      }
    });

    test('celebration enquired body matches the soft wish', () {
      final c = card(OccasionKind.celebration, enquired: true);
      expect(c.eyebrow, 'THINKING OF YOU');
      expect(c.bodyLine, 'Wishing you a happy year ahead.');
    });

    test('corporate enquired matches past-customer corporate wording', () {
      final c = card(OccasionKind.corporate, enquired: true);
      expect(c.eyebrow, 'WARM WISHES');
      expect(c.bodyLine, 'From all of us at We Decor.');
    });
  });

  group('CustomerCardContent thankYou', () {
    test('uses gratitude eyebrow, Dear first name, single Thank You headline', () {
      final c = CustomerCardContent.thankYou(customerName: 'Neha Sharma');
      expect(c.eyebrow, 'WITH GRATITUDE');
      expect(c.greeting, 'Dear Neha,');
      expect(c.headlineLines, ['Thank You']);
      expect(c.bodyLine, 'It was a joy to be part of your celebration.');
    });

    test('uses event type in the body and null greeting when name is blank', () {
      final wedding = CustomerCardContent.thankYou(
        customerName: 'Ayesha Khan',
        eventTypeLabel: 'Wedding',
      );
      expect(wedding.bodyLine, 'It was a joy to be part of your wedding.');
      final anon = CustomerCardContent.thankYou(customerName: '  ');
      expect(anon.greeting, isNull);
    });
  });
}
