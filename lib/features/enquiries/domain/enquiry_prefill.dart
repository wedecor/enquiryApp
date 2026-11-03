/// Starting values for a new enquiry (e.g. "Add another event" for an existing
/// customer), so staff don't re-type customer details. Create mode only.
class EnquiryPrefill {
  const EnquiryPrefill({
    this.customerName,
    this.customerPhone,
    this.whatsappNumber,
    this.customerEmail,
    this.source,
    this.eventLocation,
    this.fromEnquiryId,
  });

  final String? customerName;
  final String? customerPhone;
  final String? whatsappNumber;
  final String? customerEmail;

  /// Lead source value (e.g. `instagram`).
  final String? source;
  final String? eventLocation;

  /// Enquiry this prefill was copied from. When set, the user has already said this
  /// is another event for the customer, so the duplicate warning starts dismissed.
  final String? fromEnquiryId;

  /// Customer details of an existing enquiry document. The event location is not
  /// copied: a different event is usually somewhere else.
  factory EnquiryPrefill.fromEnquiryData(Map<String, dynamic> data, {String? enquiryId}) {
    String? read(String key) {
      final value = data[key];
      if (value is! String) return null;
      final trimmed = value.trim();
      return trimmed.isEmpty ? null : trimmed;
    }

    return EnquiryPrefill(
      customerName: read('customerName'),
      customerPhone: read('customerPhone'),
      whatsappNumber: read('whatsappNumber'),
      customerEmail: read('customerEmail'),
      source: read('sourceValue') ?? read('source'),
      fromEnquiryId: enquiryId,
    );
  }
}
