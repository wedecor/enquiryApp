import 'package:flutter_test/flutter_test.dart';
import 'package:we_decor_enquiries/features/enquiries/data/booking_clash_service.dart';

void main() {
  final now = DateTime(2026, 10, 8);
  final dec12 = DateTime(2026, 12, 12);

  group('approvedDateClashMessage', () {
    test('approve: lists areas', () {
      expect(
        approvedDateClashMessage(
          date: dec12,
          count: 2,
          areas: ['Whitefield', 'Yelahanka'],
          isDateChange: false,
          now: now,
        ),
        'You already have 2 approved events on 12 Dec (Whitefield, Yelahanka). Approve anyway?',
      );
    });

    test('date change uses the move question', () {
      expect(
        approvedDateClashMessage(
          date: dec12,
          count: 1,
          areas: ['Whitefield'],
          isDateChange: true,
          now: now,
        ),
        'You already have 1 approved event on 12 Dec (Whitefield). Move it to this date anyway?',
      );
    });

    test('no known areas omits the parentheses', () {
      expect(
        approvedDateClashMessage(
          date: dec12,
          count: 2,
          areas: [null, '  '],
          isDateChange: false,
          now: now,
        ),
        'You already have 2 approved events on 12 Dec. Approve anyway?',
      );
    });

    test('dedupes case-insensitively and skips blanks', () {
      expect(
        approvedDateClashMessage(
          date: dec12,
          count: 3,
          areas: ['Whitefield', '', 'whitefield ', 'Yelahanka'],
          isDateChange: false,
          now: now,
        ),
        'You already have 3 approved events on 12 Dec (Whitefield, Yelahanka). Approve anyway?',
      );
    });

    test('caps the list at four then "+N more"', () {
      expect(
        approvedDateClashMessage(
          date: dec12,
          count: 6,
          areas: ['A', 'B', 'C', 'D', 'E', 'F'],
          isDateChange: false,
          now: now,
        ),
        'You already have 6 approved events on 12 Dec (A, B, C, D +2 more). Approve anyway?',
      );
    });

    test('adds the year for another year', () {
      expect(
        approvedDateClashMessage(
          date: DateTime(2027, 1, 5),
          count: 1,
          areas: const [],
          isDateChange: false,
          now: now,
        ),
        'You already have 1 approved event on 5 Jan 2027. Approve anyway?',
      );
    });
  });

  group('bookingDayKey', () {
    test('zero-pads the local calendar day', () {
      expect(bookingDayKey(DateTime(2026, 3, 4)), '2026-03-04');
      expect(bookingDayKey(DateTime(2026, 12, 12, 23, 59)), '2026-12-12');
    });
  });

  group('ApprovedOnDateResult.fromResponse', () {
    test('parses an Android-style Map<Object?, Object?> response', () {
      final Map<Object?, Object?> response = {
        'count': 2,
        'events': <Object?>[
          <Object?, Object?>{'id': 'e1', 'area': 'Whitefield', 'eventType': 'Wedding'},
          <Object?, Object?>{'id': 'e2', 'area': null, 'eventType': 'Birthday'},
        ],
      };
      final result = ApprovedOnDateResult.fromResponse(response);
      expect(result.count, 2);
      expect(result.hasClash, isTrue);
      expect(result.events.map((e) => e.id), ['e1', 'e2']);
      expect(result.events.first.area, 'Whitefield');
      expect(result.events.first.eventType, 'Wedding');
      expect(result.events.last.area, isNull);
    });

    test('blank area becomes null and entries without an id are dropped', () {
      final result = ApprovedOnDateResult.fromResponse(<String, dynamic>{
        'count': 1,
        'events': [
          {'id': 'e1', 'area': '   '},
          {'area': 'Hebbal'},
          'garbage',
        ],
      });
      expect(result.events, hasLength(1));
      expect(result.events.single.area, isNull);
      expect(result.events.single.eventType, 'Event');
    });

    test('missing count falls back to the event list length', () {
      final result = ApprovedOnDateResult.fromResponse(<String, dynamic>{
        'events': [
          {'id': 'e1'},
        ],
      });
      expect(result.count, 1);
    });

    test('null / non-map response is empty (no clash)', () {
      expect(ApprovedOnDateResult.fromResponse(null).hasClash, isFalse);
      expect(ApprovedOnDateResult.fromResponse('oops').count, 0);
      expect(ApprovedOnDateResult.fromResponse(<String, dynamic>{'count': 0}).hasClash, isFalse);
    });
  });

  group('multi-day (functions)', () {
    final dec13 = DateTime(2026, 12, 13);

    test('distinct days, ascending, time of day dropped', () {
      expect(distinctBookingDays([dec13, DateTime(2026, 12, 12, 19), dec12]), [dec12, dec13]);
      expect(distinctBookingDays(const []), isEmpty);
    });

    test('parses days for the requested dates (Android nested maps too)', () {
      final clashes = approvedDayClashesFromResponse(
        <Object?, Object?>{
          'count': 3,
          'events': <Object?>[],
          'days': [
            <Object?, Object?>{
              'date': '2026-12-12',
              'count': 2,
              'events': [
                {'id': 'a', 'area': 'Whitefield', 'eventType': 'Haldi'},
                {'id': 'b', 'area': 'Yelahanka', 'eventType': 'Wedding'},
              ],
            },
            {
              'date': '2026-12-13',
              'count': 1,
              'events': [
                {'id': 'c', 'area': 'Taj West End', 'eventType': 'Reception'},
              ],
            },
          ],
        },
        [dec12, dec13, DateTime(2026, 12, 14)],
      );
      expect(clashes.map((c) => c.count), [2, 1, 0]);
      expect(clashes.first.events.map((e) => e.eventType), ['Haldi', 'Wedding']);
      expect(clashes.last.hasClash, isFalse);
    });

    test('older server (no days) answers for the first date only', () {
      final clashes = approvedDayClashesFromResponse(
        <String, dynamic>{
          'count': 1,
          'events': [
            {'id': 'a', 'area': 'HSR'},
          ],
        },
        [dec12, dec13],
      );
      expect(clashes, hasLength(1));
      expect(clashes.single.date, dec12);
      expect(clashes.single.count, 1);
    });

    ApprovedDayClash clash(DateTime date, List<String?> areas) => ApprovedDayClash(
      date: date,
      count: areas.length,
      events: [
        for (var i = 0; i < areas.length; i++)
          ApprovedBooking(id: 'e$i', eventType: 'Event', area: areas[i]),
      ],
    );

    test('one dialog summarising every clashing day', () {
      expect(
        approvedDatesClashMessage(
          clashes: [
            clash(dec12, ['Whitefield', 'Yelahanka']),
            clash(dec13, ['Taj West End']),
            clash(DateTime(2026, 12, 14), []),
          ],
          isDateChange: false,
          now: now,
        ),
        '12 Dec: 2 approved events (Whitefield, Yelahanka) · '
        '13 Dec: 1 approved event (Taj West End). Approve anyway?',
      );
    });

    test('a single clashing day reads like the classic message', () {
      expect(
        approvedDatesClashMessage(
          clashes: [
            clash(dec12, ['Whitefield']),
            clash(dec13, []),
          ],
          isDateChange: true,
          now: now,
        ),
        'You already have 1 approved event on 12 Dec (Whitefield). Move it to this date anyway?',
      );
    });

    test('date change question for several days', () {
      expect(
        approvedDatesClashMessage(
          clashes: [
            clash(dec12, [null]),
            clash(dec13, ['HSR']),
          ],
          isDateChange: true,
          now: now,
        ),
        '12 Dec: 1 approved event · 13 Dec: 1 approved event (HSR). Save these dates anyway?',
      );
    });
  });
}
