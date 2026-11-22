import 'package:cloud_firestore/cloud_firestore.dart';

/// One customer row candidates for device-contact sync.
class CustomerContactDraft {
  const CustomerContactDraft({
    required this.customerName,
    required this.customerPhone,
    this.whatsappPhone,
    this.eventDate,
    this.digits,
  });

  final String customerName;
  final String customerPhone;
  final String? whatsappPhone;
  final DateTime? eventDate;

  /// Precomputed WhatsApp digits when known (after dedupe).
  final String? digits;

  /// Prefers WhatsApp number when set.
  String get preferredPhone {
    final wa = (whatsappPhone ?? '').trim();
    if (wa.isNotEmpty) return wa;
    return customerPhone.trim();
  }

  /// Maps an enquiry Firestore map (with or without `id`) to a draft.
  /// Returns null when there is no usable phone.
  static CustomerContactDraft? fromEnquiry(Map<String, dynamic> data) {
    final name = (data['customerName'] as String?)?.trim() ?? '';
    final phone = (data['customerPhone'] as String?)?.trim() ?? '';
    final whatsapp = (data['whatsappNumber'] as String?)?.trim();
    final eventDate = _parseEventDate(data['eventDate']);
    if (phone.isEmpty && (whatsapp == null || whatsapp.isEmpty)) return null;
    return CustomerContactDraft(
      customerName: name,
      customerPhone: phone,
      whatsappPhone: (whatsapp != null && whatsapp.isNotEmpty) ? whatsapp : null,
      eventDate: eventDate,
    );
  }

  static DateTime? _parseEventDate(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    return null;
  }
}

/// Outcome of [WhatsAppContacts.syncCustomersToDevice].
class CustomerContactSyncResult {
  const CustomerContactSyncResult({
    required this.saved,
    required this.alreadyOnPhone,
    required this.failed,
    this.permissionDenied = false,
  });

  final int saved;
  final int alreadyOnPhone;
  final int failed;
  final bool permissionDenied;

  int get totalConsidered => saved + alreadyOnPhone + failed;

  String get summaryMessage {
    if (permissionDenied) return 'Contacts permission needed to sync';
    if (totalConsidered == 0) return 'No customer numbers to sync';
    final parts = <String>['Saved $saved', 'already on phone $alreadyOnPhone'];
    if (failed > 0) parts.add('failed $failed');
    final base = parts.join(' · ');
    if (saved > 0) {
      return '$base. Search Contacts for “We Decor” (enable Phone/Device if hidden).';
    }
    if (failed > 0 && saved == 0) {
      return '$base. Could not write Contacts — check Contacts permission.';
    }
    return base;
  }
}
