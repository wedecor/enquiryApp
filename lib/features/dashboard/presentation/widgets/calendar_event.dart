import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/constants/status_vocabulary.dart';
import '../../../enquiries/domain/event_functions.dart';

/// Calendar Event Model — one entry per FUNCTION of a booking, on that function's day.
class CalendarEvent {
  final String enquiryId;
  final String customerName;

  /// Event type label; "Haldi (1/4)" for a function of a multi-function booking.
  final String eventType;
  final DateTime eventDate;
  final String? eventLocation;
  final String status;
  final DateTime createdAt;
  final String? customerPhone;

  /// 0-based position of this function in the booking, and the booking's function count.
  final int functionIndex;
  final int functionCount;

  CalendarEvent({
    required this.enquiryId,
    required this.customerName,
    required this.eventType,
    required this.eventDate,
    this.eventLocation,
    required this.status,
    required this.createdAt,
    this.customerPhone,
    this.functionIndex = 0,
    this.functionCount = 1,
  });

  /// "Ayesha · Haldi (1/4)".
  String get title => '$customerName · $eventType';
}

DateTime? _calendarDate(Object? value) {
  if (value is DateTime) return value;
  if (value is Timestamp) return value.toDate();
  return null;
}

/// Expands one enquiry into calendar entries: one per function whose day falls in
/// [[windowStart], [windowEnd]) (legacy single-event enquiries: one entry on the
/// event date). Lost enquiries give none; completed functions older than 30 days
/// are dropped.
List<CalendarEvent> calendarEventsForEnquiry({
  required String enquiryId,
  required Map<String, dynamic> data,
  required DateTime windowStart,
  required DateTime windowEnd,
  required DateTime now,
}) {
  // Canonical status from statusValue (maps legacy confirmed → approved, etc.)
  final rawStatus = ((data['statusValue'] as String?) ?? 'new').toLowerCase();
  final status = EnquiryStatus.fromValue(rawStatus)?.value ?? rawStatus;
  // Only show: new, in_talks, approved, completed
  if (EnquiryStatus.isLost(status)) return const [];

  final functions = functionsOf(data);
  if (functions.isEmpty) return const [];
  final todayStart = DateTime(now.year, now.month, now.day);
  final count = functions.length;
  final legacyLabel =
      (data['eventTypeLabel'] as String?) ??
      (data['eventTypeValue'] as String?) ??
      (data['eventType'] as String?) ??
      'Unknown';
  final customerName = (data['customerName'] as String?) ?? 'Unknown';
  final createdAt = _calendarDate(data['createdAt']);
  final topLocation = data['eventLocation'] as String?;

  final events = <CalendarEvent>[];
  for (var i = 0; i < count; i++) {
    final f = functions[i];
    final day = f.day;
    if (day.isBefore(windowStart) || !day.isBefore(windowEnd)) continue;
    // Keep recent completed events for reference (last 30 days only).
    if (status == EnquiryStatus.completed.value &&
        day.isBefore(todayStart) &&
        todayStart.difference(day).inDays > 30) {
      continue;
    }
    // Past "new" / "in_talks" events are not filtered here: the nightly
    // autoExpireEnquiries function closes them once their last function has passed.
    final single = count == 1;
    events.add(
      CalendarEvent(
        enquiryId: enquiryId,
        customerName: customerName,
        eventType: single ? legacyLabel : '${f.label} (${i + 1}/$count)',
        // Legacy docs keep their stored instant (time of day included).
        eventDate: single ? (_calendarDate(data['eventDate']) ?? day) : day,
        eventLocation: single ? topLocation : f.location,
        status: status,
        createdAt: createdAt ?? day,
        customerPhone: data['customerPhone'] as String?,
        functionIndex: i,
        functionCount: count,
      ),
    );
  }
  return events;
}
