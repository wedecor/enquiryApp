import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../features/reengagement/domain/reengagement_templates.dart';
import '../logging/logger.dart';
import 'contact_launcher.dart';

/// Prefill copy + brand lockup for day-to-day enquiry WhatsApp.
///
/// **First contact** (no `firstContactAt` / contactCount): introduce We Decor.
/// **Follow-up**: shorter check-in — same greeting so the number still reads as us.
class EnquiryWhatsApp {
  EnquiryWhatsApp._();

  static const brandAsset = 'assets/brand/lockup_horizontal_gold.png';

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

  /// Opens the customer chat with the right prefill, logs contact, then best-effort
  /// shares the We Decor lockup so the thread looks like the company (not a random number).
  ///
  /// [messageOverride] keeps specialized flows (e.g. Follow Up tab) on their own copy
  /// while still getting the brand lockup share.
  static Future<ContactLaunchStatus> open({
    required ContactLauncher launcher,
    required String phone,
    required String customerName,
    String? enquiryId,
    String? eventTypeLabel,
    DateTime? eventDate,
    bool firstContact = true,
    bool shareBrandImage = true,
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
    final status = await launcher.openWhatsAppWithAudit(
      phone,
      prefillText: text,
      enquiryId: enquiryId,
      contactType: contactType,
    );
    if (status == ContactLaunchStatus.opened && shareBrandImage && !kIsWeb) {
      await _shareBrandLockup();
    }
    return status;
  }

  static Future<void> _shareBrandLockup() async {
    try {
      final data = await rootBundle.load(brandAsset);
      final bytes = data.buffer.asUint8List();
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/we-decor-intro.png');
      await file.writeAsBytes(bytes, flush: true);
      await Share.shareXFiles([XFile(file.path, mimeType: 'image/png', name: 'we-decor.png')]);
    } catch (e, st) {
      Log.w(
        'EnquiryWhatsApp: brand lockup share failed',
        data: {'error': e.toString(), 'stack': st.toString()},
      );
    }
  }
}
