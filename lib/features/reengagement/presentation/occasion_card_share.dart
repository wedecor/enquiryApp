import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/contacts/contact_launcher.dart';
import '../../../core/logging/logger.dart';
import '../domain/reengagement_templates.dart';
import 'reengagement_actions.dart';
import 'wish_card.dart';

/// Shared card + caption share used by yearly wishes and thank-you / review.
///
/// Android app: direct into the customer's WhatsApp chat when possible.
/// Otherwise: share sheet (pick WhatsApp → chat). Desktop web: text-only.
/// Phone falls back to [phoneNormalized] via [ReengagementActions.resolveWishPhone].
class OccasionCardShare {
  OccasionCardShare._();

  static const MethodChannel _whatsAppChannel = MethodChannel('wedecor/whatsapp');

  /// True when the card/text went out (contact logged with [contactType]).
  static Future<bool> share({
    required BuildContext context,
    required ContactLauncher launcher,
    required WishCardContent content,
    required String text,
    required String? customerPhone,
    required String phoneNormalized,
    required String customerName,
    required String? enquiryId,
    required ContactType contactType,
    String imageFileName = 'we-decor-card.png',
    String cardAttachFailedMessage = "Couldn't attach the card — sending text only",
  }) async {
    final resolved = ReengagementActions.resolveWishPhone(
      launcher,
      customerPhone: customerPhone,
      phoneNormalized: phoneNormalized,
    );
    if (resolved == null) {
      _snack(context, 'No phone number for this customer');
      return false;
    }

    final canShareImage =
        !kIsWeb ||
        defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;

    if (canShareImage) {
      try {
        final png = await WishCardRenderer.renderPng(content);
        if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
          final opened = await _shareToChat(png, launcher.normalize(resolved), text);
          if (opened) {
            launcher.recordContact(enquiryId: enquiryId, type: contactType);
            return true;
          }
        }
        if (context.mounted) {
          _snack(
            context,
            'Pick WhatsApp, then ${ReengagementTemplates.firstName(customerName)}\'s chat',
          );
        }
        final result = await Share.shareXFiles([
          XFile.fromData(png, mimeType: 'image/png', name: imageFileName),
        ], text: text);
        if (result.status == ShareResultStatus.dismissed) return false;
        launcher.recordContact(enquiryId: enquiryId, type: contactType);
        return true;
      } catch (e, st) {
        Log.e('Occasion card share failed; opening WhatsApp with text', error: e, stackTrace: st);
        if (context.mounted) {
          _snack(context, cardAttachFailedMessage);
        }
      }
    }

    if (!context.mounted) return false;
    final status = await launcher.openWhatsAppWithAudit(
      resolved,
      prefillText: text,
      enquiryId: enquiryId,
      contactType: contactType,
    );
    if (!context.mounted) return false;
    if (status != ContactLaunchStatus.opened) {
      _snack(context, 'Could not open WhatsApp');
      return false;
    }
    return true;
  }

  static Future<bool> _shareToChat(Uint8List png, String phone, String text) async {
    try {
      final opened = await _whatsAppChannel.invokeMethod<bool>('shareImageToChat', {
        'png': png,
        'phone': phone,
        'text': text,
      });
      return opened ?? false;
    } on PlatformException catch (e) {
      Log.w('WhatsApp direct share failed', data: {'error': e.message});
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  static void _snack(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}
