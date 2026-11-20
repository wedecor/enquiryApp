import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../features/reengagement/domain/reengagement_templates.dart';
import '../../features/reengagement/presentation/customer_card.dart';
import '../logging/logger.dart';
import 'contact_launcher.dart';
import 'whatsapp_direct_share.dart';

/// Prefill copy + matching customer card for day-to-day enquiry WhatsApp.
///
/// **First contact** / **follow-up**: brand card.
/// **Follow Up tab**: countdown card (brand when the event date is unusable).
class EnquiryWhatsApp {
  EnquiryWhatsApp._();

  /// True when this enquiry has never been contacted from the app.
  static bool isFirstContact({Object? firstContactAt, Object? contactCount}) {
    if (firstContactAt != null) return false;
    if (contactCount is num && contactCount > 0) return false;
    return true;
  }

  static bool isFirstContactFrom(Map<String, dynamic>? enquiryData) {
    if (enquiryData == null) return true;
    return isFirstContact(
      firstContactAt: enquiryData['firstContactAt'],
      contactCount: enquiryData['contactCount'],
    );
  }

  /// Message body. Uses first name; never emoji-heavy.
  static String message({
    required String customerName,
    required bool firstContact,
    String? eventTypeLabel,
    DateTime? eventDate,
  }) {
    final name = ReengagementTemplates.firstName(customerName);
    final hello = name == 'there' ? 'Hi' : 'Hi $name';
    final rawEvent = (eventTypeLabel ?? '').trim();
    final event = rawEvent.isEmpty ? '' : rawEvent.toLowerCase();
    final eventBit = event.isEmpty ? 'enquiry' : '$event enquiry';
    final dateBit = _dateSuffix(eventDate);

    if (firstContact) {
      return '$hello, greetings from We Decor.\n'
          'I\'m writing about your $eventBit$dateBit. '
          'How can we help you today?';
    }
    return '$hello, greetings from We Decor.\n'
        'Just checking in on your $eventBit$dateBit — '
        'happy to answer any questions.';
  }

  static String _dateSuffix(DateTime? eventDate) {
    if (eventDate == null || eventDate.year <= 1971) return '';
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final day = eventDate.day.toString();
    final month = months[eventDate.month - 1];
    return ' for $day $month';
  }

  /// Card for flows 1–2 (brand) or flow 3 (countdown, else brand).
  static CustomerCardContent cardFor({
    required String customerName,
    String? eventTypeLabel,
    DateTime? eventDate,
    bool countdown = false,
    DateTime? now,
    String? websiteUrl,
    String? instagramHandle,
  }) {
    if (countdown) {
      final c = CustomerCardContent.countdown(
        customerName: customerName,
        eventTypeLabel: eventTypeLabel,
        eventDate: eventDate,
        now: now ?? DateTime.now(),
      );
      if (c != null) return c;
    }
    return CustomerCardContent.brand(websiteUrl: websiteUrl, instagramHandle: instagramHandle);
  }

  /// Opens the customer chat with the right prefill, logs contact, then shares
  /// the matching customer card (Android direct-to-chat when possible).
  ///
  /// Pass [context] on Android so the glass WhatsApp / Business picker can show
  /// when both apps are installed.
  static Future<ContactLaunchStatus> open({
    required ContactLauncher launcher,
    required String phone,
    required String customerName,
    BuildContext? context,
    String? enquiryId,
    String? eventTypeLabel,
    DateTime? eventDate,
    bool firstContact = true,
    bool shareCard = true,

    /// Follow Up tab: share countdown (falls back to brand when date unusable).
    bool countdownCard = false,
    DateTime? now,
    String? websiteUrl,
    String? instagramHandle,
    ContactType contactType = ContactType.whatsapp,
    String? messageOverride,
  }) async {
    final text =
        messageOverride ??
        message(
          customerName: customerName,
          firstContact: firstContact,
          eventTypeLabel: eventTypeLabel,
          eventDate: eventDate,
        );

    Uint8List? png;
    if (shareCard && !kIsWeb) {
      try {
        final content = cardFor(
          customerName: customerName,
          eventTypeLabel: eventTypeLabel,
          eventDate: eventDate,
          countdown: countdownCard,
          now: now,
          websiteUrl: websiteUrl,
          instagramHandle: instagramHandle,
        );
        png = await CustomerCardRenderer.renderPng(content);
      } catch (e, st) {
        Log.w(
          'EnquiryWhatsApp: card render failed',
          data: {'error': e.toString(), 'stack': st.toString()},
        );
      }
    }

    // Android: card to the customer's chat (see WhatsAppDirectShare).
    if (png != null && !kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      final sheetContext = (context != null && context.mounted) ? context : null;
      final direct = await WhatsAppDirectShare.shareImageToChat(
        launcher: launcher,
        png: png,
        phone: phone,
        text: text,
        context: sheetContext,
        customerFirstName: ReengagementTemplates.firstName(customerName),
      );
      // textOnly: the chat opened with the message; staff skipped the card.
      if (direct == WhatsAppDirectShareResult.opened ||
          direct == WhatsAppDirectShareResult.textOnly) {
        launcher.recordContact(enquiryId: enquiryId, type: contactType);
        return ContactLaunchStatus.opened;
      }
      if (direct == WhatsAppDirectShareResult.cancelled) {
        return ContactLaunchStatus.failed;
      }
    }

    final status = await launcher.openWhatsAppWithAudit(
      phone,
      prefillText: text,
      enquiryId: enquiryId,
      contactType: contactType,
    );
    if (status == ContactLaunchStatus.opened && png != null && !kIsWeb) {
      await _sharePngAfterChat(png);
    }
    return status;
  }

  static Future<void> _sharePngAfterChat(Uint8List png) async {
    try {
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/we-decor-card.png');
      await file.writeAsBytes(png, flush: true);
      await Share.shareXFiles([XFile(file.path, mimeType: 'image/png', name: 'we-decor-card.png')]);
    } catch (e, st) {
      Log.w(
        'EnquiryWhatsApp: card share-after-chat failed',
        data: {'error': e.toString(), 'stack': st.toString()},
      );
    }
  }
}
