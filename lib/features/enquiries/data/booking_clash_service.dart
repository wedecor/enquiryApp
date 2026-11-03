import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/logging/logger.dart';

/// Another approved booking on the same event day (minimal fields only).
class ApprovedBooking {
  const ApprovedBooking({required this.id, required this.eventType, this.area});

  final String id;

  /// The function's area (else its location text), or null when blank.
  final String? area;

  /// Event type label of the function on that day, e.g. "Birthday", "Haldi".
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

/// Approved FUNCTIONS (of other bookings) on one requested day.
class ApprovedDayClash {
  const ApprovedDayClash({required this.date, required this.count, required this.events});

  /// The requested day (local midnight).
  final DateTime date;
  final int count;
  final List<ApprovedBooking> events;

  bool get hasClash => count > 0;
}

/// Parses the `days` of an `approvedOnDate` response for the requested [dates].
///
/// An older server (no `days`) answers for the single legacy `date` only: that
/// result is used for the first requested day.
List<ApprovedDayClash> approvedDayClashesFromResponse(Object? data, List<DateTime> dates) {
  final map = _map(data);
  if (map == null || dates.isEmpty) return const [];
  final rawDays = map['days'];
  if (rawDays is! List) {
    final single = ApprovedOnDateResult.fromResponse(map);
    return [ApprovedDayClash(date: dates.first, count: single.count, events: single.events)];
  }
  final byKey = <String, ApprovedOnDateResult>{};
  for (final raw in rawDays) {
    final day = _map(raw);
    final key = day == null ? null : _string(day['date']);
    if (day == null || key == null) continue;
    byKey[key] = ApprovedOnDateResult.fromResponse(day);
  }
  return [
    for (final date in dates)
      ApprovedDayClash(
        date: date,
        count: byKey[bookingDayKey(date)]?.count ?? 0,
        events: byKey[bookingDayKey(date)]?.events ?? const [],
      ),
  ];
}

/// Distinct calendar days (local midnight) of [dates], ascending.
List<DateTime> distinctBookingDays(Iterable<DateTime> dates) {
  final days = <DateTime>{for (final d in dates) DateTime(d.year, d.month, d.day)}.toList()..sort();
  return days;
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

/// Dialog text when a booking's functions fall on days that already have approved
/// events. One clashing day reads like [approvedDateClashMessage]; several give
/// "12 Dec: 2 approved events (Whitefield, Yelahanka) · 13 Dec: 1 approved event
/// (Taj West End). Approve anyway?". Days without a clash are left out.
String approvedDatesClashMessage({
  required List<ApprovedDayClash> clashes,
  required bool isDateChange,
  DateTime? now,
}) {
  final hits = clashes.where((c) => c.hasClash).toList();
  if (hits.length == 1) {
    final c = hits.single;
    return approvedDateClashMessage(
      date: c.date,
      count: c.count,
      areas: [for (final e in c.events) e.area],
      isDateChange: isDateChange,
      now: now,
    );
  }
  final parts = hits.map((c) {
    final noun = c.count == 1 ? 'approved event' : 'approved events';
    final summary = bookingAreasSummary([for (final e in c.events) e.area]);
    final where = summary.isEmpty ? '' : ' ($summary)';
    return '${bookingDayLabel(c.date, now: now)}: ${c.count} $noun$where';
  });
  final question = isDateChange ? 'Save these dates anyway?' : 'Approve anyway?';
  return '${parts.join(' · ')}. $question';
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
  Future<ApprovedOnDateResult> approvedOnDate(
    DateTime eventDate, {
    String? excludeEnquiryId,
  }) async {
    final callable = FirebaseFunctions.instanceFor(
      region: 'asia-south1',
    ).httpsCallable('approvedOnDate');
    final response = await callable.call<dynamic>(<String, dynamic>{
      'date': bookingDayKey(eventDate),
      if (excludeEnquiryId != null) 'excludeEnquiryId': excludeEnquiryId,
    });
    return ApprovedOnDateResult.fromResponse(response.data);
  }

  /// Approved functions of other bookings on each of [dates] (distinct days; 10 per call).
  /// Throws [FirebaseFunctionsException] on failure; see [approvedOnDatesOrNull].
  Future<List<ApprovedDayClash>> approvedOnDates(
    List<DateTime> dates, {
    String? excludeEnquiryId,
  }) async {
    final days = distinctBookingDays(dates);
    final callable = FirebaseFunctions.instanceFor(
      region: 'asia-south1',
    ).httpsCallable('approvedOnDate');
    final result = <ApprovedDayClash>[];
    for (var i = 0; i < days.length; i += 10) {
      final chunk = days.sublist(i, i + 10 > days.length ? days.length : i + 10);
      final response = await callable.call<dynamic>(<String, dynamic>{
        // `date` keeps an older server (single day only) answering for the first day.
        'date': bookingDayKey(chunk.first),
        'dates': [for (final d in chunk) bookingDayKey(d)],
        if (excludeEnquiryId != null) 'excludeEnquiryId': excludeEnquiryId,
      });
      final data = response.data;
      final hasDays = data is Map && data['days'] is List;
      if (hasDays || chunk.length == 1) {
        result.addAll(approvedDayClashesFromResponse(data, chunk));
        continue;
      }
      // Older server: one call per day.
      result.addAll(approvedDayClashesFromResponse(data, chunk.sublist(0, 1)));
      for (final day in chunk.skip(1)) {
        final single = await approvedOnDate(day, excludeEnquiryId: excludeEnquiryId);
        result.add(ApprovedDayClash(date: day, count: single.count, events: single.events));
      }
    }
    return result;
  }

  /// Like [approvedOnDates] but never throws (null on failure), so a lookup problem can
  /// never block approving a booking or changing its function dates.
  Future<List<ApprovedDayClash>?> approvedOnDatesOrNull(
    List<DateTime> dates, {
    String? excludeEnquiryId,
  }) async {
    if (dates.isEmpty) return const [];
    try {
      return await approvedOnDates(
        dates,
        excludeEnquiryId: excludeEnquiryId,
      ).timeout(const Duration(seconds: 10));
    } catch (e, st) {
      Log.w('BookingClashService: lookup failed', data: {'error': e.toString()});
      Log.e('BookingClashService: lookup error', error: e, stackTrace: st);
      return null;
    }
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
