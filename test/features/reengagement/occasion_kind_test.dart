import 'package:flutter_test/flutter_test.dart';
import 'package:we_decor_enquiries/features/reengagement/domain/occasion_kind.dart';

void main() {
  group('OccasionKind.forEventType', () {
    const cases = <String, OccasionKind>{
      'Wedding': OccasionKind.weddingAnniversary,
      'Reception': OccasionKind.weddingAnniversary,
      'Haldi': OccasionKind.weddingAnniversary,
      'Mehendi': OccasionKind.weddingAnniversary,
      'Mehndi Night': OccasionKind.weddingAnniversary,
      'Sangeet': OccasionKind.weddingAnniversary,
      'Engagement': OccasionKind.weddingAnniversary,
      'Bride-to-be': OccasionKind.weddingAnniversary,
      'Groom to be': OccasionKind.weddingAnniversary,
      'Bachelorette': OccasionKind.weddingAnniversary,
      'Nikah': OccasionKind.weddingAnniversary,
      'Roka': OccasionKind.weddingAnniversary,
      'Cocktail Party': OccasionKind.weddingAnniversary,
      'Muhurtham': OccasionKind.weddingAnniversary,
      'Pre-wedding shoot': OccasionKind.weddingAnniversary,
      'Wedding Anniversary': OccasionKind.weddingAnniversary,
      'Birthday': OccasionKind.birthday,
      'First Birthday': OccasionKind.birthday,
      'BDAY': OccasionKind.birthday,
      "Baby's 1st Birthday": OccasionKind.birthday,
      '25th Anniversary': OccasionKind.anniversary,
      'Baby Shower': OccasionKind.baby,
      'Godh Bharai': OccasionKind.baby,
      'Seemantham': OccasionKind.baby,
      'Valaikappu': OccasionKind.baby,
      'Naming Ceremony': OccasionKind.baby,
      'Cradle ceremony': OccasionKind.baby,
      'Namkaran': OccasionKind.baby,
      'Housewarming': OccasionKind.home,
      'Griha Pravesh': OccasionKind.home,
      'Corporate Event': OccasionKind.corporate,
      'Office Party': OccasionKind.corporate,
      'Product Launch': OccasionKind.corporate,
      'Conference': OccasionKind.corporate,
      'Corporate cocktail': OccasionKind.corporate,
      'Diwali Party': OccasionKind.celebration,
      '': OccasionKind.celebration,
    };

    cases.forEach((label, expected) {
      test('"$label" → ${expected.value}', () {
        expect(OccasionKind.forEventType(null, label), expected);
      });
    });

    test('matches the dropdown value when the label is missing', () {
      expect(OccasionKind.forEventType('bride_to_be'), OccasionKind.weddingAnniversary);
      expect(OccasionKind.forEventType('griha_pravesh'), OccasionKind.home);
    });

    test('every event gets a kind, never null', () {
      expect(OccasionKind.forEventType(null), OccasionKind.celebration);
      expect(OccasionKind.forEventType('unknown_value', 'Something else'), OccasionKind.celebration);
    });

    test('values round-trip and match the server strings', () {
      expect(OccasionKind.values.map((k) => k.value).toList(), [
        'wedding_anniversary',
        'birthday',
        'anniversary',
        'baby',
        'home',
        'corporate',
        'celebration',
      ]);
      for (final kind in OccasionKind.values) {
        expect(OccasionKind.fromValue(kind.value), kind);
      }
      expect(OccasionKind.fromValue('nope'), isNull);
      expect(OccasionKind.fromValue(null), isNull);
    });
  });

  group('OccasionKind.ordinal', () {
    test('suffixes', () {
      expect(
        [1, 2, 3, 4, 11, 12, 13, 21, 22, 23, 101, 111, 112].map(OccasionKind.ordinal).toList(),
        ['1st', '2nd', '3rd', '4th', '11th', '12th', '13th', '21st', '22nd', '23rd', '101st', '111th', '112th'],
      );
    });
  });
}
