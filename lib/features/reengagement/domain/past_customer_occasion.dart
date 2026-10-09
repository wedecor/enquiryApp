import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/utils/phone_normalizer.dart';
import '../../enquiries/domain/event_functions.dart';
import 'enquiry_occasion.dart';
import 'occasion_kind.dart';
import 'occasion_reminder.dart';

/// A completed enquiry with a server occasion stamp, as listed on
/// "Upcoming occasions → All past customers".
///
/// Mirrors `toReminderSource` in functions/src/reengagement.ts.
class PastCustomerOccasion {
  const PastCustomerOccasion({
    required this.enquiryId,
    required this.phoneNormalized,
    required this.customerName,
    required this.kind,
    required this.monthDay,
    required this.occasionDate,
    required this.eventTypeLabel,
    this.customerPhone,
    this.person,
    this.eventTypeValue,
    this.eventDate,
    this.assignedTo,
    this.merged = false,
    this.remindersOn = true,
  });

  final String enquiryId;
  final String phoneNormalized;
  final String customerName;
  final String? customerPhone;
  final OccasionKind kind;

  /// `occasionMonthDay` (`MM-DD`, IST).
  final String monthDay;

  /// The original occasion date (00:00 IST).
  final DateTime occasionDate;
  final String? person;
  final String? eventTypeValue;
  final String eventTypeLabel;
  final DateTime? eventDate;
  final String? assignedTo;
  final bool merged;
  final bool remindersOn;

  /// Null when the enquiry has no (valid) occasion stamp.
  static PastCustomerOccasion? fromEnquiry(String id, Map<String, dynamic> data) {
    String? str(String key) {
      final v = data[key];
      return v is String && v.trim().isNotEmpty ? v.trim() : null;
    }

    DateTime? date(String key) {
      final v = data[key];
      if (v is Timestamp) return v.toDate();
      if (v is DateTime) return v;
      return null;
    }

    final kind = OccasionKind.fromValue(str(EnquiryOccasion.kindField));
    final occasionDate = date(EnquiryOccasion.dateField);
    final monthDay = str(EnquiryOccasion.monthDayField);
    if (kind == null || occasionDate == null || monthDay == null) return null;
    if (PastCustomers.parseMonthDay(monthDay) == null) return null;

    final eventTypeValue = str('eventTypeValue') ?? str('eventType');
    return PastCustomerOccasion(
      enquiryId: id,
      phoneNormalized: str('phoneNormalized') ?? normalizePhone(str('customerPhone')),
      customerName: str('customerName') ?? 'Customer',
      customerPhone: str('customerPhone') ?? str('whatsappNumber'),
      kind: kind,
      monthDay: monthDay,
      occasionDate: occasionDate,
      person: str(EnquiryOccasion.personField),
      eventTypeValue: eventTypeValue,
      eventTypeLabel: str('eventTypeLabel') ?? PastCustomers.titleCase(eventTypeValue),
      eventDate: date('eventDate'),
      assignedTo: str('assignedTo'),
      merged: data['mergedInto'] != null || data['lostReason'] == 'duplicate',
      remindersOn: data[EnquiryOccasion.remindersField] != false,
    );
  }
}

/// One row of the past-customers list: the source enquiry and its next yearly date.
class PastCustomerRow {
  const PastCustomerRow({
    required this.source,
    required this.nextDate,
    required this.nth,
    required this.daysUntil,
  });

  final PastCustomerOccasion source;

  /// Next occurrence of the occasion, today or later (00:00 IST).
  final DateTime nextDate;

  /// Which anniversary [nextDate] is (1 = first).
  final int nth;

  /// Calendar days from today (IST) to [nextDate]; 0 = today.
  final int daysUntil;

  /// IST calendar year of [nextDate] (the reminder doc's year).
  int get year => IstDate.calendar(nextDate).year;

  /// `reminders/{phone}_{kind}_{year}` for this occurrence.
  String get reminderDocId => '${source.phoneNormalized}_${source.kind.value}_$year';

  /// "2nd wedding anniversary · 12 Dec"; the first anniversary also shows the
  /// year ("1st wedding anniversary · 12 Dec 2027").
  String get occasionText {
    final short = IstDate.short(nextDate);
    return OccasionReminder.describeRow(
      kind: source.kind,
      nth: nth,
      person: source.person,
      eventTypeLabel: source.eventTypeLabel,
      shortDate: nth == 1 ? '$short $year' : short,
    );
  }

  /// "Today", "Tomorrow", "In 12 days".
  String get whenText {
    if (daysUntil <= 0) return 'Today';
    if (daysUntil == 1) return 'Tomorrow';
    return 'In $daysUntil days';
  }
}

/// Pure helpers behind the past-customers list (no Firebase, no clock).
class PastCustomers {
  PastCustomers._();

  static const int minPhoneDigits = 7;

  static bool isLeapYear(int year) => (year % 4 == 0 && year % 100 != 0) || year % 400 == 0;

  /// `MM-DD` → (month, day), or null when malformed / impossible.
  static (int, int)? parseMonthDay(String monthDay) {
    final match = RegExp(r'^(\d{2})-(\d{2})$').firstMatch(monthDay);
    if (match == null) return null;
    final month = int.parse(match.group(1)!);
    final day = int.parse(match.group(2)!);
    if (month < 1 || month > 12 || day < 1) return null;
    // Validate against a leap year so 02-29 is accepted.
    final probe = DateTime.utc(2024, month, day);
    if (probe.month != month) return null;
    return (month, day);
  }

