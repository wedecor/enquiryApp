import 'package:flutter_test/flutter_test.dart';
import 'package:we_decor_enquiries/features/enquiries/domain/enquiry_location.dart';

void main() {
  group('pickedLocationText', () {
    test('appends the area when known', () {
      expect(pickedLocationText('Palace Grounds', 'Vasanth Nagar'), 'Palace Grounds, Vasanth Nagar');
    });

    test('venue name only when area is missing or blank', () {
      expect(pickedLocationText('Palace Grounds', null), 'Palace Grounds');
      expect(pickedLocationText('Palace Grounds', '  '), 'Palace Grounds');
    });

    test('does not repeat an area already in the name (case-insensitive)', () {
      expect(pickedLocationText('Indiranagar Club', 'indiranagar'), 'Indiranagar Club');
      expect(pickedLocationText('The Leela, Old Airport Road', 'Old Airport Road'),
          'The Leela, Old Airport Road');
    });

    test('trims the inputs', () {
      expect(pickedLocationText('  Taj West End ', ' Race Course Road '),
          'Taj West End, Race Course Road');
    });
  });

  group('mapsSearchUri', () {
    test('with a place id: query + query_place_id', () {
      final uri = mapsSearchUri(
        eventLocation: 'Palace Grounds, Vasanth Nagar',
        address: 'Jayamahal Main Rd, Bengaluru',
        placeId: 'ChIJ1',
      )!;
      expect(uri.scheme, 'https');
      expect(uri.host, 'www.google.com');
      expect(uri.path, '/maps/search/');
      expect(uri.queryParameters, {
        'api': '1',
        'query': 'Palace Grounds, Vasanth Nagar',
        'query_place_id': 'ChIJ1',
      });
      expect(uri.toString(), isNot(contains(' ')));
    });

    test('falls back to the address when the location text is blank', () {
      final uri = mapsSearchUri(eventLocation: ' ', address: 'MG Road, Bengaluru', placeId: 'p')!;
      expect(uri.queryParameters['query'], 'MG Road, Bengaluru');
      expect(uri.queryParameters['query_place_id'], 'p');
    });

    test('free text only: plain search, no place id', () {
      final uri = mapsSearchUri(eventLocation: 'Bangalore')!;
      expect(uri.queryParameters, {'api': '1', 'query': 'Bangalore'});
    });

    test('encodes special characters', () {
      final uri = mapsSearchUri(eventLocation: 'A&B Hall #2')!;
      expect(uri.queryParameters['query'], 'A&B Hall #2');
      expect(uri.toString(), contains('A%26B'));
    });

    test('null when there is nothing to search', () {
      expect(mapsSearchUri(eventLocation: null), isNull);
      expect(mapsSearchUri(eventLocation: '  ', placeId: 'p'), isNull);
    });
  });

  group('EnquiryPlace', () {
    test('fromData reads stored fields', () {
      final place = EnquiryPlace.fromData({
        'eventLocation': 'Palace Grounds',
        'locationPlaceId': 'ChIJ1',
        'locationAddress': 'Jayamahal Main Rd',
        'locationLat': 12.998,
        'locationLng': 77,
        'locationArea': 'Vasanth Nagar',
        'locationCity': 'Bengaluru',
      })!;
      expect(place.placeId, 'ChIJ1');
      expect(place.address, 'Jayamahal Main Rd');
      expect(place.lat, 12.998);
      expect(place.lng, 77.0);
      expect(place.area, 'Vasanth Nagar');
      expect(place.city, 'Bengaluru');
    });

    test('fromData is null for free-text locations', () {
      expect(EnquiryPlace.fromData({'eventLocation': 'Bangalore'}), isNull);
      expect(EnquiryPlace.fromData({'locationPlaceId': ' '}), isNull);
    });

    test('toFields writes only known values', () {
      const place = EnquiryPlace(placeId: 'p', area: 'Whitefield');
      expect(place.toFields(), {'locationPlaceId': 'p', 'locationArea': 'Whitefield'});
      expect(EnquiryPlace.fieldKeys, hasLength(6));
    });
  });
}
