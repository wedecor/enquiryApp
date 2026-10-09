import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:we_decor_enquiries/features/admin/analytics/data/analytics_repository.dart';
import 'package:we_decor_enquiries/features/admin/analytics/domain/pipeline_metrics.dart';

/// Owner's rule: EVENTS are counted per FUNCTION, REVENUE per BOOKING (once).
void main() {
  final now = DateTime(2026, 10, 15, 12);

  Map<String, Object> fn(String id, String type, DateTime date, {String? area}) => {
    'id': id,
    'eventType': type,
    'eventTypeLabel': type[0].toUpperCase() + type.substring(1),
    'date': Timestamp.fromDate(date),
    if (area != null) 'locationArea': area,
  };

  // A 4-function wedding booked for ₹2,00,000.
  final wedding = <String, dynamic>{
    'id': 'w1',
    'customerName': 'Ayesha',
    'statusValue': 'approved',
    'sourceValue': 'instagram',
    'eventTypeValue': 'wedding',
    'eventDate': DateTime(2026, 12, 13),
    'createdAt': DateTime(2026, 10, 2),
    'locationArea': 'Palace Grounds',
    'totalCost': 200000,
    'advancePaid': 50000,
    'functions': [
      fn('h', 'haldi', DateTime(2026, 12, 10), area: 'JP Nagar'),
      fn('m', 'mehendi', DateTime(2026, 12, 11), area: 'JP Nagar'),
      fn('w', 'wedding', DateTime(2026, 12, 12), area: 'Palace Grounds'),
      fn('r', 'reception', DateTime(2026, 12, 13), area: 'Palace Grounds'),
    ],
  };

  // A legacy single-event birthday, ₹30,000.
  final birthday = <String, dynamic>{
    'id': 'b1',
    'customerName': 'Ravi',
    'statusValue': 'completed',
    'sourceValue': 'referral',
    'eventTypeValue': 'birthday',
    'eventDate': DateTime(2026, 12, 20),
    'createdAt': DateTime(2026, 10, 5),
    'locationArea': 'HSR Layout',
    'totalCost': 30000,
  };

  // An open lead (not won) with two functions.
  final openLead = <String, dynamic>{
    'id': 'o1',
    'customerName': 'Open',
    'statusValue': 'in_talks',
    'eventTypeValue': 'wedding',
    'eventDate': DateTime(2027, 1, 6),
    'createdAt': DateTime(2026, 10, 6),
    'functions': [
      fn('a', 'engagement', DateTime(2027, 1, 5)),
      fn('b', 'wedding', DateTime(2027, 1, 6)),
    ],
  };

  group('4-function booking worth ₹2,00,000', () {
    final report = buildPipelineReport(
      allRows: [wedding],
      start: DateTime(2026, 10),
      end: DateTime(2026, 11),
      attribution: AnalyticsAttribution.enquiryDate,
      now: now,
    );

    test('Events 4, Bookings 1, Booked value ₹2,00,000', () {
      expect(report.eventsInPeriod, 4);
      expect(report.bookingsInPeriod, 1);
      expect(report.bookedValueInPeriod, 200000);
      expect(report.funnel.total, 1); // leads stay per booking
    });

    test('event types count each function under its own type', () {
      final byType = {for (final c in report.eventTypeEvents) c.key: c.count};
      expect(byType, {'haldi': 1, 'mehendi': 1, 'wedding': 1, 'reception': 1});
      expect(AnalyticsRepository.aggregateCountByEventType([wedding]), {
        'haldi': 1,
        'mehendi': 1,
        'wedding': 1,
        'reception': 1,
      });
    });

    test('money is per booking, never multiplied', () {
      final dec = report.money.firstWhere((m) => m.month == DateTime(2026, 12));
      expect(dec.bookings, 1);
      expect(dec.booked, 200000);
      expect(dec.collected, 50000);
    });

    test('areas: events by function area, value by the main area once', () {
      final areas = {for (final a in report.areas) a.label: a};
      expect(areas['JP Nagar']!.events, 2);
      expect(areas['JP Nagar']!.bookings, 0);
      expect(areas['JP Nagar']!.bookedValue, 0);
      expect(areas['Palace Grounds']!.events, 2);
      expect(areas['Palace Grounds']!.bookings, 1);
      expect(areas['Palace Grounds']!.bookedValue, 200000);
      final totalValue = report.areas.fold<double>(0, (a, b) => a + b.bookedValue);
      expect(totalValue, 200000);
    });
  });

  test('event-date attribution counts functions by their own date', () {
    final report = buildPipelineReport(
      allRows: [wedding, birthday, openLead],
      start: DateTime(2026, 12, 11),
      end: DateTime(2026, 12, 13),
      attribution: AnalyticsAttribution.eventDate,
      now: now,
    );
    // Mehendi (11) + Wedding (12) of the won wedding; reception (13) is outside.
    expect(report.eventsInPeriod, 2);
    // The booking's eventDate (13 Dec, last function) is outside → not a booking here.
    expect(report.bookingsInPeriod, 0);
    expect(report.bookedValueInPeriod, 0);
  });

  test('mixed rows: legacy events count once, open leads are not booked events', () {
    final report = buildPipelineReport(
      allRows: [wedding, birthday, openLead],
      start: DateTime(2026, 10),
      end: DateTime(2026, 11),
      attribution: AnalyticsAttribution.enquiryDate,
      now: now,
    );
    expect(report.eventsInPeriod, 5); // 4 wedding functions + 1 birthday
    expect(report.bookingsInPeriod, 2);
    expect(report.bookedValueInPeriod, 230000);
    expect(report.funnel.total, 3);
  });

  test('busy months and lead time count functions', () {
    final demand = computeUpcomingDemand([wedding, birthday, openLead], now);
    final dec = demand.firstWhere((m) => m.month == DateTime(2026, 12));
    expect(dec.total, 5);
    expect(dec.byEventType, {
      'haldi': 1,
      'mehendi': 1,
      'wedding': 1,
      'reception': 1,
      'birthday': 1,
    });
    final jan = demand.firstWhere((m) => m.month == DateTime(2027, 1));
    expect(jan.byEventType, {'engagement': 1, 'wedding': 1});

    final leadTime = computeLeadTime([wedding]);
    expect(leadTime.fold<int>(0, (a, b) => a + b.count), 4);
    expect(leadTime.firstWhere((b) => b.key == '1to3m').count, 4);
  });

  test('metricFunctionsOf: legacy rows give one event even without a date', () {
    final events = metricFunctionsOf({'eventTypeValue': 'birthday', 'locationArea': 'HAL'});
    expect(events, hasLength(1));
    expect(events.single.eventType, 'birthday');
    expect(events.single.date, isNull);
    expect(events.single.area, 'HAL');
    expect(metricFunctionsOf(wedding).map((f) => f.area), [
      'JP Nagar',
      'JP Nagar',
      'Palace Grounds',
      'Palace Grounds',
    ]);
  });
}
