import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:we_decor_enquiries/features/reengagement/domain/occasion_kind.dart';
import 'package:we_decor_enquiries/features/reengagement/domain/occasion_reminder.dart';
import 'package:we_decor_enquiries/features/reengagement/domain/past_customer_occasion.dart';

/// 00:00 IST of y-m-d.
DateTime ist(int y, int m, int d) => IstDate.startOfDay(y, m, d);

PastCustomerOccasion source({
  String id = 'e1',
  String phone = '9876543210',
  String name = 'Ayesha Khan',
  OccasionKind kind = OccasionKind.weddingAnniversary,
  required DateTime occasion,
  String? eventTypeValue = 'wedding',
  String eventTypeLabel = 'Wedding',
  DateTime? eventDate,
  String? person,
  bool merged = false,
  bool remindersOn = true,
}) {
  return PastCustomerOccasion(
    enquiryId: id,
    phoneNormalized: phone,
    customerName: name,
    customerPhone: '+91 $phone',
    kind: kind,
    monthDay: IstDate.monthDay(occasion),
    occasionDate: occasion,
    eventTypeValue: eventTypeValue,
    eventTypeLabel: eventTypeLabel,
    eventDate: eventDate ?? occasion,
    person: person,
    merged: merged,
    remindersOn: remindersOn,
  );
}

