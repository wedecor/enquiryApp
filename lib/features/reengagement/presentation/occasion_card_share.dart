import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/contacts/contact_launcher.dart';
import '../../../core/contacts/whatsapp_direct_share.dart';
import '../../../core/logging/logger.dart';
import '../../../shared/widgets/confirmation_dialog.dart';
import '../domain/reengagement_templates.dart';
import 'customer_card.dart';
import 'reengagement_actions.dart';

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
/// Android uses WhatsAppDirectShare (message + card to the right chat). Other
/// platforms open the phone-URL chat first, then attach the card. Untargeted
/// share sheets alone are never used to open WhatsApp.
class OccasionCardShare {
  OccasionCardShare._();

  /// Shares the card + [text]. Returns [OccasionShareResult.sent] only when the
  /// contact was logged (or text WhatsApp opened successfully).
  static Future<OccasionShareResult> share({
    required BuildContext context,
    required ContactLauncher launcher,
    required CustomerCardContent content,
    required String text,
    required String? customerPhone,
    required String phoneNormalized,
    required String customerName,
    required String? enquiryId,
    required ContactType contactType,
    DateTime? eventDate,
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

    Uint8List? png;
    try {
      png = await CustomerCardRenderer.renderPng(content);
    } catch (e, st) {
      Log.e('Occasion card render failed', error: e, stackTrace: st);
      if (context.mounted) _snack(context, cardAttachFailedMessage);
    }

    // Android: message + card to the customer's chat (see WhatsAppDirectShare).
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android && png != null) {
      if (!context.mounted) return OccasionShareResult.cancelled;
      final direct = await WhatsAppDirectShare.shareImageToChat(
        launcher: launcher,
        png: png,
        phone: resolved,
        text: text,
        context: context,
        customerFullName: customerName,
        eventDate: eventDate,
      );
      if (direct == WhatsAppDirectShareResult.opened ||
          direct == WhatsAppDirectShareResult.textOnly) {
        if (!context.mounted) return OccasionShareResult.cancelled;
        _snack(
          context,
          direct == WhatsAppDirectShareResult.opened
              ? 'Opened $first\'s WhatsApp with the card — tap Send if it looks right'
              : 'Opened $first\'s chat with the message — card not attached',
        );
        return _confirmAndLog(
          context: context,
          launcher: launcher,
          enquiryId: enquiryId,
          contactType: contactType,
          title: markSentTitle,
          message: confirmMessage,
        );
      }
      if (direct == WhatsAppDirectShareResult.cancelled) {
        return OccasionShareResult.cancelled;
      }
    }

    // All platforms / Android channel failed: open the correct chat via phone URL
    // first (same as the normal WhatsApp button). Never open an untargeted share
    // sheet as the way into WhatsApp.
    if (!context.mounted) return OccasionShareResult.cancelled;
    final status = await launcher.openWhatsApp(resolved, prefillText: text);
    if (!context.mounted) return OccasionShareResult.failed;
    if (status != ContactLaunchStatus.opened) {
      _snack(context, 'Could not open WhatsApp');
      return OccasionShareResult.failed;
    }

    // Best-effort card attach after the chat is open (may still need the user to
    // pick WhatsApp in the sheet, but the chat with the number is already open).
    if (png != null && !kIsWeb) {
      try {
        final file = await _writeTempPng(png, imageFileName);
        await Share.shareXFiles([XFile(file.path, mimeType: 'image/png', name: imageFileName)]);
      } catch (e, st) {
        Log.w(
          'Occasion card share-after-chat failed',
          data: {'error': e.toString(), 'stack': st.toString()},
        );
        if (context.mounted) _snack(context, cardAttachFailedMessage);
      }
    } else if (png == null && context.mounted) {
      // render already snacked
    }

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
