import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../logging/logger.dart';
import '../providers/role_provider.dart';

/// Status of contact launch operations
enum ContactLaunchStatus { opened, notInstalled, invalidNumber, failed }

/// Provider for the contact launcher service
final contactLauncherProvider = Provider<ContactLauncher>((ref) {
  // Default to +91 (India) - can be made configurable later
  return ContactLauncher(defaultCountryCode: '+91');
});

/// Service for launching contact applications (phone, WhatsApp)
/// Handles phone number normalization, URL scheme launching, and audit logging
class ContactLauncher {
  ContactLauncher({this.defaultCountryCode = '+91'});

  final String defaultCountryCode;

  /// Normalizes raw phone number to E.164-like format
  ///
  /// Rules:
  /// - Removes spaces, dashes, parentheses, dots
  /// - Keeps leading '+' if present
  /// - Adds defaultCountryCode if no '+' prefix
  ///
  /// Examples:
  /// - "9876543210" + "+91" → "+919876543210"
  /// - "(987) 654-3210" + "+1" → "+19876543210"
  /// - "+442071838750" → "+442071838750" (unchanged)
  String normalize(String raw) {
    if (raw.trim().isEmpty) return '';

    // Remove all formatting characters except '+'
    String cleaned = raw.replaceAll(RegExp(r'[^\d+]'), '');

    // If already has country code, return as-is
    if (cleaned.startsWith('+')) {
      return cleaned;
    }

    // Add default country code
    return '$defaultCountryCode$cleaned';
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

  /// Launch phone call with audit logging
  Future<ContactLaunchStatus> callNumberWithAudit(String rawPhone, {String? enquiryId}) async {
    final status = await callNumber(rawPhone);
    _logContactAction('call', status == ContactLaunchStatus.opened);
    return status;
  }

  /// Launch WhatsApp with audit logging
  Future<ContactLaunchStatus> openWhatsAppWithAudit(
    String rawPhone, {
    String? prefillText,
    String? enquiryId,
  }) async {
    final status = await openWhatsApp(rawPhone, prefillText: prefillText);
    _logContactAction('whatsapp', status == ContactLaunchStatus.opened);
    return status;
  }
}
