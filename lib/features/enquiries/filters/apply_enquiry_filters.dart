import '../../../core/constants/status_vocabulary.dart';
import '../../dashboard/presentation/widgets/dashboard_enquiry_utils.dart';
import '../domain/event_functions.dart';
import 'filters_state.dart';

/// Client-side filter for enquiry documents (avoids composite Firestore indexes).
bool matchesEnquiryFilters(
  Map<String, dynamic> data,
  EnquiryFilters filters, {
  String? currentUserId,
}) {
  if (filters.statuses.isNotEmpty) {
    final rawStatus = _fieldString(data, 'statusValue', 'status');
    final canonical = EnquiryStatus.canonicalValue(rawStatus) ?? rawStatus.toLowerCase();
    final matches = filters.statuses.any((filter) {
      final filterCanonical = EnquiryStatus.canonicalValue(filter) ?? filter.toLowerCase();
      return filterCanonical == canonical;
    });
    if (!matches) return false;
  }

  if (filters.eventTypes.isNotEmpty) {
    // Any function of a multi-function booking matches (legacy: the event type).
    final eventTypes = {
      _fieldString(data, 'eventTypeValue', 'eventType').toLowerCase(),
      for (final f in functionsOf(data)) f.eventType.toLowerCase(),
    };
    final matchesType = filters.eventTypes.any((t) => eventTypes.contains(t.toLowerCase()));
    if (!matchesType) return false;
  }

  if (filters.assigneeId != null) {
    final assignee = data['assignedTo'] as String?;
    final targetId = filters.assigneeId == 'current_user_id' ? currentUserId : filters.assigneeId;
    if (targetId == null || assignee != targetId) return false;
  }

  if (filters.dateRange != null) {
    final start = filters.dateRange!.start;
    final end = filters.dateRange!.end;
    bool inRange(DateTime d) => !d.isBefore(start) && d.isBefore(end);
    final functions = functionsOf(data);
    if (functions.length > 1) {
      // A booking matches when any of its functions falls in the range.
      if (!functions.any((f) => inRange(f.day))) return false;
    } else {
      final eventDate = _parseDate(data['eventDate']);
      if (eventDate == null || !inRange(eventDate)) return false;
    }
  }

  final rawQuery = filters.searchQuery?.trim();
  final query = rawQuery?.toLowerCase();
  if (rawQuery != null && query != null && query.isNotEmpty) {
    final haystack = [
      data['customerName'],
      data['customerPhone'],
      data['customerEmail'],
      data['notes'],
      data['description'],
      data['eventTypeLabel'],
      data['eventType'],
    ].whereType<String>().join(' ').toLowerCase();
    // Shared matcher adds digit-only phone matching ("98765 43210" vs "+919876543210")
    // against customerPhone / whatsappNumber / phoneNormalized, plus textIndex.
    if (!haystack.contains(query) && !matchesEnquirySearchQuery(data, rawQuery)) return false;
  }

  return true;
}

String _fieldString(Map<String, dynamic> data, String primary, String fallback) {
  final value = data[primary] ?? data[fallback];
  if (value == null) return '';
  return value.toString().trim();
}

DateTime? _parseDate(dynamic value) => parseEnquiryDateTime(value);
