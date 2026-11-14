import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/reengagement/domain/reengagement_templates.dart';
import '../contacts/contact_launcher.dart';
import '../logging/logger.dart';

/// Default Google review link when app config has none.
const String kDefaultGoogleReviewLink = 'https://share.google/qba1n2A4MKJiUy3PA';

/// Provider for ReviewRequestService
final reviewRequestServiceProvider = Provider<ReviewRequestService>((ref) {
  final contactLauncher = ref.watch(contactLauncherProvider);
  return ReviewRequestService(contactLauncher);
});

/// Service for sending thank-you + review requests to customers via WhatsApp.
class ReviewRequestService {
  final ContactLauncher _contactLauncher;

  ReviewRequestService(this._contactLauncher);

  /// Thank-you message with a Google review link.
  ///
  /// - [customerName]: full name; only the first name is used (same as wishes).
  /// - [eventTypeLabel]: event type display label; lower-cased in the message.
  ///   Blank / unknown → "celebration".
  /// - [googleReviewLink]: from app config; falls back to [kDefaultGoogleReviewLink].
  /// - [businessName]: company name from app config.
  String generateReviewMessage({
    required String customerName,
    String? eventTypeLabel,
    String? googleReviewLink,
    String? businessName,
  }) {
    final name = ReengagementTemplates.firstName(customerName);
    final rawEvent = eventTypeLabel?.trim() ?? '';
    final event = rawEvent.isEmpty ? 'celebration' : rawEvent.toLowerCase();
    final link = (googleReviewLink != null && googleReviewLink.trim().isNotEmpty)
        ? googleReviewLink.trim()
        : kDefaultGoogleReviewLink;
    final business = (businessName != null && businessName.trim().isNotEmpty)
        ? businessName.trim()
        : 'We Decor';

    return 'Hi $name, thank you for having us at your $event. '
        'It was a joy to be part of it, and we hope everything looked the way you imagined. '
        'If you have a minute, a short Google review would mean a lot to our small team: $link\n'
        '\n'
        'Warm wishes from $business.';
  }

  /// Sends thank-you / review request via WhatsApp (text-only path).
  ///
  /// Card sharing goes through the shared helper in Task 3; this remains for
  /// callers that only need the WhatsApp text launch.
  Future<ContactLaunchStatus> sendReviewRequest({
    required String customerPhone,
    required String customerName,
    String? eventTypeLabel,
    String? googleReviewLink,
    String? businessName,
    String? enquiryId,
  }) async {
    try {
      final message = generateReviewMessage(
        customerName: customerName,
        eventTypeLabel: eventTypeLabel,
        googleReviewLink: googleReviewLink,
        businessName: businessName,
      );

      Log.i(
        'Sending thank-you review request',
        data: {
          'customerName': customerName,
          'hasGoogleLink': googleReviewLink != null,
          'event': eventTypeLabel,
        },
      );

      return await _contactLauncher.openWhatsAppWithAudit(
        customerPhone,
        prefillText: message,
        enquiryId: enquiryId,
        contactType: ContactType.reviewRequest,
      );
    } catch (e) {
      Log.e('Error sending review request', error: e);
      return ContactLaunchStatus.failed;
    }
  }
}
