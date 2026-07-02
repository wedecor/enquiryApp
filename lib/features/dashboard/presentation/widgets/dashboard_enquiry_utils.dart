import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/status_vocabulary.dart';
import '../../../../core/utils/color_parsing.dart';

DateTime? parseEnquiryDateTime(dynamic value) {
  if (value == null) return null;
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
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

int compareByCreatedDate(
  QueryDocumentSnapshot<Object?> a,
  QueryDocumentSnapshot<Object?> b,
) {
  final aData = a.data() as Map<String, dynamic>;
  final bData = b.data() as Map<String, dynamic>;

  final aCreated =
      parseEnquiryDateTime(aData['createdAt']) ??
      DateTime.fromMillisecondsSinceEpoch(0);
  final bCreated =
      parseEnquiryDateTime(bData['createdAt']) ??
      DateTime.fromMillisecondsSinceEpoch(0);

  return aCreated.compareTo(bCreated);
}

int compareByEventDate(
  QueryDocumentSnapshot<Object?> a,
  QueryDocumentSnapshot<Object?> b,
) {
  final aData = a.data() as Map<String, dynamic>;
  final bData = b.data() as Map<String, dynamic>;

  final aEvent = parseEnquiryDateTime(aData['eventDate']);
  final bEvent = parseEnquiryDateTime(bData['eventDate']);

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
      parseEnquiryDateTime(aData['createdAt']) ??
      DateTime.fromMillisecondsSinceEpoch(0);
  final bCreated =
      parseEnquiryDateTime(bData['createdAt']) ??
      DateTime.fromMillisecondsSinceEpoch(0);
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

  final aEvent = parseEnquiryDateTime(aData['eventDate']);
  final bEvent = parseEnquiryDateTime(bData['eventDate']);

  final aDiff = aEvent?.difference(now);
  final bDiff = bEvent?.difference(now);

  final aIsFuture = aDiff != null && !aDiff.isNegative;
  final bIsFuture = bDiff != null && !bDiff.isNegative;

  if (aIsFuture != bIsFuture) {
    return aIsFuture ? -1 : 1;
  }

  final aMagnitude = aDiff != null
      ? aDiff.inMilliseconds.abs()
      : maxDiffMagnitude;
  final bMagnitude = bDiff != null
      ? bDiff.inMilliseconds.abs()
      : maxDiffMagnitude;

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
      parseEnquiryDateTime(aData['createdAt']) ??
      DateTime.fromMillisecondsSinceEpoch(0);
  final bCreated =
      parseEnquiryDateTime(bData['createdAt']) ??
      DateTime.fromMillisecondsSinceEpoch(0);
  return bCreated.compareTo(aCreated);
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

  bool matchesDigits(String? input) {
    if (input == null || input.isEmpty) return false;
    final cleaned = input.replaceAll(RegExp(r'\D'), '');
    return cleaned.contains(digitQuery);
  }

  return matchesDigits(data['customerPhone'] as String?) ||
      matchesDigits(data['whatsappNumber'] as String?) ||
      matchesDigits(data['phoneNormalized'] as String?);
}

bool shouldShowReminder(Map<String, dynamic> enquiryData, DateTime now) {
  final statusValueRaw = enquiryData['statusValue'] as String?;
  final statusValue = (statusValueRaw?.trim().isNotEmpty ?? false)
      ? statusValueRaw!.trim().toLowerCase()
      : 'new';

  if (statusValue != 'in_talks') {
    return false;
  }

  final eventDate = parseEnquiryDateTime(enquiryData['eventDate']);
  if (eventDate == null) {
    return false;
  }

  final todayStart = DateTime(now.year, now.month, now.day);
  final eventDateStart = DateTime(
    eventDate.year,
    eventDate.month,
    eventDate.day,
  );

  if (eventDateStart.isBefore(todayStart)) {
    return false;
  }

  final daysUntilEvent = eventDateStart.difference(todayStart).inDays;
  return daysUntilEvent >= 0 && daysUntilEvent < 21;
}

bool shouldShowInTalks(Map<String, dynamic> enquiryData, DateTime now) {
  if (!EnquiryStatus.isInTalks(enquiryData['statusValue'] as String?)) {
    return false;
  }

  final eventDate = parseEnquiryDateTime(enquiryData['eventDate']);

  if (eventDate == null) {
    final createdAt = parseEnquiryDateTime(enquiryData['createdAt']);
    if (createdAt != null) {
      final daysSinceCreation = now.difference(createdAt).inDays;
      return daysSinceCreation <= 30;
    }
    return true;
  }

  final todayStart = DateTime(now.year, now.month, now.day);
  final eventDateStart = DateTime(
    eventDate.year,
    eventDate.month,
    eventDate.day,
  );
  return eventDateStart.compareTo(todayStart) >= 0;
}

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
  final daysUntilEvent = eventDate?.difference(now).inDays;

  String urgencyMessage;
  if (daysUntilEvent != null && daysUntilEvent >= 0 && daysUntilEvent < 21) {
    if (daysUntilEvent == 0) {
      urgencyMessage = 'Your $eventType is TODAY!';
    } else if (daysUntilEvent == 1) {
      urgencyMessage = 'Your $eventType is TOMORROW!';
    } else {
      urgencyMessage = 'Your $eventType is in $daysUntilEvent days';
    }
  } else {
    urgencyMessage = 'Your upcoming $eventType needs attention';
  }

  final formattedDate = eventDate != null
      ? formatDateForMessage(eventDate)
      : '';
  final dateText = formattedDate.isNotEmpty ? ' on $formattedDate' : '';

  return 'Hi $customerName!\n\n$urgencyMessage 🎉\n\nWe Decor is excited to be part of your $eventType$dateText and help make it absolutely magical.\n\nIf you\'ve already booked with another vendor, please reply "not interested" so we can update our records.\n\nOtherwise, feel free to reply to this message - we\'re here to answer any questions and help bring your vision to life! ✨\n\nTeam We Decor - Bringing dreams to life 💫';
}
