import 'package:cloud_firestore/cloud_firestore.dart';

import '../../enquiries/domain/event_functions.dart';
import 'occasion_kind.dart';
import 'occasion_reminder.dart';

/// The yearly-reminder fields of an enquiry, as shown on its details screen.
///
/// `occasionKind` / `occasionDate` / `occasionMonthDay` are stamped by the server
/// when the enquiry becomes completed (onEnquiryCompletedStampOccasion,
/// autoExpireEnquiries, backfill). Until then the card previews the defaults
/// (kind from the event type, date = event date).
class EnquiryOccasion {
  const EnquiryOccasion({
    required this.kind,
    required this.stamped,
    required this.remindersOn,
    this.date,
    this.person,
    this.manual = false,
  });

  static const String kindField = 'occasionKind';
  static const String dateField = 'occasionDate';
  static const String monthDayField = 'occasionMonthDay';
  static const String personField = 'occasionPerson';
  static const String remindersField = 'occasionReminders';
  static const String manualField = 'occasionManual';

  final OccasionKind kind;
  final DateTime? date;
  final String? person;

  /// False until the server stamped the enquiry.
  final bool stamped;

  /// `occasionReminders` (missing = on).
  final bool remindersOn;

  /// An admin set the date / kind by hand (never re-stamped automatically).
  final bool manual;

  factory EnquiryOccasion.fromEnquiry(Map<String, dynamic> data) {
    DateTime? date(Object? raw) {
      if (raw is Timestamp) return raw.toDate();
      if (raw is DateTime) return raw;
      return null;
    }

    final stampedKind = OccasionKind.fromValue(data[kindField] as String?);
    final stampedDate = date(data[dateField]);
    final person = data[personField];
    // Preview before stamping: the main function (wedding anchor) of a multi-function
    // booking, like the server's occasionEventOf; legacy: the event type and date.
    final rawFunctions = data['functions'];
    final main = rawFunctions is List && rawFunctions.isNotEmpty
        ? mainFunctionOf(functionsOf(data))
        : null;
    return EnquiryOccasion(
      kind:
          stampedKind ??
          (main != null
              ? OccasionKind.forEventType(main.eventType, main.eventTypeLabel)
              : OccasionKind.forEventType(
                  (data['eventTypeValue'] ?? data['eventType']) as String?,
                  data['eventTypeLabel'] as String?,
                )),
      date: stampedDate ?? main?.date ?? date(data['eventDate']),
      person: person is String && person.trim().isNotEmpty ? person.trim() : null,
      stamped: stampedKind != null && stampedDate != null,
      remindersOn: data[remindersField] != false,
      manual: data[manualField] == true,
    );
  }

  /// "Wedding anniversary · 12 Dec" (no ordinal: the card is about the yearly date).
  String get summary {
    final when = date == null ? '' : ' · ${IstDate.short(date!)}';
    return '${kind.label}$when';
  }

  /// Fields an admin edit writes (kind + date are then manual). [day] is the
  /// picked calendar date (local y/m/d); stored as 00:00 IST of that day.
  static Map<String, Object?> adminEditFields({
    required OccasionKind kind,
    required DateTime day,
    required String? person,
  }) {
    final instant = IstDate.startOfDay(day.year, day.month, day.day);
    return {
      kindField: kind.value,
      dateField: Timestamp.fromDate(instant),
      monthDayField: IstDate.monthDay(instant),
      manualField: true,
      personField: person,
    };
  }
}
