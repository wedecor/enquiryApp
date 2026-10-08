import '../../../core/constants/status_vocabulary.dart';
import '../../dashboard/presentation/widgets/dashboard_enquiry_utils.dart';
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
    final eventType = _fieldString(data, 'eventTypeValue', 'eventType').toLowerCase();
    final matchesType = filters.eventTypes.any((t) => t.toLowerCase() == eventType);
    if (!matchesType) return false;
  }

  if (filters.assigneeId != null) {
    final assignee = data['assignedTo'] as String?;
    final targetId = filters.assigneeId == 'current_user_id' ? currentUserId : filters.assigneeId;
    if (targetId == null || assignee != targetId) return false;
  }

  if (filters.dateRange != null) {
    final eventDate = _parseDate(data['eventDate']);
    if (eventDate == null) return false;
    final start = filters.dateRange!.start;
    final end = filters.dateRange!.end;
    if (eventDate.isBefore(start) || !eventDate.isBefore(end)) return false;
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
