/// Calendar Event Model
class CalendarEvent {
  final String enquiryId;
  final String customerName;
  final String eventType;
  final DateTime eventDate;
  final String? eventLocation;
  final String status;
  final DateTime createdAt;
  final String? customerPhone;

  CalendarEvent({
    required this.enquiryId,
    required this.customerName,
    required this.eventType,
    required this.eventDate,
    this.eventLocation,
    required this.status,
    required this.createdAt,
    this.customerPhone,
  });
}
