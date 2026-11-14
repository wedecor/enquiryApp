import 'package:flutter_test/flutter_test.dart';
import 'package:we_decor_enquiries/features/reengagement/domain/occasion_kind.dart';
import 'package:we_decor_enquiries/features/reengagement/presentation/wish_card.dart';

void main() {
  WishCardContent card(OccasionKind kind, {String? person, int nth = 5, bool enquired = false}) =>
      WishCardContent.forOccasion(
        kind: kind,
        customerName: 'Neha Sharma',
        nth: nth,
        enquired: enquired,
        person: person,
      );

  group('WishCardContent past customer', () {
    test('birthday with a person puts the name in gold, no age', () {
      final c = card(OccasionKind.birthday, person: 'Aarav');
      expect(c.named, isTrue);
      expect(c.creamLine, 'Birthday Wishes');
      expect(c.goldLines, ['Aarav']);
      expect([c.creamLine, ...c.goldLines, c.line].join(' '), isNot(contains(RegExp(r'\d'))));
    });

    test('birthday without a person greets the customer by first name', () {
      final c = card(OccasionKind.birthday);
      expect(c.named, isFalse);
      expect(c.creamLine, 'Dear Neha,');
      expect(c.goldLines, ['Birthday', 'Wishes']);
    });

    test('wedding anniversary shows the year; anniversary party does not', () {
      expect(card(OccasionKind.weddingAnniversary).goldLines, ['5th Anniversary', 'Wishes']);
      expect(card(OccasionKind.anniversary).goldLines, ['Anniversary', 'Wishes']);
      expect(card(OccasionKind.weddingAnniversary).eyebrow, 'WISHING YOU BOTH');
    });

    test('cards are timing-neutral: no "Happy …" (reads as today), no date', () {
      for (final kind in OccasionKind.values) {
        final c = card(kind, person: 'Aarav');
        final all = [c.eyebrow, c.creamLine, ...c.goldLines, c.line].join(' ');
        expect(all, isNot(contains('Happy')), reason: kind.value);
        expect(
          all,
          isNot(contains(RegExp(r'\b(JAN|FEB|MAR|APR|MAY|JUN|JUL|AUG|SEP|OCT|NOV|DEC)\b'))),
          reason: kind.value,
        );
      }
    });

    test('only one name: the occasion person if set, else the customer', () {
      expect(card(OccasionKind.weddingAnniversary).creamLine, 'Dear Neha,');
      expect(
        card(OccasionKind.weddingAnniversary, person: 'Priya & Rahul').creamLine,
        'Dear Priya & Rahul,',
      );
    });

    test('home counts years; nth below 1 reads 1st', () {
      expect(card(OccasionKind.home, nth: 2).goldLines.first, '2nd Year');
      expect(card(OccasionKind.home, nth: 0).goldLines.first, '1st Year');
    });

    test('no card text sells', () {
      for (final kind in OccasionKind.values) {
        final c = card(kind, person: 'Aarav');
        final all = [c.eyebrow, c.creamLine, ...c.goldLines, c.line].join(' ').toLowerCase();
        expect(all, isNot(contains('decor')), reason: kind.value);
        expect(c.goldLines, isNotEmpty, reason: kind.value);
      }
    });
  });

  group('WishCardContent enquired only', () {
    test('every non-corporate kind uses the gentle THINKING OF YOU card', () {
      for (final kind in OccasionKind.values.where((k) => k != OccasionKind.corporate)) {
        final c = card(kind, enquired: true, nth: 5, person: 'Aarav');
        expect(c.eyebrow, 'THINKING OF YOU', reason: kind.value);
        expect(c.creamLine, 'Dear Aarav,', reason: kind.value);
        expect(c.goldLines, ['Warm', 'Wishes'], reason: kind.value);
        expect(c.line, 'Wishing you a happy year ahead.', reason: kind.value);
        expect(c.named, isFalse, reason: kind.value);
        final all = [c.eyebrow, c.creamLine, ...c.goldLines, c.line].join(' ');
        expect(all, isNot(contains(RegExp(r'\d'))), reason: kind.value);
        expect(all.toLowerCase(), isNot(contains('anniversary')), reason: kind.value);
      }
    });

    test('enquired cream line falls back to customer first name', () {
      final c = card(OccasionKind.home, enquired: true);
      expect(c.creamLine, 'Dear Neha,');
    });

    test('corporate enquired keeps the past-customer corporate wording', () {
      final c = card(OccasionKind.corporate, enquired: true, person: 'Aarav');
      expect(c.eyebrow, 'THINKING OF YOU');
      expect(c.creamLine, 'Dear Aarav,');
      expect(c.goldLines, ['Warm', 'Wishes']);
      expect(c.line, 'Hope this time of year is a lovely one.');
    });
  });
}
