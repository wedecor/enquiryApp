import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/constants/status_vocabulary.dart';
import 'filters_state.dart';

/// Client-side filter for enquiry documents (avoids composite Firestore indexes).
bool matchesEnquiryFilters(
  Map<String, dynamic> data,
  EnquiryFilters filters, {
  String? currentUserId,
}) {
  if (filters.statuses.isNotEmpty) {
    final rawStatus = _fieldString(data, 'statusValue', 'status');
    final canonical =
        EnquiryStatus.canonicalValue(rawStatus) ?? rawStatus.toLowerCase();
    final matches = filters.statuses.any((filter) {
      final filterCanonical =
          EnquiryStatus.canonicalValue(filter) ?? filter.toLowerCase();
      return filterCanonical == canonical;
    });
    if (!matches) return false;
  }

  if (filters.eventTypes.isNotEmpty) {
    final eventType = _fieldString(
      data,
      'eventTypeValue',
      'eventType',
    ).toLowerCase();
    final matchesType = filters.eventTypes.any(
      (t) => t.toLowerCase() == eventType,
    );
    if (!matchesType) return false;
  }

  if (filters.assigneeId != null) {
    final assignee = data['assignedTo'] as String?;
    final targetId = filters.assigneeId == 'current_user_id'
        ? currentUserId
        : filters.assigneeId;
    if (targetId == null || assignee != targetId) return false;
  }

  if (filters.dateRange != null) {
    final eventDate = _parseDate(data['eventDate']);
    if (eventDate == null) return false;
    final start = filters.dateRange!.start;
    final end = filters.dateRange!.end;
    if (eventDate.isBefore(start) || !eventDate.isBefore(end)) return false;
  }

  final query = filters.searchQuery?.trim().toLowerCase();
  if (query != null && query.isNotEmpty) {
    final haystack = [
      data['customerName'],
      data['customerPhone'],
      data['customerEmail'],
      data['notes'],
      data['description'],
      data['eventTypeLabel'],
      data['eventType'],
    ].whereType<String>().join(' ').toLowerCase();
    if (!haystack.contains(query)) return false;
  }

  return true;
}

String _fieldString(
  Map<String, dynamic> data,
  String primary,
  String fallback,
) {
  final value = data[primary] ?? data[fallback];
  if (value == null) return '';
  return value.toString().trim();
}

DateTime? _parseDate(dynamic value) {
  if (value == null) return null;
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value);
  return null;
}
