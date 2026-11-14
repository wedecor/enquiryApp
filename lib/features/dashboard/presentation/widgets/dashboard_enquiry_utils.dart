import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/status_vocabulary.dart';
import '../../../../core/utils/color_parsing.dart';
import '../../../enquiries/domain/event_functions.dart';
import '../../../reengagement/domain/occasion_reminder.dart';

/// Calendar days from today (IST) to the first upcoming function for follow-up.
/// Must match `FOLLOW_UP_LEAD_DAYS` in `functions/src/followUpsLogic.ts`.
const int kFollowUpLeadDays = 10;

DateTime? parseEnquiryDateTime(dynamic value) {
  if (value == null) return null;
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value);
  if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
  return null;
}

Color? parseDashboardColor(String? input) => parseDropdownColor(input);

Color? colorFromDynamic(dynamic value) {
  if (value == null) return null;
  if (value is Color) return value;
  if (value is int) {
    final normalized = value <= 0xFFFFFF ? 0xFF000000 | value : value;
    return Color(normalized);
  }
  if (value is String) {
    return parseDashboardColor(value);
  }
  return null;
}

int compareByCreatedDate(QueryDocumentSnapshot<Object?> a, QueryDocumentSnapshot<Object?> b) {
  final aData = a.data() as Map<String, dynamic>;
  final bData = b.data() as Map<String, dynamic>;

  final aCreated =
      parseEnquiryDateTime(aData['createdAt']) ?? DateTime.fromMillisecondsSinceEpoch(0);
  final bCreated =
      parseEnquiryDateTime(bData['createdAt']) ?? DateTime.fromMillisecondsSinceEpoch(0);

  return aCreated.compareTo(bCreated);
}

int compareByEventDate(QueryDocumentSnapshot<Object?> a, QueryDocumentSnapshot<Object?> b) {
  final aData = a.data() as Map<String, dynamic>;
  final bData = b.data() as Map<String, dynamic>;

  // Multi-function bookings sort by their next upcoming function.
  final now = DateTime.now();
  final aEvent = listSortDateOf(aData, now);
  final bEvent = listSortDateOf(bData, now);

  if (aEvent != null && bEvent != null) {
    return aEvent.compareTo(bEvent);
  }

  if (aEvent != null && bEvent == null) {
    return -1;
  }
  if (aEvent == null && bEvent != null) {
    return 1;
  }

  final aCreated =
      parseEnquiryDateTime(aData['createdAt']) ?? DateTime.fromMillisecondsSinceEpoch(0);
  final bCreated =
      parseEnquiryDateTime(bData['createdAt']) ?? DateTime.fromMillisecondsSinceEpoch(0);
  return aCreated.compareTo(bCreated);
}

int compareByNearestEventDate(
  QueryDocumentSnapshot<Object?> a,
  QueryDocumentSnapshot<Object?> b,
  DateTime now,
) {
  const int maxDiffMagnitude = 1 << 62;

  final aData = a.data() as Map<String, dynamic>;
  final bData = b.data() as Map<String, dynamic>;

  // Multi-function bookings sort by their next upcoming function.
  final aEvent = listSortDateOf(aData, now);
  final bEvent = listSortDateOf(bData, now);

  final aDiff = aEvent?.difference(now);
  final bDiff = bEvent?.difference(now);

  final aIsFuture = aDiff != null && !aDiff.isNegative;
  final bIsFuture = bDiff != null && !bDiff.isNegative;

  if (aIsFuture != bIsFuture) {
    return aIsFuture ? -1 : 1;
  }

  final aMagnitude = aDiff != null ? aDiff.inMilliseconds.abs() : maxDiffMagnitude;
  final bMagnitude = bDiff != null ? bDiff.inMilliseconds.abs() : maxDiffMagnitude;

  final magnitudeComparison = aMagnitude.compareTo(bMagnitude);
  if (magnitudeComparison != 0) {
    return magnitudeComparison;
  }

  if (aEvent != null && bEvent != null) {
    final eventComparison = aEvent.compareTo(bEvent);
    if (eventComparison != 0) {
      return eventComparison;
    }
  } else if (aEvent == null && bEvent != null) {
    return 1;
  } else if (aEvent != null && bEvent == null) {
    return -1;
  }

  final aCreated =
      parseEnquiryDateTime(aData['createdAt']) ?? DateTime.fromMillisecondsSinceEpoch(0);
  final bCreated =
      parseEnquiryDateTime(bData['createdAt']) ?? DateTime.fromMillisecondsSinceEpoch(0);
  return bCreated.compareTo(aCreated);
}

