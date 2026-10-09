import 'package:cloud_firestore/cloud_firestore.dart';

import 'occasion_kind.dart';

/// IST calendar helpers (India has no DST). Occasion dates are stored at 00:00 IST.
class IstDate {
  IstDate._();

  static const Duration offset = Duration(hours: 5, minutes: 30);

  static const List<String> _shortMonths = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  static const List<String> _longMonths = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  /// [instant] as a UTC [DateTime] whose year/month/day are the IST calendar date.
  static DateTime calendar(DateTime instant) => instant.toUtc().add(offset);

  /// 00:00 IST of the calendar day y-m-d, as an instant.
  static DateTime startOfDay(int year, int month, int day) =>
      DateTime.utc(year, month, day).subtract(offset);

  /// 00:00 IST of today.
  static DateTime todayStart(DateTime now) {
    final ist = calendar(now);
    return startOfDay(ist.year, ist.month, ist.day);
  }

  /// `MM-DD` of [instant] in IST (matches `istMonthDayYear` in reengagementLogic.ts).
  static String monthDay(DateTime instant) {
    final ist = calendar(instant);
    return '${_pad2(ist.month)}-${_pad2(ist.day)}';
  }

  /// "12 Dec".
  static String short(DateTime instant) {
    final ist = calendar(instant);
    return '${ist.day} ${_shortMonths[ist.month - 1]}';
  }

  /// "12 December".
  static String long(DateTime instant) {
    final ist = calendar(instant);
    return '${ist.day} ${_longMonths[ist.month - 1]}';
  }

  static String _pad2(int n) => n < 10 ? '0$n' : '$n';
}

/// One yearly reminder at `reminders/{phone}_{kind}_{year}`, created by the daily
/// `scheduleReengagements` function (functions/src/reengagement.ts).
class OccasionReminder {
  const OccasionReminder({
    required this.id,
    required this.enquiryId,
    required this.phoneNormalized,
    required this.customerName,
    required this.kind,
    required this.nth,
    required this.eventTypeLabel,
    required this.status,
    this.customerPhone,
    this.occasionDate,
    this.person,
    this.assignedTo,
    this.sentAt,
  });

  static const String statusPending = 'pending';
  static const String statusSent = 'sent';
  static const String statusSkipped = 'skipped';

  static const String skipReasonManual = 'manual';
  static const String skipReasonOptOut = 'opt_out';

  final String id;
  final String enquiryId;
  final String phoneNormalized;
  final String customerName;
  final String? customerPhone;
  final OccasionKind kind;

  /// This year's occasion date (00:00 IST).
  final DateTime? occasionDate;

  /// Years since the original event (1 = first anniversary).
  final int nth;
  final String? person;
  final String eventTypeLabel;
  final String? assignedTo;
  final String status;
  final DateTime? sentAt;

  factory OccasionReminder.fromMap(String id, Map<String, dynamic> data) {
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

    final nth = data['nth'];
    return OccasionReminder(
      id: id,
      enquiryId: str('enquiryId') ?? '',
      phoneNormalized: str('phoneNormalized') ?? '',
      customerName: str('customerName') ?? 'Customer',
      customerPhone: str('customerPhone'),
      kind: OccasionKind.fromValue(str('occasionKind')) ?? OccasionKind.celebration,
      occasionDate: date('occasionDate'),
      nth: nth is num && nth >= 1 ? nth.toInt() : 1,
      person: str('person'),
      eventTypeLabel: str('eventTypeLabel') ?? 'Event',
      assignedTo: str('assignedTo'),
      status: str('status') ?? statusPending,
      sentAt: date('sentAt'),
    );
  }

  /// "12 Dec" in IST, or '' when unknown.
  String get shortDate => occasionDate == null ? '' : IstDate.short(occasionDate!);

  /// Row headline, e.g. "2nd wedding anniversary · 12 Dec".
  String get occasionText => describeRow(
    kind: kind,
    nth: nth,
    person: person,
    eventTypeLabel: eventTypeLabel,
    shortDate: shortDate,
  );

  /// Pure formatter behind [occasionText].
  static String describeRow({
    required OccasionKind kind,
    required int nth,
    required String? person,
    required String eventTypeLabel,
    required String shortDate,
  }) {
    final label = kind.describe(nth: nth, person: person, eventTypeLabel: eventTypeLabel);
    return shortDate.isEmpty ? label : '$label · $shortDate';
  }
}
