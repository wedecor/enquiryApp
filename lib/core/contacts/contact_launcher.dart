import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../logging/logger.dart';
import '../services/contact_log_service.dart';

export '../services/contact_log_service.dart' show ContactType;

/// Status of contact launch operations
enum ContactLaunchStatus { opened, notInstalled, invalidNumber, failed }

/// Provider for the contact launcher service
final contactLauncherProvider = Provider<ContactLauncher>((ref) {
  // Default to +91 (India) - can be made configurable later
  return ContactLauncher(
    defaultCountryCode: '+91',
    contactLog: ref.watch(contactLogServiceProvider),
  );
});

/// Service for launching contact applications (phone, WhatsApp)
/// Handles phone number normalization, URL scheme launching, and audit logging
class ContactLauncher {
  ContactLauncher({this.defaultCountryCode = '+91', this.contactLog});

  final String defaultCountryCode;

  /// Persists successful contacts against an enquiry (speed-to-lead analytics).
  final ContactLogService? contactLog;

  /// Normalizes raw phone number to E.164-like format.
  ///
  /// - Strips everything except digits and a leading `+`.
  /// - Leading `+` is kept as-is.
  /// - Leading `00` becomes `+` (international prefix).
  /// - Otherwise leading zeros are stripped, then:
  ///   - 10 digits → [defaultCountryCode] + digits
  ///   - 12 digits starting with `91` → `+` + digits
  ///   - longer than 10 → `+` + digits
  ///   - otherwise → [defaultCountryCode] + digits
  String normalize(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return '';

    final hadLeadingPlus = trimmed.startsWith('+');
    var digits = trimmed.replaceAll(RegExp(r'\D'), '');

    if (hadLeadingPlus) {
      return '+$digits';
    }

    if (digits.startsWith('00')) {
      return '+${digits.substring(2)}';
    }

    digits = digits.replaceFirst(RegExp(r'^0+'), '');
    if (digits.isEmpty) return defaultCountryCode;

    if (digits.length == 10) {
      return '$defaultCountryCode$digits';
    }
    if (digits.length == 12 && digits.startsWith('91')) {
      return '+$digits';
    }
    if (digits.length > 10) {
      return '+$digits';
    }
    return '$defaultCountryCode$digits';
  }

  /// Launch phone dialer with the given number
  ///
  /// Uses tel: scheme to open native phone app
  /// Returns status indicating success or failure reason
  Future<ContactLaunchStatus> callNumber(String rawPhone) async {
    try {
      final normalizedPhone = normalize(rawPhone);

      if (normalizedPhone.isEmpty || normalizedPhone.length < 8) {
        Logger.error('Invalid phone number for calling', tag: 'ContactLauncher');
        return ContactLaunchStatus.invalidNumber;
      }

      final telUri = Uri.parse('tel:$normalizedPhone');

      if (await canLaunchUrl(telUri)) {
        final launched = await launchUrl(telUri, mode: LaunchMode.externalApplication);

        if (launched) {
          Logger.info('Phone dialer launched successfully', tag: 'ContactLauncher');
          return ContactLaunchStatus.opened;
        } else {
          Logger.error('Failed to launch phone dialer', tag: 'ContactLauncher');
          return ContactLaunchStatus.failed;
        }
      } else {
        Logger.error('Phone dialer not available on this platform', tag: 'ContactLauncher');
        return ContactLaunchStatus.notInstalled;
      }
    } catch (e) {
      Logger.error('Error launching phone dialer: $e', tag: 'ContactLauncher');
      return ContactLaunchStatus.failed;
    }
  }

