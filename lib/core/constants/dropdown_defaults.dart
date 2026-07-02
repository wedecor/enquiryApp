import 'status_vocabulary.dart';

/// Built-in dropdown options used when Firestore `dropdowns/{kind}/items` is empty.
class DropdownDefaults {
  DropdownDefaults._();

  static List<Map<String, String>> get statuses => EnquiryStatus.values
      .map((s) => {'label': s.label, 'value': s.value})
      .toList(growable: false);

  static const List<Map<String, String>> paymentStatuses = [
    {'label': 'Pending', 'value': 'pending'},
    {'label': 'Partial', 'value': 'partial'},
    {'label': 'Paid', 'value': 'paid'},
    {'label': 'Overdue', 'value': 'overdue'},
  ];

  static const List<Map<String, String>> priorities = [
    {'label': 'Low', 'value': 'low'},
    {'label': 'Medium', 'value': 'medium'},
    {'label': 'High', 'value': 'high'},
    {'label': 'Urgent', 'value': 'urgent'},
  ];

  static const List<Map<String, String>> sources = [
    {'label': 'Instagram', 'value': 'instagram'},
    {'label': 'Facebook', 'value': 'facebook'},
    {'label': 'WhatsApp', 'value': 'whatsapp'},
    {'label': 'Referral', 'value': 'referral'},
    {'label': 'Walk-in', 'value': 'walk_in'},
    {'label': 'Google / Website', 'value': 'google_website'},
    {'label': 'Other', 'value': 'other'},
  ];

  static const List<Map<String, String>> eventTypes = [
    {'label': 'Wedding', 'value': 'wedding'},
    {'label': 'Birthday', 'value': 'birthday'},
    {'label': 'Corporate Event', 'value': 'corporate_event'},
    {'label': 'Haldi', 'value': 'haldi'},
    {'label': 'Anniversary', 'value': 'anniversary'},
    {'label': 'Others', 'value': 'others'},
  ];

  /// Options list for form dropdown widgets keyed by Firestore collection name.
  static List<Map<String, String>> forCollection(String collectionName) {
    switch (collectionName) {
      case 'statuses':
        return List<Map<String, String>>.from(statuses);
      case 'payment_statuses':
        return List<Map<String, String>>.from(paymentStatuses);
      case 'priorities':
        return List<Map<String, String>>.from(priorities);
      case 'sources':
        return List<Map<String, String>>.from(sources);
      case 'event_types':
        return List<Map<String, String>>.from(eventTypes);
      default:
        return const [];
    }
  }

  /// Value→label map for enquiry display when Firestore lookup is empty.
  static Map<String, String> valueLabelMapFor(String collectionName) {
    final map = <String, String>{};
    for (final item in forCollection(collectionName)) {
      final value = item['value'];
      final label = item['label'];
      if (value != null && value.isNotEmpty && label != null) {
        map[value] = label;
      }
    }
    return map;
  }

  /// Returns [fetched] when non-empty; otherwise built-in defaults for [collectionName].
  static List<Map<String, String>> resolve(
    List<Map<String, String>> fetched,
    String collectionName,
  ) {
    if (fetched.isNotEmpty) return fetched;
    return forCollection(collectionName);
  }

  /// Returns [fetched] when non-empty; otherwise built-in value→label defaults.
  static Map<String, String> resolveMap(
    Map<String, String> fetched,
    String collectionName,
  ) {
    if (fetched.isNotEmpty) return fetched;
    return valueLabelMapFor(collectionName);
  }
}
