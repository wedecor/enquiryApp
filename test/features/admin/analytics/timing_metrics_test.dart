import 'package:flutter_test/flutter_test.dart';
import 'package:we_decor_enquiries/core/constants/firestore_schema.dart';
import 'package:we_decor_enquiries/features/admin/analytics/domain/pipeline_metrics.dart';
import 'package:we_decor_enquiries/features/admin/analytics/domain/timing_metrics.dart';
import 'package:we_decor_enquiries/features/reengagement/domain/occasion_reminder.dart';

void main() {
  Map<String, dynamic> row(
    String id,
    String status, {
    DateTime? created,
    DateTime? event,
    DateTime? firstContact,
    bool estimated = false,
    String source = 'instagram',
    String type = 'wedding',
    String? lostReason,
    Object? mergedInto,
    List<Map<String, dynamic>>? functions,
  }) => {
    'id': id,
    'statusValue': status,
    'createdAt': created,
    if (event != null) 'eventDate': event,
    if (firstContact != null) 'firstContactAt': firstContact,
    if (estimated) 'firstContactEstimated': true,
    'sourceValue': source,
    'eventTypeValue': type,
    if (lostReason != null) 'lostReason': lostReason,
    if (mergedInto != null) 'mergedInto': mergedInto,
    if (functions != null) 'functions': functions,
  };

  group('IST weekday / hour buckets', () {
    test('23:30 UTC Saturday → Sunday 05:00 IST (night bucket, before 06:00)', () {
      // 2026-11-14 23:30 UTC Saturday → 2026-11-15 05:00 IST Sunday
      final instant = DateTime.utc(2026, 11, 14, 23, 30);
      expect(IstDate.calendar(instant).weekday, DateTime.sunday);
      expect(istWeekdayIndex(instant), 6); // Sunday
      // Morning starts at 06:00; 05:00 is still Night (21:00–05:59).
      expect(timeOfDayBucket(instant), TimeOfDayBucket.night);
    });

    test('Night bucket wraps midnight', () {
      expect(
        timeOfDayBucket(DateTime.utc(2026, 11, 14, 15, 30)),
        TimeOfDayBucket.night,
      ); // 21:00 IST
      expect(
        timeOfDayBucket(DateTime.utc(2026, 11, 14, 20, 0)),
        TimeOfDayBucket.night,
      ); // 01:30 IST
      expect(
        timeOfDayBucket(DateTime.utc(2026, 11, 14, 0, 30)),
        TimeOfDayBucket.morning,
      ); // 06:00 IST
    });
  });

  group('enquiries by weekday', () {
    test('excludes merged duplicates and under-5 rate is null', () {
      final sat = DateTime.utc(2026, 11, 14, 6); // Sat 11:30 IST
      final rows = [
        for (var i = 0; i < 3; i++) row('w$i', 'approved', created: sat),
        for (var i = 0; i < 2; i++) row('l$i', 'not_interested', created: sat),
        row('dup', 'not_interested', created: sat, lostReason: 'duplicate'),
        row('merged', 'new', created: sat, mergedInto: 'w0'),
      ];
      final report = computeEnquiriesByWeekday(leadRows(rows));
      final saturday = report.rows[5];
      expect(saturday.enquiries, 5);
      expect(saturday.won, 3);
      expect(saturday.lost, 2);
      expect(saturday.winRate, isNotNull); // decided == 5 → rate shown
      expect(sampleWinRate(2, 2), isNull); // under 5 → no rate
      expect(formatWinRateOrDash(2, 2), '—');
    });
  });

  group('events by function', () {
    test('multi-function booking contributes one event per function weekday', () {
      final booking = row(
        'b1',
        'approved',
        created: DateTime.utc(2026, 10, 1),
        functions: [
          {
            'eventType': 'haldi',
            'date': DateTime.utc(2026, 11, 13, 6), // Fri IST
          },
          {
            'eventType': 'wedding',
            'date': DateTime.utc(2026, 11, 14, 6), // Sat IST
          },
        ],
      );
      final fns = wonFunctionsDatedInPeriod(
        [booking],
        start: DateTime.utc(2026, 11, 1),
        end: DateTime.utc(2026, 12, 1),
      );
      expect(fns, hasLength(2));
      final report = computeEventsByWeekday(fns);
      expect(report.rows[4].events, 1); // Friday
      expect(report.rows[5].events, 1); // Saturday
    });
  });

  group('busiest dates', () {
    test('ties ordered by date newest first', () {
      final rows = [
        row(
          'a',
          'completed',
          created: DateTime.utc(2026, 1, 1),
          event: DateTime.utc(2026, 11, 10, 6),
        ),
        row(
          'b',
          'completed',
          created: DateTime.utc(2026, 1, 1),
          event: DateTime.utc(2026, 11, 12, 6),
        ),
        row(
          'c',
          'completed',
          created: DateTime.utc(2026, 1, 1),
          event: DateTime.utc(2026, 11, 10, 8),
        ),
      ];
      final fns = wonFunctionsDatedInPeriod(
        rows,
        start: DateTime.utc(2026, 11, 1),
        end: DateTime.utc(2026, 12, 1),
      );
      final report = computeBusiestDates(fns);
      expect(report.maxOnSingleDay, 2);
      expect(report.daysWith2Plus, 1);
      expect(report.topDates.first.events, 2);
    });
  });

  group('season YoY', () {
    test('hides year-earlier when under 13 months of data', () {
      final now = DateTime.utc(2026, 11, 15);
      final rows = [
        row('a', 'approved', created: DateTime.utc(2026, 5, 1), event: DateTime.utc(2026, 6, 15)),
        row('b', 'approved', created: DateTime.utc(2026, 7, 1), event: DateTime.utc(2026, 8, 15)),
      ];
      final season = computeSeasonByEventType(rows, now: now);
      expect(season.hasYearEarlier, isFalse);
      expect(season.note, isNotNull);
      expect(season.rows, hasLength(12));
      expect(season.rows.every((r) => r.priorTotal == null), isTrue);
    });

    test('aligns months ending at last full IST month', () {
      final now = DateTime.utc(2026, 11, 15, 10); // Nov
      final season = computeSeasonByEventType(const [], now: now);
      expect(season.rows.last.monthStart.month, 10); // October
      expect(season.rows.first.monthStart.month, 11); // Nov previous year
    });
  });

  group('lead time with win rates', () {
    test('keeps existing bucket counts and adds win rate', () {
      final created = DateTime.utc(2026, 9, 1);
      final rows = [
        for (var i = 0; i < 6; i++)
          row('w$i', 'approved', created: created, event: created.add(const Duration(days: 10))),
        for (var i = 0; i < 2; i++)
          row(
            'l$i',
            'not_interested',
            created: created,
            event: created.add(const Duration(days: 10)),
          ),
        row('late', 'approved', created: created, event: created.add(const Duration(days: 100))),
      ];
      final baseline = computeLeadTime(rows);
      final extended = computeLeadTimeWithWinRates(rows);
      for (var i = 0; i < baseline.length; i++) {
        expect(extended.rows[i].count, baseline[i].count);
        expect(extended.rows[i].key, baseline[i].key);
      }
      expect(extended.rows[0].count, 8); // lt2w
      expect(extended.rows[0].won, 6);
      expect(extended.rows[0].lost, 2);
      expect(extended.rows[0].winRate, isNotNull);
      expect(extended.rows[3].count, 1); // 3to6m (100 days)
    });
  });

  group('website filter', () {
    test('uses schema website lead source constant', () {
      expect(EnquiryFields.websiteLeadSourceValue, 'google_website');
      expect(
        isWebsiteLead(row('w', 'new', created: DateTime.now(), source: 'google_website')),
        isTrue,
      );
      expect(isWebsiteLead(row('i', 'new', created: DateTime.now(), source: 'instagram')), isFalse);
    });
  });

  group('response median gate', () {
    test('median is null under 5 measured samples', () {
      final created = DateTime.utc(2026, 11, 10, 6);
      final rows = [
        for (var i = 0; i < 4; i++)
          row(
            'r$i',
            'new',
            created: created,
            firstContact: created.add(Duration(hours: i + 1)),
          ),
      ];
      final report = computeResponseByArrival(rows);
      final day = report.byWeekday[istWeekdayIndex(created)];
      expect(day.measuredCount, 4);
      expect(day.median, isNull);
    });
  });
}
