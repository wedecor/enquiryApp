import 'package:flutter_test/flutter_test.dart';
import 'package:we_decor_enquiries/features/admin/analytics/domain/monthly_summary.dart';
import 'package:we_decor_enquiries/features/reengagement/domain/reengagement_stats.dart';

void main() {
  // "Now" = 15 Nov 2026 IST afternoon ≈ 15 Nov 2026 09:00 UTC
  final now = DateTime.utc(2026, 11, 15, 9);
  final oct = const SummaryMonth(2026, 10);
  final nov = const SummaryMonth(2026, 11);
  final sep = const SummaryMonth(2026, 9);

  Map<String, dynamic> row(
    String id,
    String status, {
    DateTime? created,
    DateTime? event,
    DateTime? approvedAt,
    DateTime? completedAt,
    DateTime? lostAt,
    DateTime? inTalksAt,
    DateTime? firstContact,
    bool estimated = false,
    String source = 'instagram',
    String type = 'wedding',
    String? area,
    String? assignedTo,
    String? phone,
    String? name,
    String? lostReason,
    int? contactCount,
    num? totalCost,
    Object? mergedInto,
  }) => {
    'id': id,
    'statusValue': status,
    'customerName': name ?? 'Customer $id',
    'customerPhone': phone == null ? null : '+91$phone',
    if (phone != null) 'phoneNormalized': phone,
    'createdAt': created,
    if (event != null) 'eventDate': event,
    if (approvedAt != null) 'approvedAt': approvedAt,
    if (completedAt != null) 'completedAt': completedAt,
    if (lostAt != null) 'lostAt': lostAt,
    if (inTalksAt != null) 'inTalksAt': inTalksAt,
    if (firstContact != null) 'firstContactAt': firstContact,
    if (estimated) 'firstContactEstimated': true,
    'sourceValue': source,
    'eventTypeValue': type,
    if (area != null) 'locationArea': area,
    if (assignedTo != null) 'assignedTo': assignedTo,
    if (lostReason != null) 'lostReason': lostReason,
    if (contactCount != null) 'contactCount': contactCount,
    if (totalCost != null) 'totalCost': totalCost,
    if (mergedInto != null) 'mergedInto': mergedInto,
    'updatedAt': created ?? now,
  };

  group('IST month boundaries', () {
    test('31 Oct 20:00 UTC belongs to November IST', () {
      // 31 Oct 20:00 UTC = 1 Nov 01:30 IST
      final created = DateTime.utc(2025, 10, 31, 20);
      final summary = buildMonthlySummary(
        rows: [row('a', 'new', created: created, name: 'Priya Sharma', phone: '9876543210')],
        month: const SummaryMonth(2025, 11),
        now: DateTime.utc(2025, 11, 15),
        wishReminders: const [],
      );
      expect(summary.newEnquiries.value, 1);
      expect(summary.isEmpty, isFalse);

      final octSummary = buildMonthlySummary(
        rows: [row('a', 'new', created: created)],
        month: const SummaryMonth(2025, 10),
        now: DateTime.utc(2025, 11, 15),
        wishReminders: const [],
      );
      expect(octSummary.newEnquiries.value, 0);
    });
  });

  group('headlines', () {
    test('counts new, bookings, events, win rate, median response', () {
      final midOct = DateTime.utc(2026, 10, 10, 6);
      final midSep = DateTime.utc(2026, 9, 10, 6);
      final rows = [
        // Oct created + contacted
        for (var i = 0; i < 5; i++)
          row(
            'c$i',
            'new',
            created: midOct,
            firstContact: midOct.add(Duration(hours: i + 1)),
            assignedTo: 'u1',
            contactCount: 2,
            phone: '900000000$i',
            name: 'Lead $i',
          ),
        // Bookings confirmed in Oct
        row(
          'b1',
          'approved',
          created: midSep,
          approvedAt: midOct,
          event: DateTime.utc(2026, 10, 20),
          source: 'instagram',
          phone: '9111111111',
          name: 'Booked One',
          totalCost: 50000,
        ),
        row(
          'b2',
          'completed',
          created: midSep,
          approvedAt: midOct,
          completedAt: midOct.add(const Duration(days: 2)),
          event: DateTime.utc(2026, 10, 22),
          source: 'referral',
          phone: '9222222222',
          name: 'Booked Two',
          totalCost: 80000,
        ),
        // Lost in Oct
        row(
          'l1',
          'not_interested',
          created: midSep,
          lostAt: midOct,
          lostReason: 'price_too_high',
          source: 'instagram',
          phone: '9333333333',
          name: 'Lost One',
        ),
        row(
          'l2',
          'not_interested',
          created: midSep,
          lostAt: midOct,
          inTalksAt: midSep,
          lostReason: 'no_response',
          source: 'instagram',
          phone: '9444444444',
          name: 'Lost Two',
        ),
      ];

      final s = buildMonthlySummary(
        rows: rows,
        month: oct,
        now: now,
        wishReminders: const [],
        teamNames: {'u1': 'Asha'},
      );

      expect(s.newEnquiries.value, 5);
      expect(s.bookingsConfirmed.value, 2);
      expect(s.eventsCompleted.value, 2);
      expect(s.winRate.hasValue, isTrue);
      expect(s.winRate.value, closeTo(2 / 4, 0.001));
      expect(s.medianFirstResponse.hasValue, isTrue);
      expect(s.lost.total, 2);
      expect(s.lost.beforeConversation, 1);
      expect(s.lost.afterTalks, 1);
      expect(s.lost.topReasons.map((r) => r.label).toSet(), {'Price too high', 'No response'});
    });

    test('win rate with zero decided has no value', () {
      final mid = DateTime.utc(2026, 10, 5, 6);
      final s = buildMonthlySummary(
        rows: [row('n1', 'new', created: mid)],
        month: oct,
        now: now,
        wishReminders: const [],
      );
      expect(s.winRate.hasValue, isFalse);
    });
  });

  group('comparisons', () {
    test('hidden when earlier month has no enquiry data', () {
      final mid = DateTime.utc(2026, 10, 5, 6);
      final s = buildMonthlySummary(
        rows: [row('n1', 'new', created: mid)],
        month: oct,
        now: now,
        wishReminders: const [],
      );
      // Sep empty → vs previous hidden; Oct 2025 empty → yoy hidden
      expect(s.newEnquiries.vsPreviousMonth.hasData, isFalse);
      expect(s.newEnquiries.vsSameMonthLastYear.hasData, isFalse);
    });

    test('from zero shows plain difference not percent', () {
      final sepDay = DateTime.utc(2026, 9, 5, 6);
      final octDay = DateTime.utc(2026, 10, 5, 6);
      final s = buildMonthlySummary(
        rows: [
          // Sep has data but zero bookings
          row('n1', 'new', created: sepDay),
          row('b1', 'approved', created: sepDay, approvedAt: octDay),
        ],
        month: oct,
        now: now,
        wishReminders: const [],
      );
      expect(s.bookingsConfirmed.vsPreviousMonth.hasData, isTrue);
      expect(s.bookingsConfirmed.vsPreviousMonth.pct, isNull);
      expect(s.bookingsConfirmed.vsPreviousMonth.delta, 1);
    });
  });

  group('returning customers', () {
    test('detects earlier completed enquiry with same phone', () {
      final earlier = DateTime.utc(2026, 5, 1);
      final octDay = DateTime.utc(2026, 10, 10, 6);
      final s = buildMonthlySummary(
        rows: [
          row(
            'old',
            'completed',
            created: earlier,
            completedAt: earlier.add(const Duration(days: 10)),
            phone: '9555555555',
            name: 'Return Customer',
          ),
          row(
            'newb',
            'approved',
            created: octDay,
            approvedAt: octDay,
            phone: '9555555555',
            name: 'Return Customer',
          ),
          row(
            'fresh',
            'approved',
            created: octDay,
            approvedAt: octDay,
            phone: '9666666666',
            name: 'Fresh Customer',
          ),
        ],
        month: oct,
        now: now,
        wishReminders: const [],
      );
      expect(s.returningCustomers, 1);
      expect(s.newCustomers, 1);
    });
  });

  group('forward-looking sections', () {
    test('omitted for older months', () {
      final mid = DateTime.utc(2026, 9, 5, 6);
      final s = buildMonthlySummary(
        rows: [row('n1', 'new', created: mid)],
        month: sep,
        now: now,
        wishReminders: const [],
      );
      expect(s.stillOpen, isNull);
      expect(s.monthAhead, isNull);
    });

    test('included for last complete month', () {
      final mid = DateTime.utc(2026, 10, 5, 6);
      final s = buildMonthlySummary(
        rows: [
          row('n1', 'new', created: mid),
          row('open', 'in_talks', created: mid.subtract(const Duration(days: 40))),
        ],
        month: oct,
        now: now,
        wishReminders: const [],
      );
      expect(s.stillOpen, isNotNull);
      expect(s.stillOpen!.openNow, greaterThanOrEqualTo(1));
      expect(s.monthAhead, isNotNull);
    });

    test('included for current month', () {
      final mid = DateTime.utc(2026, 11, 5, 6);
      final s = buildMonthlySummary(
        rows: [row('n1', 'new', created: mid)],
        month: nov,
        now: now,
        wishReminders: const [],
      );
      expect(s.isPartialMonth, isTrue);
      expect(s.stillOpen, isNotNull);
      expect(s.monthAhead, isNotNull);
    });
  });

  group('sentences', () {
    test('skips booking sentence when prior month empty', () {
      final mid = DateTime.utc(2026, 10, 5, 6);
      final s = buildMonthlySummary(
        rows: [row('b1', 'approved', created: mid, approvedAt: mid, source: 'instagram')],
        month: oct,
        now: now,
        wishReminders: const [],
      );
      expect(s.sentences.any((t) => t.contains('Bookings confirmed')), isFalse);
      expect(s.sentences.any((t) => t.contains('Most enquiries')), isTrue);
    });
  });

  group('privacy', () {
    test('output never contains sample customer names, phones or amounts', () {
      final mid = DateTime.utc(2026, 10, 8, 6);
      const name = 'Ananya Krishnamurthy';
      const phone = '9812345678';
      final s = buildMonthlySummary(
        rows: [
          row(
            'x1',
            'approved',
            created: mid,
            approvedAt: mid,
            phone: phone,
            name: name,
            totalCost: 125000,
            assignedTo: 'u1',
            contactCount: 3,
          ),
          row(
            'x2',
            'not_interested',
            created: mid,
            lostAt: mid,
            lostReason: 'price_too_high',
            phone: '9822222222',
            name: 'Vikram Rao',
            totalCost: 99000,
          ),
        ],
        month: oct,
        now: now,
        wishReminders: [SentReminder(phoneNormalized: phone, sentAt: mid)],
        teamNames: {'u1': 'Team Asha'},
      );

      final blob = _summaryBlob(s);
      expect(blob.contains(name), isFalse);
      expect(blob.contains('Vikram Rao'), isFalse);
      expect(blob.contains(phone), isFalse);
      expect(blob.contains('9822222222'), isFalse);
      expect(blob.contains('125000'), isFalse);
      expect(blob.contains('99000'), isFalse);
      expect(blob.contains('Team Asha'), isTrue); // team names allowed
    });
  });

  group('wishes come-back', () {
    test('counts came-back via existing reengagement window', () {
      final wishAt = DateTime.utc(2026, 10, 2);
      final backAt = wishAt.add(const Duration(days: 10));
      final s = buildMonthlySummary(
        rows: [row('back', 'new', created: backAt, phone: '9777777777', name: 'Wish Back')],
        month: oct,
        now: now,
        wishReminders: [SentReminder(phoneNormalized: '9777777777', sentAt: wishAt)],
      );
      expect(s.wishes.sent, 1);
      expect(s.wishes.cameBack, 1);
      expect(ReengagementStats.window.inDays, 60);
    });
  });

  group('approvedAt fallback', () {
    test('won row without approvedAt uses completedAt then updatedAt', () {
      final mid = DateTime.utc(2026, 10, 12, 6);
      final s = buildMonthlySummary(
        rows: [
          row(
            'legacy',
            'completed',
            created: DateTime.utc(2026, 9, 1),
            completedAt: mid,
            // no approvedAt
            phone: '9888888888',
            name: 'Legacy Book',
          ),
        ],
        month: oct,
        now: now,
        wishReminders: const [],
      );
      expect(s.bookingsConfirmed.value, 1);
      expect(kApprovedAtFallback, 'completedAt, then updatedAt');
    });
  });
}

