import '../../../enquiries/domain/enquiry.dart';

/// Callbacks for enquiry list item actions (kept on the screen).
class DashboardEnquiryTabActions {
  const DashboardEnquiryTabActions({
    required this.onView,
    required this.onCall,
    required this.onWhatsApp,
    required this.onReminderWhatsApp,
    required this.onUpdateStatus,
    required this.onShare,
    required this.onAddNote,
    required this.onReviewRequest,
    required this.onMarkNotInterested,
  });

  final void Function(String enquiryId) onView;
  final Future<void> Function(
    String? phone,
    String customerName,
    String enquiryId,
  )
  onCall;
  final Future<void> Function(
    String? phone,
    String customerName,
    String enquiryId,
  )
  onWhatsApp;
  final Future<void> Function(
    String phone,
    String customerName,
    String enquiryId,
    String eventType,
    DateTime createdAt,
    DateTime? eventDate,
  )
  onReminderWhatsApp;
  final Future<void> Function(Enquiry enquiry) onUpdateStatus;
  final Future<void> Function(Enquiry enquiry) onShare;
  final Future<void> Function(Enquiry enquiry) onAddNote;
  final Future<void> Function(
    String phone,
    String customerName,
    String enquiryId,
  )
  onReviewRequest;
  final Future<void> Function(String enquiryId, String userId)
  onMarkNotInterested;
}