  /// 00:00 IST of `MM-DD` in [year] (Feb 29 → Feb 28 in non-leap years), or
  /// null when invalid. Mirrors `occasionDateIn` in reengagementLogic.ts.
  static DateTime? occasionDateIn(String monthDay, int year) {
    final parsed = parseMonthDay(monthDay);
    if (parsed == null) return null;
    final (month, rawDay) = parsed;
    final day = month == 2 && rawDay == 29 && !isLeapYear(year) ? 28 : rawDay;
    return IstDate.startOfDay(year, month, day);
  }

  /// Next occurrence of [monthDay] on or after today (IST) as 00:00 IST.
  static DateTime? nextOccurrence(String monthDay, DateTime now) {
    final today = IstDate.todayStart(now);
    final year = IstDate.calendar(now).year;
    final thisYear = occasionDateIn(monthDay, year);
    if (thisYear == null) return null;
    if (!thisYear.isBefore(today)) return thisYear;
    return occasionDateIn(monthDay, year + 1);
  }

  /// Years between the original occasion and [occurrence] (IST calendar years).
  static int nthFor(DateTime originalOccasion, DateTime occurrence) =>
      IstDate.calendar(occurrence).year - IstDate.calendar(originalOccasion).year;

  /// Next occurrence that is at least the 1st anniversary (an event completed
  /// today rolls to next year), with its nth and days from today.
  static PastCustomerRow? rowFor(PastCustomerOccasion source, DateTime now) {
    var next = nextOccurrence(source.monthDay, now);
    if (next == null) return null;
    var nth = nthFor(source.occasionDate, next);
    if (nth < 1) {
      final rolled = occasionDateIn(source.monthDay, IstDate.calendar(next).year + 1);
      if (rolled == null) return null;
      next = rolled;
      nth = nthFor(source.occasionDate, next);
      if (nth < 1) return null; // occasion stamped in the future
    }
    final days = (next.difference(IstDate.todayStart(now)).inHours / 24).round();
    return PastCustomerRow(source: source, nextDate: next, nth: nth, daysUntil: days);
  }

  /// Same ranking as `compareReminderSources` (reengagementLogic.ts): the wedding
  /// itself, then a filled-in person, then the latest event, then id.
  static int compareSources(PastCustomerOccasion a, PastCustomerOccasion b) {
    final wa = isWeddingAnchorType(a.eventTypeValue, a.eventTypeLabel) ? 0 : 1;
    final wb = isWeddingAnchorType(b.eventTypeValue, b.eventTypeLabel) ? 0 : 1;
    if (wa != wb) return wa - wb;
    final pa = a.person != null ? 0 : 1;
    final pb = b.person != null ? 0 : 1;
    if (pa != pb) return pa - pb;
    final da = a.eventDate ?? a.occasionDate;
    final db = b.eventDate ?? b.occasionDate;
    final byDate = db.compareTo(da);
    if (byDate != 0) return byDate;
    return a.enquiryId.compareTo(b.enquiryId);
  }

  /// Filters out merged duplicates, reminders-off enquiries and opted-out
  /// customers, keeps one enquiry per (phone, kind), and sorts by the next
  /// occurrence (soonest first, then name).
  static List<PastCustomerRow> build(
    Iterable<PastCustomerOccasion> sources, {
    required DateTime now,
    Set<String> optedOutPhones = const {},
  }) {
    final groups = <String, List<PastCustomerOccasion>>{};
    for (final s in sources) {
      if (s.merged || !s.remindersOn) continue;
      if (s.phoneNormalized.isNotEmpty && optedOutPhones.contains(s.phoneNormalized)) continue;
      final key = s.phoneNormalized.length >= minPhoneDigits
          ? '${s.phoneNormalized}|${s.kind.value}'
          : 'id:${s.enquiryId}';
      (groups[key] ??= []).add(s);
    }
    final rows = <PastCustomerRow>[];
    for (final list in groups.values) {
      list.sort(compareSources);
      final row = rowFor(list.first, now);
      if (row != null) rows.add(row);
    }
    rows.sort((a, b) {
      final byDate = a.nextDate.compareTo(b.nextDate);
      if (byDate != 0) return byDate;
      final byName = a.source.customerName.toLowerCase().compareTo(
        b.source.customerName.toLowerCase(),
      );
      if (byName != 0) return byName;
      return a.source.enquiryId.compareTo(b.source.enquiryId);
    });
    return rows;
  }

  /// Case-insensitive name match, or digit match against the phone.
  static List<PastCustomerRow> search(List<PastCustomerRow> rows, String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return rows;
    final digits = q.replaceAll(RegExp('[^0-9]'), '');
    return rows
        .where((r) {
          if (r.source.customerName.toLowerCase().contains(q)) return true;
          if (digits.length < 3) return false;
          final phone = r.source.customerPhone?.replaceAll(RegExp('[^0-9]'), '') ?? '';
          return r.source.phoneNormalized.contains(digits) || phone.contains(digits);
        })
        .toList(growable: false);
  }

  /// "wedding_ceremony" → "Wedding Ceremony"; "Event" when blank (server's eventTypeLabelOf).
  static String titleCase(String? value) {
    final words = (value ?? '')
        .replaceAll(RegExp('[_-]+'), ' ')
        .split(' ')
        .where((w) => w.isNotEmpty)
        .map((w) => '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}')
        .toList();
    return words.isEmpty ? 'Event' : words.join(' ');
  }
}
