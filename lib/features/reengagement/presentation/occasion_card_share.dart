import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/contacts/contact_launcher.dart';
import '../../../core/logging/logger.dart';
import '../../../shared/widgets/confirmation_dialog.dart';
import '../domain/reengagement_templates.dart';
import 'reengagement_actions.dart';
import 'wish_card.dart';

/// Outcome of [OccasionCardShare.share].
enum OccasionShareResult {
  /// Contact logged (or text WhatsApp opened with audit).
  sent,

  /// User cancelled share sheet or declined "Mark as sent?".
  cancelled,

  /// No usable phone / WhatsApp could not open.
  failed,
}

/// Shared card + caption share used by yearly wishes and thank-you / review.
///
/// Android: tries direct chat via MethodChannel; because WhatsApp's `jid` extra is
/// unofficial, delivery is confirmed with "Mark as sent?" before logging.
/// Share sheet: same confirm (avoids counting Drive/Messages as sent).
/// Text-only WhatsApp URL: logged immediately (chat is addressed in the URL).
class OccasionCardShare {
  OccasionCardShare._();

  static const MethodChannel _whatsAppChannel = MethodChannel('wedecor/whatsapp');

  /// Shares the card + [text]. Returns [OccasionShareResult.sent] only when the
  /// contact was logged (or text WhatsApp opened successfully).
  static Future<OccasionShareResult> share({
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
    String markSentTitle = 'Mark as sent?',
    String? markSentMessage,
  }) async {
    final resolved = ReengagementActions.resolveWishPhone(
      launcher,
      customerPhone: customerPhone,
      phoneNormalized: phoneNormalized,
    );
    if (resolved == null) {
      _snack(context, 'No phone number for this customer');
      return OccasionShareResult.failed;
    }

    final first = ReengagementTemplates.firstName(customerName);
    final confirmMessage =
        markSentMessage ?? 'Did the message go to $first\'s WhatsApp chat? Only tap Yes if it did.';

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
            await Clipboard.setData(ClipboardData(text: text));
            if (!context.mounted) return OccasionShareResult.cancelled;
            _snack(context, 'Card opened in WhatsApp — caption copied if you need to paste it');
            return _confirmAndLog(
              context: context,
              launcher: launcher,
              enquiryId: enquiryId,
              contactType: contactType,
              title: markSentTitle,
              message: confirmMessage,
            );
          }
        }

        if (!context.mounted) return OccasionShareResult.cancelled;
        // Prefer a real temp file — XFile.fromData often fails to hand the image
        // to WhatsApp on Android (empty attachment / share aborted).
        final files = kIsWeb
            ? [XFile.fromData(png, mimeType: 'image/png', name: imageFileName)]
            : [
                XFile(
                  (await _writeTempPng(png, imageFileName)).path,
                  mimeType: 'image/png',
                  name: imageFileName,
                ),
              ];
        final result = await Share.shareXFiles(files, text: text);
        if (result.status == ShareResultStatus.dismissed) {
          // Offer text-only fallback instead of abandoning.
          if (!context.mounted) return OccasionShareResult.cancelled;
          final useText = await ConfirmationDialog.show(
            context: context,
            title: 'Send text only?',
            message: 'Image share was cancelled. Open WhatsApp with the message text?',
            confirmText: 'Open WhatsApp',
            icon: Icons.chat_bubble_outline,
          );
          if (!useText || !context.mounted) return OccasionShareResult.cancelled;
        } else {
          await Clipboard.setData(ClipboardData(text: text));
          if (!context.mounted) return OccasionShareResult.cancelled;
          return _confirmAndLog(
            context: context,
            launcher: launcher,
            enquiryId: enquiryId,
            contactType: contactType,
            title: markSentTitle,
            message: confirmMessage,
          );
        }
      } catch (e, st) {
        Log.e('Occasion card share failed; opening WhatsApp with text', error: e, stackTrace: st);
        if (context.mounted) {
          _snack(context, cardAttachFailedMessage);
        }
      }
    }

    if (!context.mounted) return OccasionShareResult.cancelled;
    final status = await launcher.openWhatsAppWithAudit(
      resolved,
      prefillText: text,
      enquiryId: enquiryId,
      contactType: contactType,
    );
    if (!context.mounted) return OccasionShareResult.failed;
    if (status != ContactLaunchStatus.opened) {
      _snack(context, 'Could not open WhatsApp');
      return OccasionShareResult.failed;
    }
    return OccasionShareResult.sent;
  }

  static Future<OccasionShareResult> _confirmAndLog({
    required BuildContext context,
    required ContactLauncher launcher,
    required String? enquiryId,
    required ContactType contactType,
    required String title,
    required String message,
  }) async {
    final confirmed = await ConfirmationDialog.show(
      context: context,
      title: title,
      message: message,
      confirmText: 'Yes, mark sent',
      cancelText: 'Not yet',
      icon: Icons.mark_chat_read_outlined,
    );
    if (!confirmed) return OccasionShareResult.cancelled;
    final ok = await launcher.recordContactAwait(enquiryId: enquiryId, type: contactType);
    if (!ok && context.mounted) {
      _snack(context, 'Opened WhatsApp, but could not save the contact log');
      return OccasionShareResult.failed;
    }
    return OccasionShareResult.sent;
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

  static Future<File> _writeTempPng(Uint8List png, String fileName) async {
    final dir = await getTemporaryDirectory();
    final safe = fileName.trim().isEmpty ? 'we-decor-card.png' : fileName.trim();
    final file = File('${dir.path}/$safe');
    await file.writeAsBytes(png, flush: true);
    return file;
  }

  static void _snack(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}
