import 'package:flutter_test/flutter_test.dart';
import 'package:we_decor_enquiries/features/admin/analytics/domain/pipeline_metrics.dart';

void main() {
  final now = DateTime(2026, 10, 15, 12);
  DateTime ago({int days = 0, int hours = 0}) => now.subtract(Duration(days: days, hours: hours));

  Map<String, dynamic> row(
    String id,
    String status, {
    DateTime? created,
    DateTime? event,
    DateTime? firstContact,
    bool estimated = false,
    num? total,
    num? advance,
    num? quoted,
    String source = 'instagram',
    String type = 'wedding',
    String? assignedTo,
    String? lostReason,
    DateTime? inTalksAt,
    DateTime? approvedAt,
    DateTime? updated,
    DateTime? lastContact,
    int? contactCount,
    int? reminders,
    String? payment,
  }) => {
    'id': id,
    'customerName': 'Customer $id',
    'statusValue': status,
    'createdAt': created ?? ago(days: 10),
    if (event != null) 'eventDate': event,
    if (firstContact != null) 'firstContactAt': firstContact,
    if (estimated) 'firstContactEstimated': true,
    if (total != null) 'totalCost': total,
    if (advance != null) 'advancePaid': advance,
    if (quoted != null) 'quotedAmount': quoted,
    'sourceValue': source,
    'eventTypeValue': type,
    if (assignedTo != null) 'assignedTo': assignedTo,
    if (lostReason != null) 'lostReason': lostReason,
    if (inTalksAt != null) 'inTalksAt': inTalksAt,
    if (approvedAt != null) 'approvedAt': approvedAt,
    'updatedAt': updated ?? ago(days: 1),
    if (lastContact != null) 'lastContactAt': lastContact,
    if (contactCount != null) 'contactCount': contactCount,
    if (reminders != null) 'reminderClickCount': reminders,
    if (payment != null) 'paymentStatusValue': payment,
  };

  group('statuses', () {
    test('legacy values count as their canonical stage', () {
      expect(isWon(row('a', 'confirmed')), isTrue);
      expect(isOpen(row('b', 'quote_sent')), isTrue);
      expect(furthestStage(row('c', 'quote_sent')), 1);
    });

    test('only known active statuses are open', () {
      expect(isOpen(row('a', 'new')), isTrue);
      expect(isOpen(row('b', 'in_talks')), isTrue);
      expect(isOpen(row('c', 'approved')), isFalse);
      expect(isOpen(row('d', 'not_interested')), isFalse);
      expect(isOpen(row('e', 'not_intrested')), isFalse); // legacy typo → lost
      expect(isLostRow(row('e', 'not_intrested')), isTrue);
      expect(isOpen(row('f', 'mystery_status')), isFalse);
      expect(isOpen(row('g', '')), isFalse);
      expect(isOpen({'id': 'h'}), isFalse);
    });

    test('lost enquiries use stage timestamps for how far they got', () {
      expect(furthestStage(row('a', 'not_interested')), 0);
      expect(furthestStage(row('b', 'cancelled', inTalksAt: ago(days: 5))), 1);
      expect(furthestStage(row('c', 'cancelled', approvedAt: ago(days: 5))), 2);
    });
  });

  group('rowsInPeriod', () {
    final rows = [
      row('a', 'new', created: DateTime(2026, 9, 30), event: DateTime(2026, 12, 1)),
      row('b', 'new', created: DateTime(2026, 10, 1), event: DateTime(2026, 10, 20)),
    ];

    test('enquiry date uses createdAt with an exclusive end', () {
      final r = rowsInPeriod(
        rows,
        start: DateTime(2026, 10, 1),
        end: DateTime(2026, 11, 1),
        attribution: AnalyticsAttribution.enquiryDate,
      );
      expect(r.map((e) => e['id']), ['b']);
    });

    test('event date uses eventDate', () {
      final r = rowsInPeriod(
        rows,
        start: DateTime(2026, 12, 1),
        end: DateTime(2027, 1, 1),
        attribution: AnalyticsAttribution.eventDate,
      );
      expect(r.map((e) => e['id']), ['a']);
    });
  });

  group('funnel', () {
    test('counts stages reached and where leads were lost', () {
      final f = computeFunnel([
        row('1', 'new'),
        row('2', 'in_talks'),
        row('3', 'approved'),
        row('4', 'completed'),
        row('5', 'not_interested'),
        row('6', 'closed_lost', inTalksAt: ago(days: 3)),
        row('7', 'cancelled', approvedAt: ago(days: 2)),
      ]);
      expect(f.total, 7);
      expect(f.reachedInTalks, 5); // 2,3,4,6,7
      expect(f.reachedApproved, 3); // 3,4,7
      expect(f.reachedCompleted, 1);
      expect(f.lostBeforeInTalks, 1);
      expect(f.lostAfterInTalks, 1);
      expect(f.lostAfterApproved, 1);
      expect(f.lost, 3);
      expect(f.open, 2);
    });

    test('empty input gives zeros', () {
      final f = computeFunnel(const []);
      expect(f.total, 0);
      expect(f.lost, 0);
    });
  });

  group('lost reasons', () {
    test('groups by reason with "Not recorded" for missing', () {
      final r = computeLostReasons([
        row('1', 'not_interested', lostReason: 'price_too_high'),
        row('2', 'cancelled', lostReason: 'price_too_high'),
        row('3', 'closed_lost'),
        row('4', 'approved', lostReason: 'price_too_high'), // not lost → ignored
      ]);
      expect(r.first.key, 'price_too_high');
      expect(r.first.count, 2);
      expect(r.first.label, 'Price too high');
      expect(r.last.label, 'Not recorded');
    });
  });

  group('speed to lead', () {
    test('percentiles, shares and buckets exclude estimates', () {
      final r = computeSpeedToLead([
        row(
          '1',
          'in_talks',
          created: ago(days: 2),
          firstContact: ago(days: 2).add(const Duration(minutes: 30)),
        ),
        row(
          '2',
          'approved',
          created: ago(days: 5),
          firstContact: ago(days: 5).add(const Duration(hours: 5)),
        ),
        row('3', 'not_interested', created: ago(days: 9), firstContact: ago(days: 4)),
        row('4', 'new', created: ago(days: 1)), // never contacted
        row('5', 'completed', created: ago(days: 30), firstContact: ago(days: 29), estimated: true),
      ]);
      expect(r.sampleSize, 3);
      expect(r.estimatedExcluded, 1);
      expect(r.neverContacted, 1);
      expect(r.median, const Duration(hours: 5));
      expect(r.within1h, closeTo(1 / 4, 1e-9));
      expect(r.within24h, closeTo(2 / 4, 1e-9));
      expect(r.buckets[0].leads, 1);
      expect(r.buckets[1].won, 1);
      expect(r.buckets[3].lost, 1);
      expect(r.buckets[4].leads, 1);
    });

    test('no contact data → no sample', () {
      final r = computeSpeedToLead([row('1', 'new')]);
      expect(r.hasData, isFalse);
      expect(r.median, isNull);
    });
  });

  group('performance', () {
    test('source rows: leads, win rate, booked value', () {
      final rows = [
        row('1', 'approved', total: 100000, source: 'instagram'),
        row('2', 'not_interested', source: 'instagram'),
        row('3', 'completed', total: 50000, source: 'referral'),
        row('4', 'in_talks', source: 'instagram'),
      ];
      final sources = computeSourcePerformance(rows, now);
      final insta = sources.firstWhere((s) => s.key == 'instagram');
      expect(insta.leads, 3);
      expect(insta.winRate, closeTo(0.5, 1e-9));
      expect(insta.bookedValue, 100000);
      expect(sources.first.key, 'instagram'); // most leads first
    });

    test('team rows count stale open enquiries', () {
      final rows = [
        row('1', 'in_talks', assignedTo: 'u1', updated: ago(days: 10), created: ago(days: 20)),
        row('2', 'in_talks', assignedTo: 'u1', updated: ago(days: 1)),
        row('3', 'new'),
      ];
      final team = computeTeamPerformance(rows, now);
      final u1 = team.firstWhere((t) => t.key == 'u1');
      expect(u1.open, 2);
      expect(u1.stale, 1);
      expect(team.any((t) => t.key == ''), isTrue); // unassigned bucket
    });
  });

  group('money', () {
    test('booked / collected by event month and overdue balances', () {
      final rows = [
        row('1', 'approved', event: DateTime(2026, 10, 25), total: 100000, advance: 40000),
        row('2', 'confirmed', event: DateTime(2026, 11, 5), total: 50000, advance: 50000),
        row('3', 'in_talks', event: DateTime(2026, 10, 28), total: 70000),
        row('4', 'completed', event: DateTime(2026, 9, 1), total: 80000, advance: 30000),
      ];
      final months = computeMoneyByMonth(rows, now);
      expect(months.length, 6);
      expect(months[0].month, DateTime(2026, 10));
      expect(months[0].booked, 100000);
      expect(months[0].outstanding, 60000);
      expect(months[1].bookings, 1);
      expect(months[1].outstanding, 0);

      final overdue = computeOverdue(rows, now);
      expect(overdue.length, 1);
      expect(overdue.first.id, '4');
      expect(overdue.first.outstanding, 50000);
    });

    test('paid enquiries are fully collected', () {
      final paidPast = row(
        '1',
        'completed',
        event: DateTime(2026, 9, 1),
        total: 80000,
        advance: 30000,
        payment: 'paid',
      );
      final paidUpcoming = row(
        '2',
        'approved',
        event: DateTime(2026, 10, 25),
        total: 100000,
        advance: 40000,
        payment: 'Paid',
      );
      final partial = row(
        '3',
        'approved',
        event: DateTime(2026, 10, 26),
        total: 20000,
        advance: 5000,
        payment: 'partial',
      );
      final legacyField = {
        ...row('4', 'completed', event: DateTime(2026, 9, 2), total: 10000),
        'paymentStatus': 'paid',
      };

      expect(isFullyPaid(paidPast), isTrue);
      expect(isFullyPaid(paidUpcoming), isTrue);
      expect(isFullyPaid(partial), isFalse);
      expect(isFullyPaid(legacyField), isTrue);
      expect(outstandingOf(paidPast), 0);
      expect(outstandingOf(partial), 15000);
      expect(collectedOf(paidUpcoming), 100000);
      expect(collectedOf(partial), 5000);

      final months = computeMoneyByMonth([paidUpcoming, partial], now);
      expect(months[0].booked, 120000);
      expect(months[0].collected, 105000);
      expect(months[0].outstanding, 15000);

      final overdue = computeOverdue([paidPast, legacyField, partial], now);
      expect(overdue, isEmpty);
    });
  });

  group('forecast', () {
    test('uses quote, else event-type average, weighted by win rate', () {
      final rows = [
        row('w1', 'completed', total: 100000, type: 'wedding', created: ago(days: 60)),
        row('w2', 'approved', total: 60000, type: 'wedding', created: ago(days: 40)),
        row('l1', 'not_interested', inTalksAt: ago(days: 30), created: ago(days: 35)),
        row('l2', 'not_interested', created: ago(days: 20)), // lost before talks: not counted
        row('o1', 'in_talks', quoted: 90000),
        row('o2', 'quote_sent', type: 'wedding'), // avg wedding = 80000
      ];
      final f = computeForecast(rows, now);
      expect(f.openCount, 2);
      expect(f.quotedCount, 1);
      expect(f.totalValue, 170000);
      expect(f.decidedSample, 3);
      expect(f.winProbability, closeTo(2 / 3, 1e-9));
      expect(f.expectedValue, closeTo(170000 * 2 / 3, 1e-6));
    });
  });

  group('demand', () {
    test('lead time buckets', () {
      final r = computeLeadTime([
        row('1', 'new', created: DateTime(2026, 10, 1), event: DateTime(2026, 10, 10)),
        row('2', 'new', created: DateTime(2026, 10, 1), event: DateTime(2027, 6, 1)),
      ]);
      expect(r.first.count, 1);
      expect(r.last.count, 1);
    });

    test('upcoming demand skips lost and past months', () {
      final r = computeUpcomingDemand([
        row('1', 'approved', event: DateTime(2026, 12, 3), type: 'wedding'),
        row('2', 'new', event: DateTime(2026, 12, 9), type: 'haldi'),
        row('3', 'cancelled', event: DateTime(2026, 12, 9)),
        row('4', 'approved', event: DateTime(2026, 8, 1)),
      ], now);
      expect(r.length, 12);
      expect(r[2].month, DateTime(2026, 12));
      expect(r[2].total, 2);
      expect(r[0].total, 0);
    });
  });

  group('follow-up', () {
    test('lists open enquiries not contacted for 7+ days', () {
      final rows = [
        row('1', 'in_talks', lastContact: ago(days: 9)),
        row('2', 'in_talks', lastContact: ago(days: 2)),
        row('3', 'new', created: ago(days: 12)),
        row('4', 'approved', contactCount: 4, reminders: 2),
        row('5', 'not_interested', contactCount: 1),
      ];
      final r = computeFollowUp(openRows: rows, periodRows: rows, now: now);
      expect(r.notContacted7d.map((s) => s.id), ['3', '1']);
      expect(r.avgContactsBeforeWin, 4);
      expect(r.avgContactsBeforeLoss, 1);
      expect(r.remindersSent, 2);
    });
  });

  test('buildPipelineReport wires the period and attribution', () {
    final rows = [
      row(
        '1',
        'approved',
        created: DateTime(2026, 10, 2),
        event: DateTime(2027, 1, 5),
        total: 1000,
      ),
      row(
        '2',
        'approved',
        created: DateTime(2026, 8, 2),
        event: DateTime(2026, 10, 20),
        total: 2000,
      ),
    ];
    final byEnquiry = buildPipelineReport(
      allRows: rows,
      start: DateTime(2026, 10, 1),
      end: DateTime(2026, 11, 1),
      attribution: AnalyticsAttribution.enquiryDate,
      now: now,
    );
    expect(byEnquiry.periodCount, 1);
    expect(byEnquiry.bookedValueInPeriod, 1000);

    final byEvent = buildPipelineReport(
      allRows: rows,
      start: DateTime(2026, 10, 1),
      end: DateTime(2026, 11, 1),
      attribution: AnalyticsAttribution.eventDate,
      now: now,
    );
    expect(byEvent.bookedValueInPeriod, 2000);
  });
}
