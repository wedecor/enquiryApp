import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../contacts/contact_launcher.dart';
import '../../utils/logger.dart';

/// Provider for ReviewRequestService
final reviewRequestServiceProvider = Provider<ReviewRequestService>((ref) {
  final contactLauncher = ref.watch(contactLauncherProvider);
  return ReviewRequestService(contactLauncher);
});

/// Service for sending review requests to customers via WhatsApp
class ReviewRequestService {
  final ContactLauncher _contactLauncher;

  ReviewRequestService(this._contactLauncher);

  /// Generates a review request message with Google review link, Instagram follow request, and website
  ///
  /// Parameters:
  /// - [customerName]: Name of the customer
  /// - [googleReviewLink]: Google review URL (optional, defaults to We Decor's review link)
  /// - [instagramHandle]: Instagram handle (optional, defaults to @wedecorbangalore)
  /// - [websiteUrl]: Website URL (optional, defaults to https://www.wedecorevents.com/)
  ///
  /// Returns formatted message ready to send via WhatsApp
  String generateReviewMessage({
    required String customerName,
    String? googleReviewLink,
    String? instagramHandle,
    String? websiteUrl,
  }) {
    // Default values if not provided
    final defaultGoogleReviewLink = 'https://share.google/qba1n2A4MKJiUy3PA';
    final defaultInstagramHandle = '@wedecorbangalore';
    final defaultWebsiteUrl = 'https://www.wedecorevents.com/';

    final reviewLink = googleReviewLink?.isNotEmpty == true
        ? googleReviewLink!
        : defaultGoogleReviewLink;

    final instagram = instagramHandle?.isNotEmpty == true
        ? (instagramHandle!.startsWith('@') ? instagramHandle : '@$instagramHandle')
        : defaultInstagramHandle;

    final website = websiteUrl?.isNotEmpty == true ? websiteUrl! : defaultWebsiteUrl;

    final buffer = StringBuffer();

    buffer.writeln('Hi $customerName! 👋');
    buffer.writeln('');
    buffer.writeln(
      'Thank you for choosing We Decor for your event! We hope you had a wonderful experience. 🙏',
    );
    buffer.writeln('');
    buffer.writeln('We would be grateful if you could:');
    buffer.writeln('');
    buffer.writeln('⭐ Leave us a Google review:');
    buffer.writeln(reviewLink);
    buffer.writeln('');
    buffer.writeln('📸 Follow us on Instagram: $instagram');
    buffer.writeln('https://www.instagram.com/wedecorbangalore/');
    buffer.writeln('');
    buffer.writeln('🌐 Visit our website:');
    buffer.writeln(website);
    buffer.writeln('');
    buffer.writeln('Your feedback helps us serve you better! 😊');
    buffer.writeln('');
    buffer.writeln('Thank you!');
    buffer.writeln('We Decor Team');

    return buffer.toString();
  }

  /// Sends review request via WhatsApp
  ///
  /// Returns the status of the WhatsApp launch
  Future<ContactLaunchStatus> sendReviewRequest({
    required String customerPhone,
    required String customerName,
    String? googleReviewLink,
    String? instagramHandle,
    String? websiteUrl,
    String? enquiryId,
  }) async {
    try {
      final message = generateReviewMessage(
        customerName: customerName,
        googleReviewLink: googleReviewLink,
        instagramHandle: instagramHandle,
        websiteUrl: websiteUrl,
      );

      Log.i(
        'Sending review request',
        data: {
          'customerName': customerName,
          'hasGoogleLink': googleReviewLink != null,
          'hasInstagram': instagramHandle != null,
          'hasWebsite': websiteUrl != null,
        },
      );

      return await _contactLauncher.openWhatsAppWithAudit(
        customerPhone,
        prefillText: message,
        enquiryId: enquiryId,
      );
    } catch (e) {
      Log.e('Error sending review request', error: e);
      return ContactLaunchStatus.failed;
    }
  }
}
