import 'package:flutter_test/flutter_test.dart';
import 'package:we_decor_enquiries/features/enquiries/domain/enquiry_location.dart';

void main() {
  group('pickedLocationText', () {
    test('appends the area when known', () {
      expect(
        pickedLocationText('Palace Grounds', 'Vasanth Nagar'),
        'Palace Grounds, Vasanth Nagar',
      );
    });

    test('venue name only when area is missing or blank', () {
      expect(pickedLocationText('Palace Grounds', null), 'Palace Grounds');
      expect(pickedLocationText('Palace Grounds', '  '), 'Palace Grounds');
    });

    test('does not repeat an area already in the name (case-insensitive)', () {
      expect(pickedLocationText('Indiranagar Club', 'indiranagar'), 'Indiranagar Club');
      expect(
        pickedLocationText('The Leela, Old Airport Road', 'Old Airport Road'),
        'The Leela, Old Airport Road',
      );
    });

    test('area pick is just the area name (no "JP Nagar, JP Nagar")', () {
      expect(pickedLocationText('JP Nagar', 'JP Nagar', isArea: true), 'JP Nagar');
      expect(pickedLocationText('Whitefield', 'Whitefield', isArea: true), 'Whitefield');
      expect(pickedLocationText(' J. P. Nagar ', 'JP Nagar', isArea: true), 'J. P. Nagar');
      expect(pickedLocationText('', 'JP Nagar', isArea: true), 'JP Nagar');
    });

    test('venue name matching the area with different punctuation is not repeated', () {
      expect(pickedLocationText('J. P. Nagar Club', 'JP Nagar'), 'J. P. Nagar Club');
      expect(pickedLocationText('JP Nagar', 'JP Nagar'), 'JP Nagar');
    });

    test('trims the inputs', () {
      expect(
        pickedLocationText('  Taj West End ', ' Race Course Road '),
        'Taj West End, Race Course Road',
      );
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

  group('isVagueLocation', () {
    test('city / state / country names are vague', () {
      for (final text in [
        'Bangalore',
        'bengaluru',
        'Banglore',
        'Bangaluru',
        'BLR',
        'Bangalore City',
        'Bengaluru city',
        'Bangalore Urban',
        'bengaluru urban',
        'Karnataka',
        'India',
        'Bangalore, Karnataka',
        'Bengaluru - Karnataka.',
        '  bangalore.  ',
        'Bangalore\u00A0Urban',
      ]) {
        expect(isVagueLocation(text), isTrue, reason: text);
      }
    });

    test('empty, null and punctuation-only are vague', () {
      expect(isVagueLocation(null), isTrue);
      expect(isVagueLocation(''), isTrue);
      expect(isVagueLocation('   '), isTrue);
      expect(isVagueLocation(' , . - '), isTrue);
    });

    test('areas, venues and anything more specific are not vague', () {
      for (final text in [
        'JP Nagar',
        'Whitefield',
        'Whitefield, Bangalore',
        'Bangalore Palace',
        'Palace Grounds, Vasanth Nagar',
        'Bangalore 560078',
        'Mysore',
      ]) {
        expect(isVagueLocation(text), isFalse, reason: text);
      }
    });

    test('the list has the 13 agreed names (mirrored in firestore.rules)', () {
      expect(vagueLocationNames, hasLength(13));
      for (final name in vagueLocationNames) {
        expect(isVagueLocation(name), isTrue, reason: name);
      }
    });
  });

  group('isLocationKnown', () {
    test('known from a specific location text', () {
      expect(isLocationKnown(eventLocation: 'JP Nagar'), isTrue);
      expect(isLocationKnown(area: null, eventLocation: 'Taj West End'), isTrue);
    });

    test('known from a stored area even when the text is the city', () {
      expect(isLocationKnown(area: 'Indiranagar', eventLocation: 'Bangalore'), isTrue);
    });

    test('unknown when both are empty or only the city', () {
      expect(isLocationKnown(), isFalse);
      expect(isLocationKnown(eventLocation: 'Bangalore'), isFalse);
      expect(isLocationKnown(area: ' ', eventLocation: ''), isFalse);
      expect(isLocationKnown(area: 'Bengaluru', eventLocation: 'BLR'), isFalse);
    });

    test('isLocationKnownInData reads locationArea and eventLocation', () {
      expect(isLocationKnownInData({'eventLocation': 'Bangalore'}), isFalse);
      expect(isLocationKnownInData({}), isFalse);
      expect(isLocationKnownInData({'eventLocation': 'HSR Layout'}), isTrue);
      expect(
        isLocationKnownInData({'eventLocation': 'Bangalore', 'locationArea': 'HSR Layout'}),
        isTrue,
      );
      expect(isLocationKnownInData({'location': 'Koramangala'}), isTrue);
      expect(isLocationKnownInData({'eventLocation': 42, 'locationArea': 7}), isFalse);
    });

    test('isApprovedLocationPending only for approved enquiries', () {
      expect(
        isApprovedLocationPending(statusIsApproved: true, data: {'eventLocation': 'Bangalore'}),
        isTrue,
      );
      expect(
        isApprovedLocationPending(statusIsApproved: false, data: {'eventLocation': 'Bangalore'}),
        isFalse,
      );
      expect(
        isApprovedLocationPending(statusIsApproved: true, data: {'eventLocation': 'JP Nagar'}),
        isFalse,
      );
    });
  });

  group('approve sheet', () {
    test('Save & approve is disabled until the location passes the rule', () {
      expect(canSaveApprovalLocation(text: ''), isFalse);
      expect(canSaveApprovalLocation(text: 'Bangalore'), isFalse);
      expect(canSaveApprovalLocation(text: 'Bengaluru, Karnataka'), isFalse);
      expect(canSaveApprovalLocation(text: 'JP Nagar'), isTrue);
      expect(canSaveApprovalLocation(text: 'Whitefield, Bangalore'), isTrue);
    });

    test('a picked place with an area enables Save', () {
      const place = EnquiryPlace(placeId: 'p', area: 'JP Nagar');
      expect(canSaveApprovalLocation(text: 'JP Nagar', place: place), isTrue);
      const cityOnly = EnquiryPlace(placeId: 'c', city: 'Bengaluru');
      expect(canSaveApprovalLocation(text: 'Bengaluru', place: cityOnly), isFalse);
    });

    test('typed location is also stored as the area', () {
      expect(approvalLocationFields(text: '  HSR Layout '), {
        'eventLocation': 'HSR Layout',
        'locationArea': 'HSR Layout',
      });
    });

    test('picked place writes the text plus its place fields', () {
      const place = EnquiryPlace(
        placeId: 'ChIJ1',
        address: 'Jayamahal Main Rd, Vasanth Nagar',
        area: 'Vasanth Nagar',
        city: 'Bengaluru',
      );
      expect(approvalLocationFields(text: 'Palace Grounds, Vasanth Nagar', place: place), {
        'eventLocation': 'Palace Grounds, Vasanth Nagar',
        'locationPlaceId': 'ChIJ1',
        'locationAddress': 'Jayamahal Main Rd, Vasanth Nagar',
        'locationArea': 'Vasanth Nagar',
        'locationCity': 'Bengaluru',
      });
    });
  });
}