/// Digit strings to try for a phone search, so the country code / trunk zero
/// doesn't matter either way: "+91 98765 43210", "0 98765 43210" and
/// "9876543210" all find a number stored as "9876543210" or "+919876543210".
/// Partial input works too ("+91 98765" also tries "98765").
Set<String> phoneSearchVariants(String digits, {String rawQuery = ''}) {
  final variants = <String>{digits};
  // Full number typed with a country code: compare the last 10 digits.
  if (digits.length > 10) variants.add(digits.substring(digits.length - 10));
  // Partial number typed with an explicit +91 / 0091 prefix: drop the prefix.
  // (A bare "91…" isn't stripped — Indian mobiles can start with 91.)
  final raw = rawQuery.replaceAll(RegExp(r'\s'), '');
  if (raw.startsWith('+91') && digits.length > 2) variants.add(digits.substring(2));
  if (digits.startsWith('0091') && digits.length > 4) variants.add(digits.substring(4));
  // Trunk zero ("098765…"): mobiles never start with 0.
  if (digits.startsWith('0') && digits.length > 1) {
    variants.add(digits.replaceFirst(RegExp('^0+'), ''));
  }
  variants.remove('');
  return variants;
}

bool matchesEnquirySearchQuery(Map<String, dynamic> data, String searchQuery) {
  if (searchQuery.isEmpty) return true;

  final query = searchQuery.trim();
  final queryLower = query.toLowerCase();

  if (queryLower.isNotEmpty) {
    final lowerFields = <String>[
      (data['customerName'] as String? ?? '').toLowerCase(),
      (data['customerNameLower'] as String? ?? '').toLowerCase(),
      (data['textIndex'] as String? ?? '').toLowerCase(),
    ];
    if (lowerFields.any((field) => field.contains(queryLower))) {
      return true;
    }
  }

  final digitQuery = query.replaceAll(RegExp(r'\D'), '');
  if (digitQuery.isEmpty) {
    return false;
  }
  final digitQueries = phoneSearchVariants(digitQuery, rawQuery: query);

  bool matchesDigits(String? input) {
    if (input == null || input.isEmpty) return false;
    final cleaned = input.replaceAll(RegExp(r'\D'), '');
    return digitQueries.any(cleaned.contains);
  }

  return matchesDigits(data['customerPhone'] as String?) ||
      matchesDigits(data['whatsappNumber'] as String?) ||
      matchesDigits(data['phoneNormalized'] as String?);
}

/// IST calendar day as a UTC date at midnight (year/month/day = IST Y/M/D).
DateTime _istCalendarDay(DateTime instant) {
  final ist = IstDate.calendar(instant);
  return DateTime.utc(ist.year, ist.month, ist.day);
}

/// First function dated today or later (IST), else null. Multi-function bookings
/// use the earliest upcoming function; single-event uses `eventDate` via [functionsOf].
DateTime? earliestUpcomingFollowUpDay(Map<String, dynamic> enquiryData, DateTime now) {
  final today = _istCalendarDay(now);
  DateTime? best;
  for (final f in functionsOf(enquiryData)) {
    final day = _istCalendarDay(f.day);
    if (day.isBefore(today)) continue;
    if (best == null || day.isBefore(best)) best = day;
  }
  return best;
}

/// Follow Up tab / "Follow-ups" counter: In Talks whose first upcoming function
/// is exactly [kFollowUpLeadDays] calendar days after today (IST).
bool shouldShowReminder(Map<String, dynamic> enquiryData, DateTime now) {
  if (!EnquiryStatus.isInTalks(enquiryData['statusValue'] as String?)) {
    return false;
  }
  final upcoming = earliestUpcomingFollowUpDay(enquiryData, now);
  if (upcoming == null) return false;
  return upcoming.difference(_istCalendarDay(now)).inDays == kFollowUpLeadDays;
}