  /// Open WhatsApp chat with the given number
  ///
  /// Tries native WhatsApp app first, falls back to WhatsApp Web
  /// Supports optional prefilled message text
  Future<ContactLaunchStatus> openWhatsApp(String rawPhone, {String? prefillText}) async {
    try {
      final normalizedPhone = normalize(rawPhone);

      if (normalizedPhone.isEmpty || normalizedPhone.length < 8) {
        Logger.error('Invalid phone number for WhatsApp', tag: 'ContactLauncher');
        return ContactLaunchStatus.invalidNumber;
      }

      // Remove '+' for WhatsApp URLs (they expect just digits)
      final whatsappPhone = normalizedPhone.startsWith('+')
          ? normalizedPhone.substring(1)
          : normalizedPhone;

      // Encode prefill text for URL
      final encodedText = prefillText != null ? Uri.encodeComponent(prefillText) : '';

      // Try native WhatsApp app first
      final nativeUri = Uri.parse(
        'whatsapp://send?phone=$whatsappPhone${encodedText.isNotEmpty ? '&text=$encodedText' : ''}',
      );

      if (await canLaunchUrl(nativeUri)) {
        final launched = await launchUrl(nativeUri, mode: LaunchMode.externalApplication);

        if (launched) {
          Logger.info('WhatsApp app launched successfully', tag: 'ContactLauncher');
          return ContactLaunchStatus.opened;
        }
      }

      // Fallback to WhatsApp Web
      final webUri = Uri.parse(
        'https://wa.me/$whatsappPhone${encodedText.isNotEmpty ? '?text=$encodedText' : ''}',
      );

      final webLaunched = await launchUrl(webUri, mode: LaunchMode.externalApplication);

      if (webLaunched) {
        Logger.info('WhatsApp Web launched successfully', tag: 'ContactLauncher');
        return ContactLaunchStatus.opened;
      } else {
        Logger.error('Failed to launch WhatsApp (both app and web)', tag: 'ContactLauncher');
        return ContactLaunchStatus.failed;
      }
    } catch (e) {
      Logger.error('Error launching WhatsApp: $e', tag: 'ContactLauncher');
      return ContactLaunchStatus.failed;
    }
  }

  /// Log contact action for audit trail
  void _logContactAction(String mode, bool success) {
    Logger.info('Contact action: $mode (success: $success)', tag: 'ContactLauncher');
  }

  /// Records a successful contact against [enquiryId] without delaying the UI.
  void _recordContact(String? enquiryId, ContactType type, ContactLaunchStatus status) {
    if (enquiryId == null || enquiryId.isEmpty || status != ContactLaunchStatus.opened) return;
    final log = contactLog;
    if (log == null) return;
    // Fire-and-forget: the service swallows its own errors.
    unawaited(log.record(enquiryId: enquiryId, type: type));
  }

  /// Records a contact made outside [openWhatsApp] (e.g. a wish card shared
  /// through the share sheet) in the enquiry's contact log.
  void recordContact({required String? enquiryId, required ContactType type}) {
    _recordContact(enquiryId, type, ContactLaunchStatus.opened);
  }

  /// Awaits the contact log write. False when skipped (no enquiry / no uid) or failed.
  Future<bool> recordContactAwait({required String? enquiryId, required ContactType type}) async {
    if (enquiryId == null || enquiryId.isEmpty) return false;
    final log = contactLog;
    if (log == null) return false;
    return log.record(enquiryId: enquiryId, type: type);
  }

  /// Launch phone call with audit logging
  Future<ContactLaunchStatus> callNumberWithAudit(String rawPhone, {String? enquiryId}) async {
    final status = await callNumber(rawPhone);
    _logContactAction('call', status == ContactLaunchStatus.opened);
    _recordContact(enquiryId, ContactType.call, status);
    return status;
  }

  /// Launch WhatsApp with audit logging. [contactType] distinguishes reminders
  /// and review requests from ordinary messages in the contact log.
  Future<ContactLaunchStatus> openWhatsAppWithAudit(
    String rawPhone, {
    String? prefillText,
    String? enquiryId,
    ContactType contactType = ContactType.whatsapp,
  }) async {
    final status = await openWhatsApp(rawPhone, prefillText: prefillText);
    _logContactAction('whatsapp', status == ContactLaunchStatus.opened);
    _recordContact(enquiryId, contactType, status);
    return status;
  }
}
