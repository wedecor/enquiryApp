import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/logging/logger.dart';

/// Another approved booking on the same event day (minimal fields only).
class ApprovedBooking {
  const ApprovedBooking({required this.id, required this.eventType, this.area});

  final String id;

  /// The enquiry's `eventLocation`, or null when blank.
  final String? area;

  /// Event type label, e.g. "Birthday".
  final String eventType;

  factory ApprovedBooking.fromMap(Map<String, dynamic> map) => ApprovedBooking(
    id: _string(map['id']) ?? '',
    area: _string(map['area']),
    eventType: _string(map['eventType']) ?? 'Event',
  );
}

/// Result of the `approvedOnDate` callable.
class ApprovedOnDateResult {
  const ApprovedOnDateResult({required this.count, required this.events});

  static const empty = ApprovedOnDateResult(count: 0, events: []);

  /// Other approved bookings that day (excludes the enquiry being changed).
  final int count;
  final List<ApprovedBooking> events;

  bool get hasClash => count > 0;

  /// Parses the callable's response. Android returns `Map<Object?, Object?>`
  /// (nested maps too), so every level is converted before reading.
  factory ApprovedOnDateResult.fromResponse(Object? data) {
    final map = _map(data);
    if (map == null) return empty;
    final rawEvents = map['events'];
    final events = rawEvents is List
        ? rawEvents
              .map(_map)
              .whereType<Map<String, dynamic>>()
              .map(ApprovedBooking.fromMap)
              .where((e) => e.id.isNotEmpty)
              .toList()
        : <ApprovedBooking>[];
    final count = (map['count'] as num?)?.toInt() ?? events.length;
    return ApprovedOnDateResult(count: count < 0 ? 0 : count, events: events);
  }
}

/// `YYYY-MM-DD` of [date]'s calendar day as the user sees it (local fields).
String bookingDayKey(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';

/// "12 Dec" — the year is added when [date] is not in [now]'s year.
String bookingDayLabel(DateTime date, {DateTime? now}) {
  final current = now ?? DateTime.now();
  return DateFormat(date.year == current.year ? 'd MMM' : 'd MMM yyyy').format(date);
}

/// Distinct non-blank areas (case-insensitive), first [max] then "+N more".
/// Returns '' when no area is known.
String bookingAreasSummary(List<String?> areas, {int max = 4}) {
  final seen = <String>{};
  final distinct = <String>[];
  for (final raw in areas) {
    final area = raw?.trim() ?? '';
    if (area.isEmpty) continue;
    if (seen.add(area.toLowerCase())) distinct.add(area);
  }
  if (distinct.isEmpty) return '';
  if (distinct.length <= max) return distinct.join(', ');
  return '${distinct.take(max).join(', ')} +${distinct.length - max} more';
}

/// Dialog text for the approved-date clash warning, e.g.
/// "You already have 2 approved events on 12 Dec (Whitefield, Yelahanka). Approve anyway?"
String approvedDateClashMessage({
  required DateTime date,
  required int count,
  required List<String?> areas,
  required bool isDateChange,
  DateTime? now,
}) {
  final noun = count == 1 ? 'approved event' : 'approved events';
  final summary = bookingAreasSummary(areas);
  final where = summary.isEmpty ? '' : ' ($summary)';
  final question = isDateChange ? 'Move it to this date anyway?' : 'Approve anyway?';
  return 'You already have $count $noun on ${bookingDayLabel(date, now: now)}$where. $question';
}

Map<String, dynamic>? _map(Object? raw) {
  if (raw is! Map) return null;
  return raw.map((key, value) => MapEntry(key.toString(), value));
}

String? _string(Object? raw) {
  if (raw is! String) return null;
  final trimmed = raw.trim();
  return trimmed.isEmpty ? null : trimmed;
}

/// Counts other APPROVED enquiries on an event day via the `approvedOnDate` callable
/// (asia-south1). Server-side because staff can only read their own enquiries.
class BookingClashService {
  const BookingClashService();

  /// Throws [FirebaseFunctionsException] on failure; see [approvedOnDateOrNull].
  Future<ApprovedOnDateResult> approvedOnDate(DateTime eventDate, {String? excludeEnquiryId}) async {
    final callable = FirebaseFunctions.instanceFor(
      region: 'asia-south1',
    ).httpsCallable('approvedOnDate');
    final response = await callable.call<dynamic>(<String, dynamic>{
      'date': bookingDayKey(eventDate),
      if (excludeEnquiryId != null) 'excludeEnquiryId': excludeEnquiryId,
    });
    return ApprovedOnDateResult.fromResponse(response.data);
  }

  /// Like [approvedOnDate] but never throws: failures are logged and return null, so a
  /// lookup problem can never block approving an enquiry or changing its date.
  Future<ApprovedOnDateResult?> approvedOnDateOrNull(
    DateTime eventDate, {
    String? excludeEnquiryId,
  }) async {
    try {
      // Offline / cold start: don't hold the status change hostage for long.
      return await approvedOnDate(
        eventDate,
        excludeEnquiryId: excludeEnquiryId,
      ).timeout(const Duration(seconds: 8));
    } catch (e, st) {
      Log.w('BookingClashService: lookup failed', data: {'error': e.toString()});
      Log.e('BookingClashService: lookup error', error: e, stackTrace: st);
      return null;
    }
  }
}

final bookingClashServiceProvider = Provider<BookingClashService>(
  (ref) => const BookingClashService(),
);