/// True when a call / WhatsApp / follow-up WhatsApp was logged on this enquiry today (IST).
bool isFollowUpContactedToday(Map<String, dynamic> enquiryData, DateTime now) {
  final at =
      parseEnquiryDateTime(enquiryData['lastContactAt']) ??
      parseEnquiryDateTime(enquiryData['lastReminderSentAt']);
  if (at == null) return false;
  final a = _istCalendarDay(at);
  final n = _istCalendarDay(now);
  return a.year == n.year && a.month == n.month && a.day == n.day;
}

/// Calendar days from [now]'s IST day to [eventDate]'s IST day (0 = today, negative = past).
int eventDayOffset(DateTime eventDate, DateTime now) {
  return _istCalendarDay(eventDate).difference(_istCalendarDay(now)).inDays;
}

/// Past-dated enquiries stay visible: they are flagged for follow-up, never auto-closed.
bool shouldShowInTalks(Map<String, dynamic> enquiryData) =>
    EnquiryStatus.isInTalks(enquiryData['statusValue'] as String?);

String formatAgeLabel(DateTime createdAt) {
  final age = DateTime.now().difference(createdAt);
  if (age.inMinutes < 1) return 'Just now';
  if (age.inMinutes < 60) return '${age.inMinutes}m old';
  if (age.inHours < 24) return '${age.inHours}h old';
  if (age.inDays < 7) return '${age.inDays}d old';
  final weeks = age.inDays ~/ 7;
  if (weeks < 5) return '${weeks}w old';
  final months = age.inDays ~/ 30;
  if (months < 12) return '${months}mo old';
  final years = age.inDays ~/ 365;
  return '${years}y old';
}

String formatDateLabel(DateTime? date) {
  if (date == null) return 'Date TBC';
  if (date.year <= 1971) return '—';
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  final year = date.year.toString();
  return '$day/$month/$year';
}

String? formatEventCountdownLabel(DateTime? date) {
  if (date == null) return null;
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final eventDay = DateTime(date.year, date.month, date.day);
  final days = eventDay.difference(today).inDays;

  if (days > 1) return 'In $days days';
  if (days == 1) return 'Tomorrow';
  if (days == 0) return 'Today';
  if (days == -1) return 'Yesterday';
  return '${days.abs()} days ago';
}

String formatDateForMessage(DateTime? date) {
  if (date == null) return '';
  const months = [
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
  final day = date.day.toString().padLeft(2, '0');
  final month = months[date.month - 1];
  final year = date.year.toString();
  return '$day $month $year';
}

String buildReminderMessage(
  String customerName,
  String eventType,
  DateTime createdAt,
  DateTime? eventDate,
) {
  final now = DateTime.now();
  final daysUntilEvent = eventDate != null ? eventDayOffset(eventDate, now) : null;

  // Follow Up tab only opens this at exactly [kFollowUpLeadDays] out.
  final String urgencyMessage;
  if (daysUntilEvent == kFollowUpLeadDays) {
    urgencyMessage = 'Your $eventType is in $kFollowUpLeadDays days';
  } else if (daysUntilEvent == 0) {
    urgencyMessage = 'Your $eventType is TODAY!';
  } else if (daysUntilEvent == 1) {
    urgencyMessage = 'Your $eventType is TOMORROW!';
  } else if (daysUntilEvent != null && daysUntilEvent > 1) {
    urgencyMessage = 'Your $eventType is in $daysUntilEvent days';
  } else {
    urgencyMessage = 'Your upcoming $eventType needs attention';
  }

  final formattedDate = eventDate != null ? formatDateForMessage(eventDate) : '';
  final dateText = formattedDate.isNotEmpty ? ' on $formattedDate' : '';

  return 'Hi $customerName!\n\n$urgencyMessage 🎉\n\nWe Decor is excited to be part of your $eventType$dateText and help make it absolutely magical.\n\nIf you\'ve already booked with another vendor, please reply "not interested" so we can update our records.\n\nOtherwise, feel free to reply to this message - we\'re here to answer any questions and help bring your vision to life! ✨\n\nTeam We Decor - Bringing dreams to life 💫';
}