void main() {
  // 9 Oct 2026, 10:00 IST.
  final now = DateTime.utc(2026, 10, 9, 4, 30);

  group('nextOccurrence', () {
    test('later this year', () {
      expect(PastCustomers.nextOccurrence('12-12', now), ist(2026, 12, 12));
    });

    test('today counts as the next occurrence', () {
      expect(PastCustomers.nextOccurrence('10-09', now), ist(2026, 10, 9));
    });

    test('already passed this year → next year', () {
      expect(PastCustomers.nextOccurrence('10-08', now), ist(2027, 10, 8));
      expect(PastCustomers.nextOccurrence('01-15', now), ist(2027, 1, 15));
    });

    test('uses the IST calendar day near midnight UTC', () {
      // 8 Oct 2026 20:00 UTC = 9 Oct 01:30 IST → 10-08 already passed.
      final lateUtc = DateTime.utc(2026, 10, 8, 20);
      expect(PastCustomers.nextOccurrence('10-08', lateUtc), ist(2027, 10, 8));
    });

    test('Feb 29 → Feb 28 in non-leap years, Feb 29 in leap years', () {
      expect(PastCustomers.nextOccurrence('02-29', now), ist(2027, 2, 28));
      final march2027 = DateTime.utc(2027, 3, 1, 6);
      expect(PastCustomers.nextOccurrence('02-29', march2027), ist(2028, 2, 29));
    });

    test('invalid month-day → null', () {
      expect(PastCustomers.nextOccurrence('13-01', now), isNull);
      expect(PastCustomers.nextOccurrence('04-31', now), isNull);
      expect(PastCustomers.nextOccurrence('xx', now), isNull);
    });
  });

  group('nth', () {
    test('years between the original occasion and the occurrence', () {
      expect(PastCustomers.nthFor(ist(2024, 12, 12), ist(2026, 12, 12)), 2);
      expect(PastCustomers.nthFor(ist(2025, 12, 31), ist(2026, 12, 31)), 1);
    });

    test('event within the last year → 1st anniversary shown with the year', () {
      final row = PastCustomers.rowFor(source(occasion: ist(2026, 3, 20)), now)!;
      expect(row.nextDate, ist(2027, 3, 20));
      expect(row.nth, 1);
      expect(row.occasionText, '1st wedding anniversary · 20 Mar 2027');
      expect(row.reminderDocId, '9876543210_wedding_anniversary_2027');
    });

    test('older event → nth without the year', () {
      final row = PastCustomers.rowFor(source(occasion: ist(2024, 12, 12)), now)!;
      expect(row.nth, 2);
      expect(row.daysUntil, 64);
      expect(row.occasionText, '2nd wedding anniversary · 12 Dec');
      expect(row.whenText, 'In 64 days');
    });

    test('event completed today rolls to next year (1st anniversary)', () {
      final row = PastCustomers.rowFor(source(occasion: ist(2026, 10, 9)), now)!;
      expect(row.nextDate, ist(2027, 10, 9));
      expect(row.nth, 1);
    });

    test('anniversary today', () {
      final row = PastCustomers.rowFor(source(occasion: ist(2023, 10, 9)), now)!;
      expect(row.nth, 3);
      expect(row.daysUntil, 0);
      expect(row.whenText, 'Today');
    });
  });

  group('build (filter, dedupe, sort)', () {
    test('hides merged, reminders-off and opted-out customers', () {
      final rows = PastCustomers.build(
        [
          source(id: 'a', phone: '9000000001', occasion: ist(2024, 11, 1), merged: true),
          source(id: 'b', phone: '9000000002', occasion: ist(2024, 11, 1), remindersOn: false),
          source(id: 'c', phone: '9000000003', occasion: ist(2024, 11, 1)),
          source(id: 'd', phone: '9000000004', occasion: ist(2024, 11, 1)),
        ],
        now: now,
        optedOutPhones: {'9000000003'},
      );
      expect(rows.map((r) => r.source.enquiryId), ['d']);
    });

    test('one row per (phone, kind), the wedding itself wins over haldi', () {
      final rows = PastCustomers.build([
        source(
          id: 'haldi',
          occasion: ist(2024, 12, 12),
          eventTypeValue: 'haldi',
          eventTypeLabel: 'Haldi',
          eventDate: ist(2024, 12, 10),
        ),
        source(id: 'wedding', occasion: ist(2024, 12, 12)),
        source(
          id: 'bday',
          kind: OccasionKind.birthday,
          occasion: ist(2025, 1, 5),
          eventTypeValue: 'birthday',
          eventTypeLabel: 'Birthday',
        ),
      ], now: now);
      expect(rows.map((r) => r.source.enquiryId), ['wedding', 'bday']);
    });

    test('same kind: filled-in person, then latest event wins', () {
      final rows = PastCustomers.build([
        source(
          id: 'old',
          kind: OccasionKind.birthday,
          occasion: ist(2023, 11, 1),
          eventTypeValue: 'birthday',
          eventTypeLabel: 'Birthday',
        ),
        source(
          id: 'new',
          kind: OccasionKind.birthday,
          occasion: ist(2024, 11, 1),
          eventTypeValue: 'birthday',
          eventTypeLabel: 'Birthday',
        ),
      ], now: now);
      expect(rows.single.source.enquiryId, 'new');

      final withPerson = PastCustomers.build([
        source(
          id: 'new',
          kind: OccasionKind.birthday,
          occasion: ist(2024, 11, 1),
          eventTypeValue: 'birthday',
          eventTypeLabel: 'Birthday',
        ),
        source(
          id: 'named',
          kind: OccasionKind.birthday,
          occasion: ist(2023, 11, 1),
          eventTypeValue: 'birthday',
          eventTypeLabel: 'Birthday',
          person: 'Aarav',
        ),
      ], now: now);
      expect(withPerson.single.source.enquiryId, 'named');
    });

    test('short phones are never merged together', () {
      final rows = PastCustomers.build([
        source(id: 'x', phone: '', occasion: ist(2024, 11, 1)),
        source(id: 'y', phone: '', occasion: ist(2024, 11, 2)),
      ], now: now);
      expect(rows.length, 2);
    });

    test('sorted by next occurrence, soonest first, then name', () {
      final rows = PastCustomers.build([
        source(id: 'jan', phone: '9000000001', name: 'Zed', occasion: ist(2024, 1, 15)),
        source(id: 'dec', phone: '9000000002', name: 'Bea', occasion: ist(2024, 12, 12)),
        source(id: 'oct', phone: '9000000003', name: 'Cal', occasion: ist(2024, 10, 9)),
        source(id: 'dec2', phone: '9000000004', name: 'Abe', occasion: ist(2023, 12, 12)),
      ], now: now);
      expect(rows.map((r) => r.source.enquiryId), ['oct', 'dec2', 'dec', 'jan']);
    });
  });

  group('search', () {
    final rows = PastCustomers.build([
      source(id: 'a', phone: '9876543210', name: 'Ayesha Khan', occasion: ist(2024, 11, 1)),
      source(id: 'b', phone: '9123456789', name: 'Rahul Mehta', occasion: ist(2024, 11, 2)),
    ], now: now);

    test('by name (case-insensitive) and by phone digits', () {
      expect(PastCustomers.search(rows, '').length, 2);
      expect(PastCustomers.search(rows, 'rahul').single.source.enquiryId, 'b');
      expect(PastCustomers.search(rows, '98765').single.source.enquiryId, 'a');
      expect(PastCustomers.search(rows, 'nobody'), isEmpty);
    });
  });

  group('fromEnquiry', () {
    test('reads the stamp and enquiry fields', () {
      final s = PastCustomerOccasion.fromEnquiry('e9', {
        'customerName': 'Ayesha Khan',
        'customerPhone': '+91 98765 43210',
        'occasionKind': 'wedding_anniversary',
        'occasionDate': Timestamp.fromDate(ist(2024, 12, 12)),
        'occasionMonthDay': '12-12',
        'eventTypeValue': 'wedding_ceremony',
        'assignedTo': 'u1',
      })!;
      expect(s.phoneNormalized, '9876543210');
      expect(s.kind, OccasionKind.weddingAnniversary);
      expect(s.eventTypeLabel, 'Wedding Ceremony');
      expect(s.remindersOn, isTrue);
      expect(s.merged, isFalse);
    });

    test('flags merged duplicates and reminders off; null without a stamp', () {
      final merged = PastCustomerOccasion.fromEnquiry('e1', {
        'occasionKind': 'birthday',
        'occasionDate': Timestamp.fromDate(ist(2024, 1, 1)),
        'occasionMonthDay': '01-01',
        'lostReason': 'duplicate',
        'occasionReminders': false,
      })!;
      expect(merged.merged, isTrue);
      expect(merged.remindersOn, isFalse);
      expect(PastCustomerOccasion.fromEnquiry('e2', {'customerName': 'X'}), isNull);
    });
  });
}
