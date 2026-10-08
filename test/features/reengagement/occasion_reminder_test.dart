import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:we_decor_enquiries/features/reengagement/domain/enquiry_occasion.dart';
import 'package:we_decor_enquiries/features/reengagement/domain/occasion_kind.dart';
import 'package:we_decor_enquiries/features/reengagement/domain/occasion_reminder.dart';
import 'package:we_decor_enquiries/features/reengagement/domain/reengagement_stats.dart';

void main() {
  group('OccasionReminder row text', () {
    test('wedding anniversary with ordinal and IST short date', () {
      final reminder = OccasionReminder.fromMap('9876543210_wedding_anniversary_2026', {
        'enquiryId': 'e1',
        'phoneNormalized': '9876543210',
        'customerName': 'Ayesha Khan',
        'customerPhone': '+91 98765 43210',
        'occasionKind': 'wedding_anniversary',
        // 12 Dec 2026 00:00 IST = 11 Dec 18:30 UTC.
        'occasionDate': Timestamp.fromDate(DateTime.utc(2026, 12, 11, 18, 30)),
        'nth': 2,
        'eventTypeLabel': 'Haldi',
        'status': 'pending',
      });
      expect(reminder.kind, OccasionKind.weddingAnniversary);
      expect(reminder.shortDate, '12 Dec');
      expect(reminder.occasionText, '2nd wedding anniversary · 12 Dec');
      expect(reminder.status, OccasionReminder.statusPending);
    });

    test('birthday with and without a person', () {
      String row(String? person) => OccasionReminder.describeRow(
        kind: OccasionKind.birthday,
        nth: 1,
        person: person,
        eventTypeLabel: 'Birthday',
        shortDate: '3 Jan',
      );
      expect(row('Aarav'), "Aarav's birthday · 3 Jan");
      expect(row(null), 'Birthday · 3 Jan');
    });

    test('generic kinds count years since the event', () {
      expect(
        OccasionKind.celebration.describe(nth: 2, eventTypeLabel: 'Diwali Party'),
        '2 years since Diwali Party',
      );
      expect(OccasionKind.baby.describe(nth: 1, eventTypeLabel: 'Baby Shower'), '1 year since Baby Shower');
      expect(OccasionKind.home.describe(nth: 3), '3rd housewarming anniversary');
    });

    test('missing fields fall back safely', () {
      final reminder = OccasionReminder.fromMap('x', const {});
      expect(reminder.kind, OccasionKind.celebration);
      expect(reminder.nth, 1);
      expect(reminder.customerName, 'Customer');
      expect(reminder.occasionText, '1 year since Event');
    });
  });

  group('IstDate', () {
    test('month-day and Feb 29', () {
      expect(IstDate.monthDay(IstDate.startOfDay(2028, 2, 29)), '02-29');
      expect(IstDate.monthDay(DateTime.utc(2026, 12, 11, 18, 30)), '12-12');
      expect(IstDate.monthDay(DateTime.utc(2026, 12, 11, 18, 29)), '12-11');
    });
  });

  group('EnquiryOccasion', () {
    test('previews defaults before the server stamps', () {
      final occasion = EnquiryOccasion.fromEnquiry({
        'eventTypeValue': 'haldi',
        'eventTypeLabel': 'Haldi',
        'eventDate': Timestamp.fromDate(DateTime.utc(2026, 12, 9, 18, 30)),
      });
      expect(occasion.kind, OccasionKind.weddingAnniversary);
      expect(occasion.stamped, isFalse);
      expect(occasion.remindersOn, isTrue);
      expect(occasion.summary, 'Wedding anniversary · 10 Dec');
    });

    test('uses the stamped kind/date and person', () {
      final occasion = EnquiryOccasion.fromEnquiry({
        'eventTypeValue': 'haldi',
        'eventDate': Timestamp.fromDate(DateTime.utc(2026, 12, 9, 18, 30)),
        'occasionKind': 'wedding_anniversary',
        'occasionDate': Timestamp.fromDate(DateTime.utc(2026, 12, 11, 18, 30)),
        'occasionPerson': ' Ayesha & Imran ',
        'occasionReminders': false,
      });
      expect(occasion.stamped, isTrue);
      expect(occasion.summary, 'Wedding anniversary · 12 Dec');
      expect(occasion.person, 'Ayesha & Imran');
      expect(occasion.remindersOn, isFalse);
    });

    test('admin edit stores 00:00 IST of the picked day and marks it manual', () {
      final fields = EnquiryOccasion.adminEditFields(
        kind: OccasionKind.birthday,
        day: DateTime(2024, 2, 29),
        person: 'Aarav',
      );
      expect(fields['occasionKind'], 'birthday');
      expect(fields['occasionMonthDay'], '02-29');
      expect((fields['occasionDate']! as Timestamp).toDate().toUtc(), DateTime.utc(2024, 2, 28, 18, 30));
      expect(fields['occasionManual'], isTrue);
    });
  });

  group('ReengagementStats', () {
    test('counts customers who enquired again within 60 days of the wish', () {
      final sentAt = DateTime(2026, 1, 1);
      final stats = ReengagementStats.compute(
        sent: [
          SentReminder(phoneNormalized: 'a', sentAt: sentAt),
          SentReminder(phoneNormalized: 'a', sentAt: sentAt), // two kinds, same customer
          SentReminder(phoneNormalized: 'b', sentAt: sentAt),
          SentReminder(phoneNormalized: 'c', sentAt: sentAt),
        ],
        enquiries: [
          EnquiryArrival(phoneNormalized: 'a', createdAt: DateTime(2026, 2, 1)),
          EnquiryArrival(phoneNormalized: 'b', createdAt: DateTime(2025, 12, 1)), // before
          EnquiryArrival(phoneNormalized: 'c', createdAt: DateTime(2026, 3, 15)), // > 60 days
        ],
      );
      expect(stats.sent, 4);
      expect(stats.customers, 3);
      expect(stats.cameBack, 1);
      expect(stats.comeBackRate, closeTo(1 / 3, 1e-9));
    });
  });
}
