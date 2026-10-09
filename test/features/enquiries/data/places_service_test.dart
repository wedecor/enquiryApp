import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:we_decor_enquiries/features/enquiries/data/places_service.dart';

void main() {
  group('PlaceSuggestion.listFromResponse', () {
    test('parses an Android-style Map<Object?, Object?> response', () {
      final Map<Object?, Object?> response = {
        'suggestions': <Object?>[
          <Object?, Object?>{
            'placeId': 'ChIJ1',
            'mainText': 'Palace Grounds',
            'secondaryText': 'Jayamahal, Bengaluru, Karnataka, India',
          },
          <Object?, Object?>{'placeId': 'ChIJ2', 'mainText': 'Taj West End'},
        ],
      };
      final list = PlaceSuggestion.listFromResponse(response);
      expect(list, hasLength(2));
      expect(list[0].placeId, 'ChIJ1');
      expect(list[0].mainText, 'Palace Grounds');
      expect(list[0].secondaryText, 'Jayamahal, Bengaluru, Karnataka, India');
      expect(list[1].secondaryText, '');
    });

    test('skips entries without id or name and caps at 5', () {
      final response = {
        'suggestions': [
          {'placeId': '', 'mainText': 'No id'},
          {'placeId': 'x', 'mainText': '  '},
          'junk',
          for (var i = 0; i < 7; i++) {'placeId': 'p$i', 'mainText': 'Venue $i'},
        ],
      };
      final list = PlaceSuggestion.listFromResponse(response);
      expect(list.map((s) => s.placeId), ['p0', 'p1', 'p2', 'p3', 'p4']);
    });

    test('returns empty for null or malformed data', () {
      expect(PlaceSuggestion.listFromResponse(null), isEmpty);
      expect(PlaceSuggestion.listFromResponse('oops'), isEmpty);
      expect(PlaceSuggestion.listFromResponse({'suggestions': 'nope'}), isEmpty);
    });
  });

  group('PlaceDetails.fromResponse', () {
    test('parses a full response', () {
      final Map<Object?, Object?> response = {
        'placeId': 'ChIJ1',
        'address': 'Jayamahal Main Rd, Vasanth Nagar, Bengaluru, Karnataka 560052, India',
        'lat': 12.998,
        'lng': 77.592,
        'area': 'Vasanth Nagar',
        'city': 'Bengaluru',
      };
      final details = PlaceDetails.fromResponse(response)!;
      expect(details.placeId, 'ChIJ1');
      expect(details.address, startsWith('Jayamahal Main Rd'));
      expect(details.lat, 12.998);
      expect(details.lng, 77.592);
      expect(details.area, 'Vasanth Nagar');
      expect(details.city, 'Bengaluru');
      expect(details.isArea, isFalse);

      final place = details.toEnquiryPlace();
      expect(place.placeId, 'ChIJ1');
      expect(place.area, 'Vasanth Nagar');
    });

    test('nullable fields stay null; int coordinates become doubles', () {
      final details = PlaceDetails.fromResponse({
        'placeId': 'p',
        'address': null,
        'lat': 13,
        'lng': 77,
        'area': '',
        'city': null,
      })!;
      expect(details.address, isNull);
      expect(details.lat, 13.0);
      expect(details.area, isNull);
      expect(details.city, isNull);
    });

    test('reads isArea for an area pick', () {
      final details = PlaceDetails.fromResponse(<Object?, Object?>{
        'placeId': 'ChIJjp',
        'area': 'JP Nagar',
        'city': 'Bengaluru',
        'isArea': true,
      })!;
      expect(details.isArea, isTrue);
      expect(details.area, 'JP Nagar');
      expect(PlaceDetails.fromResponse({'placeId': 'p', 'isArea': 'yes'})!.isArea, isFalse);
    });

    test('returns null without a place id', () {
      expect(PlaceDetails.fromResponse({'address': 'x'}), isNull);
      expect(PlaceDetails.fromResponse(null), isNull);
    });
  });

  group('newPlacesSessionToken', () {
    test('is a v4 UUID string', () {
      final token = newPlacesSessionToken();
      expect(
        token,
        matches(RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$')),
      );
    });

    test('differs between calls', () {
      final random = Random(42);
      expect(newPlacesSessionToken(random: random), isNot(newPlacesSessionToken(random: random)));
    });
  });
}
