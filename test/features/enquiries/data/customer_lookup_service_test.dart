import 'package:flutter_test/flutter_test.dart';
import 'package:we_decor_enquiries/features/enquiries/data/customer_lookup_service.dart';

void main() {
  group('CustomerLookupResult.fromResponse', () {
    test('parses a full response (Android-style Map<Object?, Object?>)', () {
      final Map<Object?, Object?> response = {
        'customer': <Object?, Object?>{
          'name': 'Asha Rao',
          'email': 'asha@example.com',
          'whatsappNumber': null,
          'phone': '+91 98765 43210',
        },
        'events': <Object?>[
          <Object?, Object?>{
            'id': 'e1',
            'eventType': 'Birthday',
            'eventDate': '2026-03-14T18:30:00.000Z',
            'status': 'in_talks',
            'statusLabel': 'In Talks',
            'assignedToName': 'Ravi',
            'assignedToMe': true,
            'createdAt': '2026-02-01T10:00:00.000Z',
            'isOpen': true,
          },
          <Object?, Object?>{
            'id': 'e2',
            'eventType': 'Anniversary',
            'eventDate': null,
            'status': 'completed',
            'statusLabel': 'Completed',
            'assignedToName': null,
            'assignedToMe': false,
            'createdAt': null,
            'isOpen': false,
          },
        ],
        'totalEvents': 2,
        'openEvents': 1,
      };

      final result = CustomerLookupResult.fromResponse(response);

      expect(result.isKnownCustomer, isTrue);
      expect(result.customer!.name, 'Asha Rao');
      expect(result.customer!.email, 'asha@example.com');
      expect(result.customer!.whatsappNumber, isNull);
      expect(result.totalEvents, 2);
      expect(result.openEvents, 1);
      expect(result.events, hasLength(2));

      final first = result.events.first;
      expect(first.id, 'e1');
      expect(first.eventType, 'Birthday');
      expect(first.eventDate, DateTime.utc(2026, 3, 14, 18, 30).toLocal());
      expect(first.status, 'in_talks');
      expect(first.isOpen, isTrue);
      expect(first.assignedToName, 'Ravi');
      expect(first.canOpen(isAdmin: false), isTrue);

      final second = result.events.last;
      expect(second.eventDate, isNull);
      expect(second.isAssigned, isFalse);
      expect(second.canOpen(isAdmin: false), isFalse);
      expect(second.canOpen(isAdmin: true), isTrue);

      expect(result.openEventList.map((e) => e.id), ['e1']);
    });

    test('no customer → empty result', () {
      final result = CustomerLookupResult.fromResponse(<String, dynamic>{
        'customer': null,
        'events': <dynamic>[],
        'totalEvents': 0,
        'openEvents': 0,
      });
      expect(result.isKnownCustomer, isFalse);
      expect(result.events, isEmpty);
      expect(result.totalEvents, 0);
    });

    test('tolerates malformed data', () {
      expect(CustomerLookupResult.fromResponse(null).isKnownCustomer, isFalse);
      expect(CustomerLookupResult.fromResponse('oops').events, isEmpty);

      final result = CustomerLookupResult.fromResponse(<String, dynamic>{
        'customer': <String, dynamic>{'name': '  '},
        'events': <dynamic>[
          'not a map',
          <String, dynamic>{'eventType': 'No id'},
          <String, dynamic>{'id': 'ok', 'eventDate': 'not-a-date'},
        ],
      });
      expect(result.customer!.name, 'Customer');
      expect(result.events.map((e) => e.id), ['ok']);
      expect(result.events.single.eventType, 'Event');
      expect(result.events.single.statusLabel, 'Unknown');
      expect(result.events.single.eventDate, isNull);
      // Counts fall back to the parsed list when missing.
      expect(result.totalEvents, 1);
      expect(result.openEvents, 0);
    });
  });
}