String _summaryBlob(MonthlySummary s) {
  final buf = StringBuffer()
    ..writeln(s.sentences.join('\n'))
    ..writeln(s.newEnquiries.value)
    ..writeln(s.bookingsConfirmed.value)
    ..writeln(s.eventsCompleted.value)
    ..writeln(s.winRate.value)
    ..writeln(s.medianFirstResponse.value)
    ..writeln(s.returningCustomers)
    ..writeln(s.newCustomers)
    ..writeln(s.lost.total)
    ..writeln(s.lost.topReasons.map((r) => '${r.label}:${r.count}').join(','))
    ..writeln(s.sources.map((r) => '${r.source}:${r.enquiries}:${r.bookings}').join(','))
    ..writeln(s.bookingsByEventType.map((r) => '${r.label}:${r.count}').join(','))
    ..writeln(s.bookingsByArea.map((r) => '${r.label}:${r.count}').join(','))
    ..writeln(s.timing.busiestEnquiryWeekday)
    ..writeln(s.timing.busiestEventWeekday)
    ..writeln(s.team.map((t) => '${t.name}:${t.enquiriesAssigned}:${t.contactsLogged}').join(','))
    ..writeln('${s.wishes.sent}:${s.wishes.cameBack}')
    ..writeln(s.stillOpen?.openNow)
    ..writeln(s.monthAhead?.inTalksWithDate);
  return buf.toString();
}
