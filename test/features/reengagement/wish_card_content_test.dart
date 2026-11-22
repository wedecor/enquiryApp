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
    test('birthday with a person keeps Birthday coming up; name in body', () {
      final c = card(OccasionKind.birthday, person: 'Aarav');
      expect(c.eyebrow, 'WARM WISHES');
      expect(c.greeting, 'Dear Neha,');
      expect(c.headlineLines, ['Birthday coming up']);
      expect(c.bodyLine, 'Wishing Aarav a wonderful celebration ahead.');
    });

    test('birthday without a person greets the customer by first name', () {
      final c = card(OccasionKind.birthday);
      expect(c.greeting, 'Dear Neha,');
      expect(c.headlineLines, ['Birthday coming up']);
      expect(c.bodyLine, 'Wishing you a wonderful celebration ahead.');
    });

    test('wedding and anniversary share ahead-of-day copy; no year number or Happy', () {
      for (final kind in [OccasionKind.weddingAnniversary, OccasionKind.anniversary]) {
        final c = card(kind, nth: 5);
        expect(c.headlineLines, ['Anniversary coming up'], reason: kind.value);
        expect(c.bodyLine, 'Wishing you both a wonderful celebration ahead.', reason: kind.value);
        expect(c.eyebrow, 'WARM WISHES', reason: kind.value);
        final all = [...c.headlineLines, c.bodyLine].join(' ');
        expect(all.toLowerCase(), isNot(contains('happy anniversary')), reason: kind.value);
        expect(all, isNot(contains(RegExp(r'\b(First|Fifth|5th|\d+)\b'))), reason: kind.value);
      }
    });

    test('home is ahead-of-day without year count', () {
      final c = card(OccasionKind.home, nth: 2);
      expect(c.headlineLines, ['Home anniversary coming up']);
      expect(c.bodyLine, 'Wishing you many happy years ahead.');
    });

    test('baby uses Celebration coming up', () {
      final c = card(OccasionKind.baby);
      expect(c.headlineLines, ['Celebration coming up']);
      expect(c.bodyLine, 'Warm wishes for your little one.');
    });

    test('corporate uses default warm wish body', () {
      final c = card(OccasionKind.corporate);
      expect(c.eyebrow, 'WARM WISHES');
      expect(c.headlineLines, ['Warm wishes']);
      expect(c.bodyLine, 'From all of us at We Decor.');
    });

    test('celebration wishes a happy year ahead', () {
      final c = card(OccasionKind.celebration);
      expect(c.headlineLines, ['Warm wishes']);
      expect(c.bodyLine, 'Wishing you a happy year ahead.');
    });
  });

  group('CustomerCardContent enquired only', () {
    test('never claims the event happened, day-of Happy, or an ordinal', () {
      for (final kind in OccasionKind.values) {
        final c = card(kind, enquired: true, nth: 5, person: 'Aarav');
        final all = [c.eyebrow, c.greeting, ...c.headlineLines, c.bodyLine].join(' ');
        expect(all.toLowerCase(), isNot(contains('it was a joy')), reason: kind.value);
        expect(all.toLowerCase(), isNot(contains('happy anniversary')), reason: kind.value);
        expect(all.toLowerCase(), isNot(contains('happy birthday')), reason: kind.value);
        expect(
          all,
          isNot(contains(RegExp(r'\b(First|Second|Third|Fourth|Fifth|1st|2nd|5th)\b'))),
          reason: kind.value,
        );
        expect(c.eyebrow, 'WARM WISHES', reason: kind.value);
      }
    });

    test('celebration enquired body matches ahead-of-year wish', () {
      final c = card(OccasionKind.celebration, enquired: true);
      expect(c.eyebrow, 'WARM WISHES');
      expect(c.bodyLine, 'Wishing you a happy year ahead.');
    });

    test('corporate enquired matches past-customer corporate wording', () {
      final c = card(OccasionKind.corporate, enquired: true);
      expect(c.eyebrow, 'WARM WISHES');
      expect(c.bodyLine, 'From all of us at We Decor.');
    });

    test('wedding enquired uses Anniversary coming up without a number', () {
      final c = card(OccasionKind.weddingAnniversary, enquired: true, nth: 10);
      expect(c.headlineLines, ['Anniversary coming up']);
      expect(c.bodyLine, 'Wishing you both a wonderful celebration ahead.');
    });
  });

  group('CustomerCardContent thankYou', () {
    test('uses thank-you eyebrow, Dear first name, joy headline', () {
      final c = CustomerCardContent.thankYou(customerName: 'Neha Sharma');
      expect(c.eyebrow, 'THANK YOU');
      expect(c.greeting, 'Dear Neha,');
      expect(c.headlineLines, ['It was a joy']);
      expect(c.bodyLine, 'Being part of your celebration.');
    });

    test('uses event type in the body and null greeting when name is blank', () {
      final wedding = CustomerCardContent.thankYou(
        customerName: 'Ayesha Khan',
        eventTypeLabel: 'Wedding',
      );
      expect(wedding.bodyLine, 'Being part of your wedding.');
      final anon = CustomerCardContent.thankYou(customerName: '  ');
      expect(anon.greeting, isNull);
    });
  });
}
