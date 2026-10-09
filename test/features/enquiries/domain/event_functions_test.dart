import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:we_decor_enquiries/features/enquiries/domain/event_functions.dart';

void main() {
  Map<String, Object> fn(
    String id,
    String type,
    DateTime date, {
    String? time,
    String? location,
    String? area,
    String? placeId,
    String? notes,
  }) => {
    'id': id,
    'eventType': type,
    'eventTypeLabel': type[0].toUpperCase() + type.substring(1),
    'date': Timestamp.fromDate(date),
    if (time != null) 'time': time,
    if (location != null) 'location': location,
    if (area != null) 'locationArea': area,
    if (placeId != null) 'locationPlaceId': placeId,
    if (notes != null) 'notes': notes,
  };

  final weddingBooking = <String, dynamic>{
    'eventTypeValue': 'wedding',
    'eventDate': Timestamp.fromDate(DateTime(2026, 12, 13)),
    'functions': [
      fn('r', 'reception', DateTime(2026, 12, 13), location: 'Taj West End'),
      fn('h', 'haldi', DateTime(2026, 12, 10), location: 'Home, JP Nagar', area: 'JP Nagar'),
      fn('w', 'wedding', DateTime(2026, 12, 12), time: '19:00', location: 'Palace Grounds'),
      fn('m', 'mehendi', DateTime(2026, 12, 11)),
      {'id': 'broken'}, // no type / date → ignored
    ],
  };

  group('functionsOf', () {
    test('legacy single-event enquiry → one synthesized function', () {
      final functions = functionsOf({
        'eventType': 'birthday',
        'eventTypeValue': 'birthday',
        'eventTypeLabel': 'Birthday',
        'eventDate': Timestamp.fromDate(DateTime(2026, 3, 5, 15)),
        'eventLocation': 'Leela Palace',
        'locationArea': 'HAL',
        'locationPlaceId': 'abc',
      });
      expect(functions, hasLength(1));
      final f = functions.single;
      expect(f.id, EventFunction.legacyId);
      expect(f.eventType, 'birthday');
      expect(f.label, 'Birthday');
      expect(f.day, DateTime(2026, 3, 5));
      expect(f.location, 'Leela Palace');
      expect(f.locationArea, 'HAL');
      expect(f.locationPlaceId, 'abc');
      expect(f.time, isNull);
    });

    test('legacy without a date (or the 1970 placeholder) → none', () {
      expect(functionsOf({'eventType': 'wedding'}), isEmpty);
      expect(
        functionsOf({'eventType': 'wedding', 'eventDate': Timestamp.fromDate(DateTime(1970))}),
        isEmpty,
      );
    });

    test('empty array falls back to the legacy fields', () {
      final functions = functionsOf({
        'functions': <Object>[],
        'eventType': 'wedding',
        'eventDate': Timestamp.fromDate(DateTime(2026, 1, 2)),
      });
      expect(functions.single.eventType, 'wedding');
    });

    test('multi: parsed, invalid entries skipped, ordered by date then time', () {
      final functions = functionsOf(weddingBooking);
      expect(functions.map((f) => f.id), ['h', 'm', 'w', 'r']);
      expect(functions[2].time, '19:00');
      expect(hasMultipleFunctions(weddingBooking), isTrue);
    });

    test('same day: untimed first, then by time', () {
      final functions = functionsOf({
        'functions': [
          fn('b', 'reception', DateTime(2026, 5, 1), time: '19:30'),
          fn('a', 'wedding', DateTime(2026, 5, 1), time: '10:00'),
          fn('c', 'haldi', DateTime(2026, 5, 1)),
        ],
      });
      expect(functions.map((f) => f.id), ['c', 'a', 'b']);
    });

    test('toMap / tryFromMap round trip', () {
      final f = EventFunction(
        id: 'x1',
        eventType: 'sangeet',
        date: DateTime(2026, 2, 3, 14),
        time: '18:00',
        location: 'Taj',
        notes: '  bring lights ',
      );
      final map = f.toMap();
      expect(map['date'], Timestamp.fromDate(DateTime(2026, 2, 3)));
      expect(map['eventTypeLabel'], 'Sangeet');
      expect(map['notes'], 'bring lights');
      expect(map.containsKey('locationArea'), isFalse);
      expect(EventFunction.tryFromMap(map), f);
    });
  });

  group('main / next function', () {
    test('main = first wedding anchor, else the first', () {
      expect(mainFunctionOf(functionsOf(weddingBooking))!.id, 'w');
      final noWedding = functionsOf({
        'functions': [
          fn('r', 'reception', DateTime(2026, 1, 7)),
          fn('h', 'haldi', DateTime(2026, 1, 5)),
        ],
      });
      expect(mainFunctionOf(noWedding)!.id, 'h');
      expect(mainFunctionOf(const []), isNull);
      expect(isWeddingAnchorType('nikah'), isTrue);
      expect(isWeddingAnchorType('pre_wedding', 'Pre-wedding shoot'), isFalse);
    });

    test('next = first on or after today, else the last', () {
      final functions = functionsOf(weddingBooking);
      expect(nextFunctionOf(functions, DateTime(2026, 12, 1))!.id, 'h');
      expect(nextFunctionOf(functions, DateTime(2026, 12, 11, 23))!.id, 'm');
      expect(nextFunctionOf(functions, DateTime(2026, 12, 12, 8))!.id, 'w');
      expect(nextFunctionOf(functions, DateTime(2027, 1, 1))!.id, 'r');
      expect(nextFunctionOf(const [], DateTime(2026)), isNull);
    });

    test('list sort date: next function for multi, eventDate for legacy', () {
      expect(listSortDateOf(weddingBooking, DateTime(2026, 12, 11)), DateTime(2026, 12, 11));
      final legacy = {'eventDate': Timestamp.fromDate(DateTime(2026, 6, 1, 10))};
      expect(listSortDateOf(legacy, DateTime(2026, 1, 1)), DateTime(2026, 6, 1, 10));
    });

    test('function days are distinct and sorted', () {
      expect(functionDaysOf(weddingBooking), [
        DateTime(2026, 12, 10),
        DateTime(2026, 12, 11),
        DateTime(2026, 12, 12),
        DateTime(2026, 12, 13),
      ]);
    });
  });

  group('functionSyncFields', () {
    test('eventDate = last, eventStartDate = first, type = main, count', () {
      final fields = functionSyncFields(functionsOf(weddingBooking));
      expect(fields['eventDate'], Timestamp.fromDate(DateTime(2026, 12, 13)));
      expect(fields['eventStartDate'], Timestamp.fromDate(DateTime(2026, 12, 10)));
      expect(fields['functionCount'], 4);
      expect(fields['eventType'], 'wedding');
      expect(fields['eventTypeValue'], 'wedding');
      expect(fields['eventTypeLabel'], 'Wedding');
      final stored = fields['functions']! as List;
      expect(stored.map((m) => (m as Map)['id']), ['h', 'm', 'w', 'r']);
    });

    test('location = main function\'s when it has one', () {
      final fields = functionSyncFields(functionsOf(weddingBooking));
      expect(fields['eventLocation'], 'Palace Grounds');
      expect(fields.containsKey('locationArea'), isTrue);
      expect(fields['locationArea'], isNull); // delete: the main function has no area
      expect(fields['locationLat'], isNull);
    });

    test('else the first function with a location', () {
      final functions = functionsOf({
        'functions': [
          fn('h', 'haldi', DateTime(2026, 1, 5)),
          fn('m', 'mehendi', DateTime(2026, 1, 6), location: 'Whitefield', area: 'Whitefield'),
          fn('w', 'wedding', DateTime(2026, 1, 7)),
        ],
      });
      final fields = functionSyncFields(functions);
      expect(fields['eventType'], 'wedding');
      expect(fields['eventLocation'], 'Whitefield');
      expect(fields['locationArea'], 'Whitefield');
    });

    test('no function has a location → top-level location is left alone', () {
      final functions = functionsOf({
        'functions': [
          fn('h', 'haldi', DateTime(2026, 1, 5)),
          fn('w', 'wedding', DateTime(2026, 1, 7)),
        ],
      });
      final fields = functionSyncFields(functions);
      expect(fields.containsKey('eventLocation'), isFalse);
      expect(fields.containsKey('locationArea'), isFalse);
    });

    test('lat / lng / city kept only when the place id is unchanged', () {
      final functions = functionsOf({
        'functions': [
          fn('w', 'wedding', DateTime(2026, 1, 7), location: 'Palace', placeId: 'p1'),
          fn('r', 'reception', DateTime(2026, 1, 8)),
        ],
      });
      final same = functionSyncFields(functions, existing: {'locationPlaceId': 'p1'});
      expect(same.containsKey('locationLat'), isFalse);
      expect(same['locationPlaceId'], 'p1');
      final other = functionSyncFields(functions, existing: {'locationPlaceId': 'p0'});
      expect(other.containsKey('locationLat'), isTrue);
      expect(other['locationLat'], isNull);
    });

    test('the synthesized legacy function gets a real id when stored', () {
      final legacy = functionsOf({
        'eventType': 'wedding',
        'eventDate': Timestamp.fromDate(DateTime(2026, 1, 7)),
      }).single;
      final added = EventFunction(id: 'new1', eventType: 'reception', date: DateTime(2026, 1, 8));
      final stored = functionSyncFields([legacy, added])['functions']! as List;
      expect((stored.first as Map)['id'], isNot(EventFunction.legacyId));
    });

    test('a single plain function goes back to the legacy shape', () {
      final single = [EventFunction(id: 'a', eventType: 'wedding', date: DateTime(2026, 1, 7))];
      final fields = functionsWriteFields(
        single,
        existing: {'functions': <Object>[], 'functionCount': 2, 'eventStartDate': 1},
      );
      expect(fields.containsKey('functions'), isTrue);
      expect(fields['functions'], isNull);
      expect(fields['functionCount'], isNull);
      expect(fields['eventStartDate'], isNull);
      expect(fields['eventDate'], Timestamp.fromDate(DateTime(2026, 1, 7)));
      // Nothing to clear on a doc that never had the array.
      expect(functionsWriteFields(single).containsKey('functions'), isFalse);
      // A single function with a time keeps its array.
      final timed = [
        EventFunction(id: 'a', eventType: 'wedding', date: DateTime(2026, 1, 7), time: '19:00'),
      ];
      expect(functionsWriteFields(timed)['functionCount'], 1);
    });
  });

  group('text', () {
    test('list subtitle for multi-function bookings', () {
      final functions = functionsOf(weddingBooking);
      expect(
        functionsListSubtitle(functions, DateTime(2026, 12, 1)),
        '4 functions · 10–13 Dec · Next: Haldi, 10 Dec (JP Nagar)',
      );
      expect(
        functionsListSubtitle(functions, DateTime(2026, 12, 12)),
        '4 functions · 10–13 Dec · Next: Wedding, 12 Dec (Palace Grounds)',
      );
      // Past booking: next = the last one.
      expect(
        functionsListSubtitle(functions, DateTime(2027, 2, 1)),
        '4 functions · 10–13 Dec · Next: Reception, 13 Dec (Taj West End)',
      );
      expect(functionsListSubtitle(functions.take(1).toList(), DateTime(2026)), isNull);
    });

    test('date range label', () {
      EventFunction at(DateTime d) => EventFunction(id: '$d', eventType: 'x', date: d);
      expect(functionDateRangeLabel([at(DateTime(2026, 12, 12))]), '12 Dec');
      expect(
        functionDateRangeLabel([at(DateTime(2026, 12, 13)), at(DateTime(2026, 12, 10))]),
        '10–13 Dec',
      );
      expect(
        functionDateRangeLabel([at(DateTime(2026, 12, 30)), at(DateTime(2027, 1, 2))]),
        '30 Dec – 2 Jan',
      );
    });

    test('summary for CSV / history', () {
      expect(
        functionsSummary(functionsOf(weddingBooking)),
        'Haldi 10 Dec; Mehendi 11 Dec; Wedding 12 Dec 7:00 PM; Reception 13 Dec',
      );
      expect(functionsSummary(const []), '');
    });

    test('time helpers', () {
      expect(formatFunctionTime('19:00'), '7:00 PM');
      expect(formatFunctionTime('9:5'), isNull);
      expect(formatFunctionTime(null), isNull);
      expect(parseFunctionTime('24:00'), isNull);
      expect(functionTimeText(7, 5), '07:05');
    });

    test('search labels and ids', () {
      expect(functionTypeLabels(functionsOf(weddingBooking)), [
        'Haldi',
        'Mehendi',
        'Wedding',
        'Reception',
      ]);
      final id = newEventFunctionId(random: Random(1));
      expect(id, hasLength(8));
      expect(RegExp(r'^[a-z0-9]{8}$').hasMatch(id), isTrue);
    });
  });
}
